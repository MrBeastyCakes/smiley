import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:openclaw_client/src/core/errors/failures.dart';
import 'package:openclaw_client/src/presentation/blocs/notification/notification_bloc.dart';
import 'package:openclaw_client/src/services/notification_service.dart';

class _MockNotificationService extends Mock implements NotificationService {}

void main() {
  group('NotificationBloc', () {
    late _MockNotificationService mockService;

    setUp(() {
      mockService = _MockNotificationService();
    });

    blocTest<NotificationBloc, NotificationState>(
      'emits NotificationInitial as initial state',
      build: () => NotificationBloc(service: mockService),
      expect: () => <NotificationState>[],
      verify: (bloc) {
        expect(bloc.state, const NotificationInitial());
      },
    );

    blocTest<NotificationBloc, NotificationState>(
      'emits NotificationShown on ShowNotification',
      build: () => NotificationBloc(service: mockService),
      setUp: () {
        when(() => mockService.showNotification(
              id: any(named: 'id'),
              title: any(named: 'title'),
              body: any(named: 'body'),
              payload: any(named: 'payload'),
            )).thenAnswer((_) async {});
      },
      act: (bloc) => bloc.add(const ShowNotification(
        id: 1,
        title: 'Test',
        body: 'Hello',
      )),
      expect: () => [
        const NotificationShown(id: 1),
      ],
    );

    blocTest<NotificationBloc, NotificationState>(
      'emits NotificationScheduled on ScheduleNotification',
      build: () => NotificationBloc(service: mockService),
      setUp: () {
        when(() => mockService.scheduleNotification(
              id: any(named: 'id'),
              title: any(named: 'title'),
              body: any(named: 'body'),
              scheduledDate: any(named: 'scheduledDate'),
              payload: any(named: 'payload'),
            )).thenAnswer((_) async {});
      },
      act: (bloc) => bloc.add(ScheduleNotification(
        id: 2,
        title: 'Reminder',
        body: 'Meeting in 5 min',
        scheduledDate: DateTime(2026, 4, 25, 10, 0),
      )),
      expect: () => [
        const NotificationScheduled(id: 2),
      ],
    );

    blocTest<NotificationBloc, NotificationState>(
      'emits NotificationCancelled on CancelNotification',
      build: () => NotificationBloc(service: mockService),
      setUp: () {
        when(() => mockService.cancelNotification(any()))
            .thenAnswer((_) async {});
      },
      act: (bloc) => bloc.add(const CancelNotification(id: 3)),
      expect: () => [
        const NotificationCancelled(id: 3),
      ],
    );

    blocTest<NotificationBloc, NotificationState>(
      'emits NotificationAllCancelled on CancelAllNotifications',
      build: () => NotificationBloc(service: mockService),
      setUp: () {
        when(() => mockService.cancelAll()).thenAnswer((_) async {});
      },
      act: (bloc) => bloc.add(const CancelAllNotifications()),
      expect: () => [
        const NotificationAllCancelled(),
      ],
    );

    blocTest<NotificationBloc, NotificationState>(
      'emits NotificationError on show failure',
      build: () => NotificationBloc(service: mockService),
      setUp: () {
        when(() => mockService.showNotification(
              id: any(named: 'id'),
              title: any(named: 'title'),
              body: any(named: 'body'),
              payload: any(named: 'payload'),
            )).thenThrow(Exception('boom'));
      },
      act: (bloc) => bloc.add(const ShowNotification(
        id: 1,
        title: 'Test',
        body: 'Hello',
      )),
      expect: () => [
        isA<NotificationError>().having(
          (s) => s.message,
          'message',
          contains('boom'),
        ),
      ],
    );
  });
}
