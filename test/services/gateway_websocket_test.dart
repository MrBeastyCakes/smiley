import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:openclaw_client/src/core/errors/exceptions.dart';
import 'package:openclaw_client/src/domain/entities/gateway_settings.dart';
import 'package:openclaw_client/src/services/gateway_websocket.dart';

void main() {
  group('GatewayWebSocketClient', () {
    late GatewayWebSocketClient client;

    setUp(() {
      client = GatewayWebSocketClient();
    });

    tearDown(() async {
      await client.dispose();
    });

    group('initial state', () {
      test('starts disconnected', () {
        expect(client.status, ConnectionStatus.disconnected);
        expect(client.isConnected, isFalse);
      });
    });

    group('send', () {
      test('throws when not connected', () {
        expect(
          () => client.send({'type': 'hello'}),
          throwsA(isA<GatewayException>().having(
            (e) => e.message,
            'message',
            'Not connected',
          )),
        );
      });
    });

    group('dispose', () {
      test('can be disposed cleanly', () async {
        expect(client.status, ConnectionStatus.disconnected);
        await client.dispose();
        expect(client.statusStream.isBroadcast, isTrue);
      });

      test('double dispose is safe', () async {
        await client.dispose();
        await client.dispose();
      });
    });

    group('streams', () {
      test('messageStream is broadcast', () {
        expect(client.messageStream.isBroadcast, isTrue);
      });

      test('statusStream is broadcast', () {
        expect(client.statusStream.isBroadcast, isTrue);
      });

      test('can listen to messageStream without errors when disconnected', () async {
        final messages = <Map<String, dynamic>>[];
        final sub = client.messageStream.listen(messages.add);
        await Future.delayed(Duration.zero);
        expect(messages, isEmpty);
        await sub.cancel();
      });
    });

    group('connect behavior', () {
      test('emits connecting on connect attempt', () async {
        final states = <ConnectionStatus>[];
        final sub = client.statusStream.listen(states.add);

        final settings = GatewaySettings(
          host: 'invalid-host',
          port: 1,
          token: 'test',
          useTls: false,
        );

        unawaited(client.connect(settings));
        await Future.delayed(const Duration(seconds: 1));

        expect(states, contains(ConnectionStatus.connecting));

        await sub.cancel();
      });
    });

    group('integration', () {
      test('connects to real gateway', () async {
        final settings = GatewaySettings(
          host: 'localhost',
          port: 18789,
          token: 'test-token',
          useTls: false,
        );

        final states = <ConnectionStatus>[];
        final sub = client.statusStream.listen(states.add);

        await client.connect(settings);
        await Future.delayed(const Duration(seconds: 2));

        expect(states, contains(ConnectionStatus.connecting));
        await sub.cancel();
      }, skip: 'Requires running gateway server');
    });
  });
}
