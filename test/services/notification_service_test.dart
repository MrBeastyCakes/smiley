import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:openclaw_client/src/services/notification_service.dart';

class MockFlutterLocalNotificationsPlugin extends Mock
    implements FlutterLocalNotificationsPlugin {}

class FakeAndroidFlutterLocalNotificationsPlugin extends Fake
    implements AndroidFlutterLocalNotificationsPlugin {
  @override
  Future<void> createNotificationChannel(
    AndroidNotificationChannel channel,
  ) async {}
}

void main() {
  late MockFlutterLocalNotificationsPlugin mockPlugin;
  late NotificationService service;

  setUpAll(() {
    tz_data.initializeTimeZones();

    registerFallbackValue(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    registerFallbackValue(
      const AndroidNotificationChannel(
        'test',
        'Test',
        importance: Importance.high,
      ),
    );
    registerFallbackValue(
      const NotificationDetails(
        android: AndroidNotificationDetails('test', 'Test'),
      ),
    );
    registerFallbackValue(AndroidScheduleMode.exactAllowWhileIdle);
    registerFallbackValue(tz.TZDateTime.now(tz.local));
  });

  setUp(() {
    mockPlugin = MockFlutterLocalNotificationsPlugin();
    service = NotificationService(plugin: mockPlugin);
  });

  tearDown(() {
    service.dispose();
  });

  group('initialize', () {
    test('completes without error', () async {
      when(
        () => mockPlugin.initialize(
          any(),
          onDidReceiveNotificationResponse:
              any(named: 'onDidReceiveNotificationResponse'),
          onDidReceiveBackgroundNotificationResponse:
              any(named: 'onDidReceiveBackgroundNotificationResponse'),
        ),
      ).thenAnswer((_) async => true);

      when(
        () => mockPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>(),
      ).thenReturn(FakeAndroidFlutterLocalNotificationsPlugin());

      await expectLater(service.initialize(), completes);
    });
  });

  group('showNotification', () {
    test('completes without error', () async {
      when(
        () => mockPlugin.show(
          any(),
          any(),
          any(),
          any(),
          payload: any(named: 'payload'),
        ),
      ).thenAnswer((_) async {});

      await expectLater(
        service.showNotification(
          id: 1,
          title: 'Test',
          body: 'Test body',
          payload: '{"key":"value"}',
        ),
        completes,
      );
    });
  });

  group('cancelNotification', () {
    test('completes without error', () async {
      when(() => mockPlugin.cancel(any())).thenAnswer((_) async {});

      await expectLater(service.cancelNotification(1), completes);
    });
  });

  group('cancelAll', () {
    test('completes without error', () async {
      when(() => mockPlugin.cancelAll()).thenAnswer((_) async {});

      await expectLater(service.cancelAll(), completes);
    });
  });

  group('scheduleNotification', () {
    test('completes without error', () async {
      when(
        () => mockPlugin.zonedSchedule(
          any(),
          any(),
          any(),
          any(),
          any(),
          payload: any(named: 'payload'),
          androidScheduleMode: any(named: 'androidScheduleMode'),
        ),
      ).thenAnswer((_) async {});

      await expectLater(
        service.scheduleNotification(
          id: 1,
          title: 'Test',
          body: 'Test body',
          scheduledDate: DateTime.now().add(const Duration(hours: 1)),
          payload: '{"key":"value"}',
        ),
        completes,
      );
    });
  });

  group('onNotificationTap', () {
    test('emits payload on tap', () async {
      final tapController = StreamController<String?>.broadcast();
      final testService = NotificationService(
        plugin: mockPlugin,
        tapController: tapController,
      );
      addTearDown(testService.dispose);

      when(
        () => mockPlugin.initialize(
          any(),
          onDidReceiveNotificationResponse:
              any(named: 'onDidReceiveNotificationResponse'),
          onDidReceiveBackgroundNotificationResponse:
              any(named: 'onDidReceiveBackgroundNotificationResponse'),
        ),
      ).thenAnswer((_) async => true);

      when(
        () => mockPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>(),
      ).thenReturn(FakeAndroidFlutterLocalNotificationsPlugin());

      await testService.initialize();

      const payload = '{"key":"value"}';
      final future = testService.onNotificationTap.first;
      tapController.add(payload);

      await expectLater(future, completion(equals(payload)));
    });
  });
}
