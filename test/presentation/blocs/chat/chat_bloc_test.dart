import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openclaw_client/src/core/errors/failures.dart';
import 'package:openclaw_client/src/domain/entities/chat_message.dart';
import 'package:openclaw_client/src/domain/repositories/message_repository.dart';
import 'package:openclaw_client/src/presentation/blocs/chat/chat_bloc.dart';

class _MockMessageRepository implements MessageRepository {
  @override
  Future<Either<Failure, List<ChatMessage>>> getMessages(String sessionId) async =>
    const Right([]);
  @override
  Future<Either<Failure, ChatMessage>> sendMessage(String sessionId, String text) async =>
    Right(ChatMessage(
      id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
      sessionId: sessionId,
      role: 'user',
      text: text,
      timestamp: DateTime.now(),
    ));
  @override
  Stream<Either<Failure, ChatMessage>> watchNewMessages(String sessionId) =>
    const Stream.empty();
  @override
  Stream<Either<Failure, String>> watchMessageStream(String sessionId) =>
    const Stream.empty();
  @override
  Future<Either<Failure, void>> clearHistory(String sessionId) async =>
    const Right(null);
}

void main() {
  group('ChatBloc', () {
    const sessionId = 's1';
    final mockRepo = _MockMessageRepository();

    blocTest<ChatBloc, ChatState>(
      'emits ChatLoaded on ChatStarted',
      build: () => ChatBloc(repository: mockRepo),
      act: (bloc) => bloc.add(const ChatStarted()),
      expect: () => [
        isA<ChatLoaded>().having((s) => (s as ChatLoaded).messages, 'messages', isEmpty),
      ],
    );

    blocTest<ChatBloc, ChatState>(
      'adds user message on MessageSent',
      build: () => ChatBloc(repository: mockRepo),
      seed: () => const ChatLoaded(messages: []),
      act: (bloc) => bloc.add(const MessageSent(sessionId: sessionId, text: 'Hello')),
      expect: () => [
        isA<ChatLoaded>().having((s) => (s as ChatLoaded).messages.length, 'count', 1)
          .having((s) => s.messages.first.role, 'role', 'user')
          .having((s) => s.messages.first.text, 'text', 'Hello'),
      ],
    );



    blocTest<ChatBloc, ChatState>(
      'retries failed user messages',
      build: () => ChatBloc(repository: mockRepo),
      seed: () => ChatLoaded(
        messages: [
          ChatMessage(
            id: 'm-failed',
            sessionId: sessionId,
            role: 'user',
            text: 'Need retry',
            status: MessageStatus.failed,
            timestamp: DateTime.now(),
          ),
        ],
      ),
      act: (bloc) => bloc.add(const RetryPendingMessages(sessionId: sessionId)),
      expect: () => [
        isA<ChatLoaded>().having((s) => (s as ChatLoaded).messages.length, 'count', 1),
      ],
    );

    blocTest<ChatBloc, ChatState>(
      'does not duplicate a received message with the same id',
      build: () => ChatBloc(repository: mockRepo),
      seed: () => ChatLoaded(
        messages: [
          ChatMessage(
            id: 'm1',
            sessionId: sessionId,
            role: 'assistant',
            text: 'Original',
            timestamp: DateTime.now(),
          ),
        ],
      ),
      act: (bloc) => bloc.add(
        MessageReceived(
          ChatMessage(
            id: 'm1',
            sessionId: sessionId,
            role: 'assistant',
            text: 'Updated',
            timestamp: DateTime.now(),
          ),
        ),
      ),
      expect: () => [
        isA<ChatLoaded>()
            .having((s) => (s as ChatLoaded).messages.length, 'count', 1)
            .having((s) => s.messages.first.text, 'text', 'Updated'),
      ],
    );

    blocTest<ChatBloc, ChatState>(
      'streams assistant message chunks',
      build: () => ChatBloc(repository: mockRepo),
      seed: () => const ChatLoaded(messages: [], isStreaming: false),
      act: (bloc) => bloc.add(const MessageStreamed(sessionId: sessionId, chunk: 'Hello')),
      expect: () => [
        isA<ChatLoaded>().having((s) => (s as ChatLoaded).messages.length, 'count', 1)
          .having((s) => s.messages.first.role, 'role', 'assistant')
          .having((s) => s.messages.first.text, 'text', 'Hello')
          .having((s) => s.isStreaming, 'streaming', true),
      ],
    );

    blocTest<ChatBloc, ChatState>(
      'appends to existing streaming message',
      build: () => ChatBloc(repository: mockRepo),
      seed: () => ChatLoaded(
        messages: [
          ChatMessage(
            id: 'm1',
            sessionId: sessionId,
            role: 'assistant',
            text: 'Hel',
            status: MessageStatus.streaming,
            timestamp: DateTime.now(),
          ),
        ],
        isStreaming: true,
      ),
      act: (bloc) => bloc.add(const MessageStreamed(sessionId: sessionId, chunk: 'lo')),
      expect: () => [
        isA<ChatLoaded>().having((s) => (s as ChatLoaded).messages.length, 'count', 1)
          .having((s) => s.messages.first.text, 'text', 'Hello'),
      ],
    );
  });
}
