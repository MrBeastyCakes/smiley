import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/errors/failures.dart';
import '../../../domain/entities/chat_message.dart';
import '../../../domain/repositories/message_repository.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final MessageRepository _repository;
  StreamSubscription<Either<Failure, ChatMessage>>? _newMessageSub;
  StreamSubscription<Either<Failure, String>>? _streamSub;
  String? _currentSessionId;

  ChatBloc({MessageRepository? repository})
    : _repository = repository ?? ServiceLocator.get<MessageRepository>(),
      super(const ChatInitial()) {
    on<ChatStarted>(_onStarted);
    on<MessageSent>(_onMessageSent);
    on<MessageReceived>(_onMessageReceived);
    on<MessageStreamed>(_onMessageStreamed);
    on<_LoadMessages>(_onLoadMessages);
  }

  Future<void> _onStarted(ChatStarted event, Emitter<ChatState> emit) async {
    emit(const ChatLoaded(messages: []));
  }

  Future<void> _onLoadMessages(_LoadMessages event, Emitter<ChatState> emit) async {
    emit(const ChatLoading());
    final result = await _repository.getMessages(event.sessionId);
    result.fold(
      (failure) => emit(ChatError(message: failure.message)),
      (messages) {
        emit(ChatLoaded(messages: messages));
        _listenToStreams(event.sessionId);
      },
    );
  }

  Future<void> _onMessageSent(MessageSent event, Emitter<ChatState> emit) async {
    if (state is! ChatLoaded) return;
    final current = state as ChatLoaded;
    final message = ChatMessage(
      id: DateTime.now().toIso8601String(),
      sessionId: event.sessionId,
      role: 'user',
      text: event.text,
      timestamp: DateTime.now(),
      status: MessageStatus.pending,
    );
    emit(ChatLoaded(messages: [...current.messages, message], isStreaming: true));

    final result = await _repository.sendMessage(event.sessionId, event.text);
    result.fold(
      (failure) => emit(ChatError(message: failure.message)),
      (_) {}, // Message will come back through watchNewMessages
    );
  }

  void _onMessageReceived(MessageReceived event, Emitter<ChatState> emit) {
    if (state is! ChatLoaded) return;
    final current = state as ChatLoaded;
    emit(ChatLoaded(messages: [...current.messages, event.message], isStreaming: false));
  }

  void _onMessageStreamed(MessageStreamed event, Emitter<ChatState> emit) {
    if (state is! ChatLoaded) return;
    final current = state as ChatLoaded;
    final messages = List<ChatMessage>.from(current.messages);
    if (messages.isNotEmpty && messages.last.isAssistant && messages.last.isStreaming) {
      messages[messages.length - 1] = messages.last.copyWith(text: messages.last.text + event.chunk);
    } else {
      messages.add(ChatMessage(
        id: 'stream-${DateTime.now().millisecondsSinceEpoch}',
        sessionId: event.sessionId,
        role: 'assistant',
        text: event.chunk,
        timestamp: DateTime.now(),
        status: MessageStatus.streaming,
      ));
    }
    emit(ChatLoaded(messages: messages, isStreaming: true));
  }

  void _listenToStreams(String sessionId) {
    _currentSessionId = sessionId;
    _newMessageSub?.cancel();
    _streamSub?.cancel();

    _newMessageSub = _repository.watchNewMessages(sessionId).listen((result) {
      result.fold(
        (failure) {}, // Silent failure for stream
        (message) => add(MessageReceived(message)),
      );
    });

    _streamSub = _repository.watchMessageStream(sessionId).listen((result) {
      result.fold(
        (failure) {},
        (chunk) => add(MessageStreamed(sessionId: sessionId, chunk: chunk)),
      );
    });
  }

  @override
  Future<void> close() {
    _newMessageSub?.cancel();
    _streamSub?.cancel();
    return super.close();
  }
}

class _LoadMessages extends ChatEvent {
  final String sessionId;
  const _LoadMessages(this.sessionId);
}
