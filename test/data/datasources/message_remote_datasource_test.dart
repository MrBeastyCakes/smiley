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
  });

  group('listMessages', () {
    test('should call sendRequest and decode response', () async {
      when(() => mockClient.sendRequest(any())).thenAnswer((_) async => {
        'messages': [tMessageJson],
      });

      final result = await dataSource.listMessages(tSessionId);

      expect(result.length, 1);
      expect(result.first.id, tMessageModel.id);
      expect(result.first.text, tMessageModel.text);

      verify(() => mockClient.sendRequest({
        'type': 'list_messages',
        'sessionId': tSessionId,
      })).called(1);
    });

    test('should throw GatewayException when sendRequest fails', () async {
      when(() => mockClient.sendRequest(any())).thenThrow(
        const GatewayException('Not connected', code: 'NOT_CONNECTED'),
      );

      expect(
        () => dataSource.listMessages(tSessionId),
        throwsA(isA<GatewayException>()),
      );
    });
  });

  group('sendMessage', () {
    test('should call sendRequest and decode response', () async {
      when(() => mockClient.sendRequest(any())).thenAnswer((_) async => {
        'message': tMessageJson,
      });

      final result = await dataSource.sendMessage(tSessionId, 'Hi there');

      expect(result.id, tMessageModel.id);
      expect(result.text, tMessageModel.text);

      verify(() => mockClient.sendRequest({
        'type': 'send_message',
        'sessionId': tSessionId,
        'text': 'Hi there',
      })).called(1);
    });
  });

  group('watchNewMessages', () {
    test('should filter by sessionId and emit complete messages', () async {
      final controller = StreamController<Map<String, dynamic>>.broadcast();
      when(() => mockClient.eventStream).thenAnswer((_) => controller.stream);

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

  group('watchMessageEvents', () {
    test('should emit raw events including chunks', () async {
      final controller = StreamController<Map<String, dynamic>>.broadcast();
      when(() => mockClient.eventStream).thenAnswer((_) => controller.stream);

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
