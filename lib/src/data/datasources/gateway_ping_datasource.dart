import 'dart:io';

import '../../core/errors/exceptions.dart';

/// Simple TCP connectivity check before WebSocket handshake.
class GatewayPingDataSource {
  final Duration timeout;

  const GatewayPingDataSource({this.timeout = const Duration(seconds: 5)});

  /// Attempts a TCP socket connection to verify the host is reachable.
  /// Throws detailed [GatewayException]s for common failures.
  Future<void> ping(String host, int port) async {
    try {
      final socket = await Socket.connect(host, port, timeout: timeout);
      await socket.close();
    } on SocketException catch (e) {
      final osError = e.osError;
      final errorCode = osError?.errorCode ?? 0;
      String userMessage;
      switch (errorCode) {
        case 10061:
        case 111:
          userMessage = 'Connection refused at $host:$port.\n\n'
              '• Is the gateway running? (run: openclaw gateway status)\n'
              '• Is the port correct? Default is 18789.\n'
              '• Is a firewall blocking port $port?';
          break;
        case 10051:
        case 101:
          userMessage = 'Network unreachable.\n\n'
              '• Are your phone and gateway on the same WiFi?\n'
              '• Is the host address correct?\n'
              '• Try using the gateway\'s local IP (e.g. 192.168.x.x)';
          break;
        case 10060:
        case 110:
          userMessage = 'Connection timed out after ${timeout.inSeconds}s.\n\n'
              '• The gateway may be behind a firewall.\n'
              '• The host may be unreachable.\n'
              '• Try pinging the gateway from another device.';
          break;
        case 8:
        case -2:
          userMessage = 'Host "$host" not found.\n\n'
              '• Check the IP address or hostname.\n'
              '• Make sure DNS resolves correctly.';
          break;
        default:
          userMessage = 'Could not reach $host:$port.\n\n'
              'Error: ${e.message}\n'
              'Code: $errorCode';
      }
      throw GatewayException(userMessage, code: 'PING_FAILED_$errorCode');
    } catch (e) {
      if (e is GatewayException) rethrow;
      throw GatewayException('Unexpected error: $e', code: 'PING_UNEXPECTED');
    }
  }
}
