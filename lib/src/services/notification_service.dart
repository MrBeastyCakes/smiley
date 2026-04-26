import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../core/errors/exceptions.dart';

/// NotificationService — local push notifications for OpenClaw client.
///
/// Responsibilities:
/// - Initialize notification channels (Android) + request permissions (iOS)
/// - Show notification: title, body, payload (optional JSON)
/// - Cancel specific notification by ID
/// - Cancel all notifications
/// - Handle tap on notification (return payload to caller)
/// - Schedule notification for future time
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin;
  final StreamController<String?> _tapController;

  static const String _channelId = 'openclaw_messages';
  static const String _channelName = 'OpenClaw Messages';
  static const String _channelDescription =
      'Notifications for new messages and agent actions';

  NotificationService({
    FlutterLocalNotificationsPlugin? plugin,
    StreamController<String?>? tapController,
  })  : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
        _tapController = tapController ?? StreamController<String?>.broadcast();

  /// Emits the payload whenever a notification is tapped.
  Stream<String?> get onNotificationTap => _tapController.stream;

  /// Initializes notification channels and requests permissions.
  Future<void> initialize() async {
    try {
      tz_data.initializeTimeZones();

      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      );

      await _plugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
        onDidReceiveBackgroundNotificationResponse:
            _onBackgroundNotificationResponse,
      );

      final androidPlugin =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDescription,
            importance: Importance.high,
          ),
        );
      }
    } catch (e) {
      throw NotificationException(
        'Failed to initialize notifications: $e',
        code: 'INIT_FAILED',
      );
    }
  }

  /// Shows an immediate notification.
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      final details = _buildNotificationDetails();
      await _plugin.show(id, title, body, details, payload: payload);
    } catch (e) {
      throw NotificationException(
        'Failed to show notification: $e',
        code: 'SHOW_FAILED',
      );
    }
  }

  /// Schedules a notification for a future [scheduledDate].
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    try {
      final details = _buildNotificationDetails();
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        _toTzDateTime(scheduledDate),
        details,
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      throw NotificationException(
        'Failed to schedule notification: $e',
        code: 'SCHEDULE_FAILED',
      );
    }
  }

  /// Cancels a specific notification by [id].
  Future<void> cancelNotification(int id) async {
    try {
      await _plugin.cancel(id);
    } catch (e) {
      throw NotificationException(
        'Failed to cancel notification: $e',
        code: 'CANCEL_FAILED',
      );
    }
  }

  /// Cancels all notifications.
  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (e) {
      throw NotificationException(
        'Failed to cancel all notifications: $e',
        code: 'CANCEL_ALL_FAILED',
      );
    }
  }

  /// Disposes internal resources.
  void dispose() {
    _tapController.close();
  }

  NotificationDetails _buildNotificationDetails() {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    return const NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );
  }

  void _onNotificationResponse(NotificationResponse response) {
    _tapController.add(response.payload);
  }

  static void _onBackgroundNotificationResponse(NotificationResponse response) {
    // Background taps are handled by the OS; we rely on the foreground
    // callback when the app is brought back to the foreground.
  }

  tz.TZDateTime _toTzDateTime(DateTime date) {
    return tz.TZDateTime.from(date, tz.local);
  }
}
