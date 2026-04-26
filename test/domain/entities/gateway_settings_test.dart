import 'package:flutter_test/flutter_test.dart';
import 'package:openclaw_client/src/domain/entities/gateway_settings.dart';

void main() {
  group('GatewaySettings', () {
    const settings = GatewaySettings(host: '127.0.0.1', port: 18789, token: 'test-token');

    test('properties', () {
      expect(settings.host, '127.0.0.1');
      expect(settings.port, 18789);
      expect(settings.token, 'test-token');
      expect(settings.useTls, false);
    });

    test('copyWith', () {
      final updated = settings.copyWith(host: 'new-host', useTls: true);
      expect(updated.host, 'new-host');
      expect(updated.useTls, true);
      expect(updated.port, settings.port);
    });

    test('equality', () {
      const s2 = GatewaySettings(host: '127.0.0.1', port: 18789, token: 'test-token');
      expect(settings, s2);
    });
  });
}
