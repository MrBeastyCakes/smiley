import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/errors/failures.dart';
import '../../../domain/entities/chat_message.dart';
import '../../../domain/repositories/message_repository.dart';
import '../connection/connection_bloc.dart' as conn;

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final MessageRepository _repository;
  final conn.ConnectionBloc? _connectionBloc;
  StreamSubscription<conn.ConnectionState>? _connectionSub;
  StreamSubscription<Either<Failure, ChatMessage>>? _newMessageSub;
  StreamSubscription<Either<Failure, String>>? _streamSub;
  String? _currentSessionId;

  ChatBloc({
    MessageRepository? repository,
    conn.ConnectionBloc? connectionBloc,
  })  : _repository = repository ?? ServiceLocator.get<MessageRepository>(),
        _connectionBloc = connectionBloc,
        super(const ChatInitial()) {
    on<ChatStarted>(_onStarted);
    on<LoadChatMessages>(_onLoadMessages);
    on<MessageSent>(_onMessageSent);
    on<MessageReceived>(_onMessageReceived);
    on<MessageStreamed>(_onMessageStreamed);
    on<MessageStatusChanged>(_onMessageStatusChanged);
    on<ConnectionRestored>(_onConnectionRestored);
    on<RetryPendingMessages>(_onRetryPendingMessages);

    // Listen for connection state changes
    _listenToConnection();
  }

  Future<void> _onStarted(ChatStarted event, Emitter<ChatState> emit) async {
    emit(const ChatLoaded(messages: []));
  }

  Future<void> _onLoadMessages(LoadChatMessages event, Emitter<ChatState> emit) async {
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
      (failure) {
        // Message stays pending — it was saved locally.
        // Update its status to failed so user knows it failed.
        if (state is ChatLoaded) {
          final s = state as ChatLoaded;
          final updated = s.messages.map((m) =>
            m.id == message.id ? m.copyWith(status: MessageStatus.failed) : m
          ).toList();
          emit(ChatLoaded(messages: updated, isStreaming: false));
        }
      },
      (remoteMessage) {
        // Update local pending to confirmed
        if (state is ChatLoaded) {
          final s = state as ChatLoaded;
          final updated = s.messages.map((m) =>
            m.id == message.id ? remoteMessage : m
          ).toList();
          emit(ChatLoaded(messages: updated, isStreaming: false));
        }
      },
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

  void _onMessageStatusChanged(MessageStatusChanged event, Emitter<ChatState> emit) {
    if (state is! ChatLoaded) return;
    final current = state as ChatLoaded;
    final updated = current.messages.map((m) =>
      m.id == event.messageId ? m.copyWith(status: event.newStatus) : m
    ).toList();
    emit(current.copyWith(messages: updated));
  }

  Future<void> _onConnectionRestored(ConnectionRestored event, Emitter<ChatState> emit) async {
    if (_currentSessionId != null) {
      add(RetryPendingMessages(sessionId: _currentSessionId!));
    }
  }

  Future<void> _onRetryPendingMessages(RetryPendingMessages event, Emitter<ChatState> emit) async {
    if (state is! ChatLoaded) return;
    final current = state as ChatLoaded;
    final pending = current.messages
        .where((m) => m.isUser && m.status == MessageStatus.pending)
        .toList();

    if (pending.isEmpty) return;

    for (final msg in pending) {
      final result = await _repository.sendMessage(msg.sessionId, msg.text);
      result.fold(
        (_) {}, // Still failed, keep as pending
        (remoteMsg) {
          final updated = current.messages.map((m) =>
            m.id == msg.id ? remoteMsg : m
          ).toList();
          emit(current.copyWith(messages: updated));
        },
      );
    }
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

  void _listenToConnection() {
    _connectionSub = _connectionBloc?.stream.listen((state) {
      if (state is conn.ConnectionConnected) {
        add(const ConnectionRestored());
      }
    });
  }

  @override
  Future<void> close() {
    _newMessageSub?.cancel();
    _streamSub?.cancel();
    _connectionSub?.cancel();
    return super.close();
  }
}
