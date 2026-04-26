import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:openclaw_client/src/core/errors/exceptions.dart';
import 'package:openclaw_client/src/data/datasources/message_remote_datasource.dart';
import 'package:openclaw_client/src/data/models/chat_message_model.dart';
import 'package:openclaw_client/src/services/gateway_websocket.dart';

class MockGatewayWebSocketClient extends Mock implements GatewayWebSocketClient {}

void main() {
  late MockGatewayWebSocketClient mockClient;
  late MessageRemoteDataSourceImpl dataSource;

  const tSessionId = 'session-123';
  final tTimestamp = DateTime.now().toIso8601String();

  final tMessageJson = {
    'id': 'msg-1',
    'sessionId': tSessionId,
    'role': 'assistant',
    'text': 'Hello',
    'timestamp': tTimestamp,
    'status': 'sent',
  };

  final tMessageModel = ChatMessageModel.fromJson(tMessageJson);

  setUp(() {
    mockClient = MockGatewayWebSocketClient();
    dataSource = MessageRemoteDataSourceImpl(client: mockClient);

    when(() => mockClient.send(any())).thenAnswer((_) async {});
  });

  group('listMessages', () {
    test('should send correct JSON and decode response', () async {
      final controller = StreamController<Map<String, dynamic>>.broadcast();
      when(() => mockClient.messageStream).thenAnswer((_) => controller.stream);

      final future = dataSource.listMessages(tSessionId);

      await Future.delayed(Duration.zero);

      verify(() => mockClient.send({
            'type': 'list_messages',
            'sessionId': tSessionId,
          })).called(1);

      controller.add({
        'type': 'message_list',
        'sessionId': tSessionId,
        'messages': [tMessageJson],
      });

      final result = await future;

      expect(result.length, 1);
      expect(result.first.id, tMessageModel.id);
      expect(result.first.text, tMessageModel.text);

      await controller.close();
    });

    test('should throw GatewayException on error', () async {
      final controller = StreamController<Map<String, dynamic>>.broadcast();
      when(() => mockClient.messageStream).thenAnswer((_) => controller.stream);

      final future = dataSource.listMessages(tSessionId);

      await Future.delayed(Duration.zero);
      controller.addError(Exception('network error'));

      expect(future, throwsA(isA<GatewayException>()));

      await controller.close();
    });
  });

  group('sendMessage', () {
    test('should send correct JSON and decode response', () async {
      final controller = StreamController<Map<String, dynamic>>.broadcast();
      when(() => mockClient.messageStream).thenAnswer((_) => controller.stream);

      final future = dataSource.sendMessage(tSessionId, 'Hi there');

      await Future.delayed(Duration.zero);

      verify(() => mockClient.send({
            'type': 'send_message',
            'sessionId': tSessionId,
            'text': 'Hi there',
          })).called(1);

      controller.add({
        'type': 'message_sent',
        'sessionId': tSessionId,
        'message': tMessageJson,
      });

      final result = await future;

      expect(result.id, tMessageModel.id);
      expect(result.text, tMessageModel.text);

      await controller.close();
    });

    test('should throw GatewayException on error', () async {
      final controller = StreamController<Map<String, dynamic>>.broadcast();
      when(() => mockClient.messageStream).thenAnswer((_) => controller.stream);

      final future = dataSource.sendMessage(tSessionId, 'Hi');

      await Future.delayed(Duration.zero);
      controller.addError(Exception('network error'));

      expect(future, throwsA(isA<GatewayException>()));

      await controller.close();
    });
  });

  group('watchNewMessages', () {
    test('should filter by sessionId and emit complete messages', () async {
      final controller = StreamController<Map<String, dynamic>>.broadcast();
      when(() => mockClient.messageStream).thenAnswer((_) => controller.stream);

      final messages = <ChatMessageModel>[];
      final sub = dataSource.watchNewMessages(tSessionId).listen(messages.add);

      controller.add({
        'type': 'message',
        'sessionId': 'other-session',
        'message': {
          'id': 'msg-other',
          'sessionId': 'other-session',
          'role': 'assistant',
          'text': 'Other',
          'timestamp': tTimestamp,
          'status': 'sent',
        },
      });

      controller.add({
        'type': 'message',
        'sessionId': tSessionId,
        'message': tMessageJson,
      });

      await Future.delayed(Duration.zero);

      expect(messages.length, 1);
      expect(messages.first.id, 'msg-1');

      await sub.cancel();
      await controller.close();
    });
  });

  group('watchMessageEvents (via watchMessageStream delegation)', () {
    test('watchMessageEvents should emit raw events including chunks', () async {
      final controller = StreamController<Map<String, dynamic>>.broadcast();
      when(() => mockClient.messageStream).thenAnswer((_) => controller.stream);

      final events = <Map<String, dynamic>>[];
      final sub = dataSource.watchMessageEvents().listen(events.add);

      controller.add({
        'type': 'message_chunk',
        'sessionId': tSessionId,
        'chunk': 'Hello',
      });

      controller.add({
        'type': 'message_chunk',
        'sessionId': 'other-session',
        'chunk': 'World',
      });

      await Future.delayed(Duration.zero);

      expect(events.length, 2);
      expect(events[0]['chunk'], 'Hello');
      expect(events[1]['chunk'], 'World');

      await sub.cancel();
      await controller.close();
    });
  });
}
