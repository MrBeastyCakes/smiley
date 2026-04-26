import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:openclaw_client/src/core/errors/exceptions.dart';
import 'package:openclaw_client/src/core/errors/failures.dart';
import 'package:openclaw_client/src/data/datasources/message_remote_datasource.dart';
import 'package:openclaw_client/src/data/models/chat_message_model.dart';
import 'package:openclaw_client/src/data/repositories/message_repository_impl.dart';
import 'package:openclaw_client/src/domain/entities/chat_message.dart';

class MockMessageRemoteDataSource extends Mock implements MessageRemoteDataSource {}

void main() {
  late MockMessageRemoteDataSource mockDataSource;
  late MessageRepositoryImpl repository;

  const tSessionId = 'session-123';
  final tTimestamp = DateTime.now().toIso8601String();

  final tMessageModel = ChatMessageModel(
    id: 'msg-1',
    sessionId: tSessionId,
    role: 'assistant',
    text: 'Hello',
    timestamp: tTimestamp,
  );

  final tMessageEntity = tMessageModel.toEntity();

  setUp(() {
    mockDataSource = MockMessageRemoteDataSource();
    repository = MessageRepositoryImpl(remoteDataSource: mockDataSource);
  });

  group('getMessages', () {
    test('should return Right(List<ChatMessage>) on success', () async {
      when(() => mockDataSource.listMessages(tSessionId))
          .thenAnswer((_) async => [tMessageModel]);

      final result = await repository.getMessages(tSessionId);

      expect(result, isA<Right<Failure, List<ChatMessage>>>());
      result.fold(
        (_) => fail('should be Right'),
        (messages) {
          expect(messages.length, 1);
          expect(messages.first.id, tMessageEntity.id);
          expect(messages.first.text, tMessageEntity.text);
        },
      );
      verify(() => mockDataSource.listMessages(tSessionId)).called(1);
    });

    test('should return Left(GatewayFailure) when datasource throws GatewayException', () async {
      when(() => mockDataSource.listMessages(tSessionId))
          .thenThrow(const GatewayException('Connection lost', code: 'CONN_LOST'));

      final result = await repository.getMessages(tSessionId);

      expect(result, isA<Left<Failure, List<ChatMessage>>>());
      result.fold(
        (failure) {
          expect(failure, isA<GatewayFailure>());
          expect(failure.message, 'Connection lost');
          expect(failure.code, 'CONN_LOST');
        },
        (_) => fail('should be Left'),
      );
    });

    test('should return Left(UnexpectedFailure) on unexpected exception', () async {
      when(() => mockDataSource.listMessages(tSessionId))
          .thenThrow(Exception('boom'));

      final result = await repository.getMessages(tSessionId);

      expect(result, isA<Left<Failure, List<ChatMessage>>>());
      result.fold(
        (failure) {
          expect(failure, isA<UnexpectedFailure>());
          expect(failure.message, 'Unexpected error while getting messages');
        },
        (_) => fail('should be Left'),
      );
    });
  });

  group('sendMessage', () {
    test('should return Right(ChatMessage) on success', () async {
      when(() => mockDataSource.sendMessage(tSessionId, any()))
          .thenAnswer((_) async => tMessageModel);

      final result = await repository.sendMessage(tSessionId, 'Hi');

      expect(result, isA<Right<Failure, ChatMessage>>());
      result.fold(
        (_) => fail('should be Right'),
        (message) {
          expect(message.id, tMessageEntity.id);
          expect(message.text, tMessageEntity.text);
        },
      );
      verify(() => mockDataSource.sendMessage(tSessionId, 'Hi')).called(1);
    });

    test('should return Left(GatewayFailure) when datasource throws GatewayException', () async {
      when(() => mockDataSource.sendMessage(tSessionId, any()))
          .thenThrow(const GatewayException('Send failed', code: 'SEND_ERR'));

      final result = await repository.sendMessage(tSessionId, 'Hi');

      expect(result, isA<Left<Failure, ChatMessage>>());
      result.fold(
        (failure) {
          expect(failure, isA<GatewayFailure>());
          expect(failure.message, 'Send failed');
          expect(failure.code, 'SEND_ERR');
        },
        (_) => fail('should be Left'),
      );
    });

    test('should return Left(UnexpectedFailure) on unexpected exception', () async {
      when(() => mockDataSource.sendMessage(tSessionId, any()))
          .thenThrow(Exception('boom'));

      final result = await repository.sendMessage(tSessionId, 'Hi');

      expect(result, isA<Left<Failure, ChatMessage>>());
      result.fold(
        (failure) {
          expect(failure, isA<UnexpectedFailure>());
          expect(failure.message, 'Unexpected error while sending message');
        },
        (_) => fail('should be Left'),
      );
    });
  });

  group('watchNewMessages', () {
    test('should emit Right(ChatMessage) for matching session', () async {
      final controller = StreamController<ChatMessageModel>.broadcast();
      when(() => mockDataSource.watchNewMessages(tSessionId))
          .thenAnswer((_) => controller.stream);

      final results = <Either<Failure, ChatMessage>>[];
      final sub = repository.watchNewMessages(tSessionId).listen(results.add);

      controller.add(tMessageModel);

      await Future.delayed(Duration.zero);

      expect(results.length, 1);
      results.first.fold(
        (_) => fail('should be Right'),
        (message) => expect(message.id, tMessageEntity.id),
      );

      await sub.cancel();
      await controller.close();
    });
  });

  group('watchMessageStream', () {
    test('should filter chunks by sessionId and emit Right(String)', () async {
      final controller = StreamController<Map<String, dynamic>>.broadcast();
      when(() => mockDataSource.watchMessageEvents())
          .thenAnswer((_) => controller.stream);

      final results = <Either<Failure, String>>[];
      final sub = repository.watchMessageStream(tSessionId).listen(results.add);

      controller.add({
        'type': 'message_chunk',
        'sessionId': 'other-session',
        'chunk': 'ignored',
      });

      controller.add({
        'type': 'message_chunk',
        'sessionId': tSessionId,
        'chunk': 'Hello',
      });

      controller.add({
        'type': 'message_chunk',
        'sessionId': tSessionId,
        'chunk': ' world',
      });

      await Future.delayed(Duration.zero);

      expect(results.length, 2);
      expect(results[0], equals(const Right<Failure, String>('Hello')));
      expect(results[1], equals(const Right<Failure, String>(' world')));

      await sub.cancel();
      await controller.close();
    });

    test('should ignore non-chunk events', () async {
      final controller = StreamController<Map<String, dynamic>>.broadcast();
      when(() => mockDataSource.watchMessageEvents())
          .thenAnswer((_) => controller.stream);

      final results = <Either<Failure, String>>[];
      final sub = repository.watchMessageStream(tSessionId).listen(results.add);

      controller.add({
        'type': 'message',
        'sessionId': tSessionId,
        'message': tMessageModel.toJson(),
      });

      controller.add({
        'type': 'message_chunk',
        'sessionId': tSessionId,
        'chunk': 'chunky',
      });

      await Future.delayed(Duration.zero);

      expect(results.length, 1);
      expect(results[0], equals(const Right<Failure, String>('chunky')));

      await sub.cancel();
      await controller.close();
    });
  });
}
