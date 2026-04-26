import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:openclaw_client/src/core/errors/exceptions.dart';
import 'package:openclaw_client/src/data/datasources/session_remote_datasource.dart';
import 'package:openclaw_client/src/data/models/session_model.dart';
import 'package:openclaw_client/src/services/gateway_websocket.dart';

class MockGatewayWebSocketClient extends Mock implements GatewayWebSocketClient {}

void main() {
  late MockGatewayWebSocketClient mockClient;
  late SessionRemoteDataSourceImpl dataSource;

  final tSessionJson = {
    'id': 'session-1',
    'title': 'Test Session',
    'agentId': 'agent-1',
    'createdAt': '2026-04-25T12:00:00.000',
    'updatedAt': '2026-04-25T12:00:00.000',
    'messageCount': 5,
    'isPinned': false,
    'isArchived': false,
    'lastMessagePreview': 'Hello',
  };

  final tSessionJsonList = [tSessionJson];

  setUp(() {
    mockClient = MockGatewayWebSocketClient();
    dataSource = SessionRemoteDataSourceImpl(client: mockClient);
  });

  group('listSessions', () {
    test('should call sendRequest and decode response', () async {
      when(() => mockClient.sendRequest(any())).thenAnswer(
        (_) async => {'sessions': tSessionJsonList},
      );

      final result = await dataSource.listSessions();

      expect(result.length, 1);
      expect(result.first.id, 'session-1');
      verify(() => mockClient.sendRequest({'type': 'list_sessions'})).called(1);
    });

    test('should throw GatewayException when sendRequest fails', () async {
      when(() => mockClient.sendRequest(any())).thenThrow(
        const GatewayException('Not connected', code: 'NOT_CONNECTED'),
      );

      expect(
        () => dataSource.listSessions(),
        throwsA(
          isA<GatewayException>().having((e) => e.message, 'message', 'Not connected'),
        ),
      );
    });
  });

  group('getSessionById', () {
    test('should call sendRequest and decode response', () async {
      when(() => mockClient.sendRequest(any())).thenAnswer(
        (_) async => {'session': tSessionJson},
      );

      final result = await dataSource.getSessionById('session-1');

      expect(result.id, 'session-1');
      expect(result.title, 'Test Session');
      verify(() => mockClient.sendRequest({'type': 'get_session', 'id': 'session-1'})).called(1);
    });
  });

  group('pinSession', () {
    test('should call sendRequest', () async {
      when(() => mockClient.sendRequest(any())).thenAnswer((_) async => {});

      await dataSource.pinSession('session-1', true);

      verify(() => mockClient.sendRequest({'type': 'pin_session', 'id': 'session-1', 'pinned': true})).called(1);
    });
  });

  group('archiveSession', () {
    test('should call sendRequest', () async {
      when(() => mockClient.sendRequest(any())).thenAnswer((_) async => {});

      await dataSource.archiveSession('session-1');

      verify(() => mockClient.sendRequest({'type': 'archive_session', 'id': 'session-1'})).called(1);
    });
  });

  group('watchSessions', () {
    test('should filter session_update events', () async {
      final controller = StreamController<Map<String, dynamic>>();
      when(() => mockClient.eventStream).thenAnswer((_) => controller.stream);

      final stream = dataSource.watchSessions();
      final results = <List<SessionModel>>[];
      final subscription = stream.listen(results.add);

      controller.add({'type': 'ping'});
      controller.add({'type': 'session_update', 'sessions': tSessionJsonList});
      controller.add({'type': 'other_event'});
      controller.add({'type': 'session_update', 'sessions': []});

      await Future.delayed(Duration.zero);

      expect(results.length, 2);
      expect(results.first.length, 1);
      expect(results.first.first.id, 'session-1');
      expect(results.last.length, 0);

      await subscription.cancel();
      await controller.close();
    });
  });
}
