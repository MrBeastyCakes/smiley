class AppException implements Exception {
  final String message;
  final String? code;
  const AppException(this.message, {this.code});
  @override String toString() => 'AppException: $message${code != null ? ' ($code)' : ''}';
}

class GatewayException extends AppException {
  const GatewayException(super.message, {super.code});
}

class ConnectionTimeoutException extends GatewayException {
  const ConnectionTimeoutException() : super('Connection timed out', code: 'TIMEOUT');
}

class AuthenticationException extends AppException {
  const AuthenticationException(super.message, {super.code});
}

class StorageException extends AppException {
  const StorageException(super.message, {super.code});
}

class NotificationException extends AppException {
  const NotificationException(super.message, {super.code});
}

class VoiceException extends AppException {
  const VoiceException(super.message, {super.code});
}
