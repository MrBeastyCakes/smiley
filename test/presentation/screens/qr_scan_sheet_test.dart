import 'package:flutter_test/flutter_test.dart';
import 'package:openclaw_client/src/domain/entities/gateway_settings.dart';
import 'package:openclaw_client/src/presentation/screens/qr_scan_sheet.dart';

void main() {
  group('parseGatewayQR', () {
    test('parses valid QR JSON', () {
      final json = '{"host": "192.168.1.100", "port": 18789, "token": "abc123"}';
      final result = parseGatewayQR(json);

      expect(result, isNotNull);
      expect(result!.host, '192.168.1.100');
      expect(result.port, 18789);
      expect(result.token, 'abc123');
    });

    test('returns null for invalid JSON', () {
      final result = parseGatewayQR('not json');
      expect(result, isNull);
    });

    test('returns null for missing fields', () {
      final result = parseGatewayQR('{"host": "1.2.3.4"}');
      expect(result, isNull);
    });

    test('returns null for empty string', () {
      final result = parseGatewayQR('');
      expect(result, isNull);
    });
  });
}
