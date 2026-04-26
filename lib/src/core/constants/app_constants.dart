/// App-wide constants.
abstract final class AppConstants {
  static const String appName = 'OpenClaw';
  static const String appVersion = '0.1.0';
  static const String defaultGatewayHost = '127.0.0.1';
  static const int defaultGatewayPort = 18789;
  static const Duration defaultConnectionTimeout = Duration(seconds: 10);
  static const Duration heartbeatInterval = Duration(seconds: 30);
  static const Duration reconnectDelay = Duration(seconds: 5);
  static const int maxReconnectAttempts = 5;
  static const double messageBubbleMaxWidthFactor = 0.82;
  static const Duration messageAnimationDuration = Duration(milliseconds: 150);
  static const Duration typingAnimationDuration = Duration(milliseconds: 1200);
  static const double minTapTargetSize = 44.0;
  static const Duration intentPreviewTimeout = Duration(seconds: 30);
  static const Duration undoWindow = Duration(seconds: 15);
}
