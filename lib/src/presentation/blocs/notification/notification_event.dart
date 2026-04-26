part of 'notification_bloc.dart';

sealed class NotificationEvent extends Equatable {
  const NotificationEvent();
  @override List<Object?> get props => [];
}

class ShowNotification extends NotificationEvent {
  final int id;
  final String title;
  final String body;
  final String? payload;

  const ShowNotification({
    required this.id,
    required this.title,
    required this.body,
    this.payload,
  });

  @override List<Object?> get props => [id, title, body, payload];
}

class ScheduleNotification extends NotificationEvent {
  final int id;
  final String title;
  final String body;
  final DateTime scheduledDate;
  final String? payload;

  const ScheduleNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledDate,
    this.payload,
  });

  @override List<Object?> get props => [id, title, body, scheduledDate, payload];
}

class CancelNotification extends NotificationEvent {
  final int id;
  const CancelNotification({required this.id});
  @override List<Object?> get props => [id];
}

class CancelAllNotifications extends NotificationEvent {
  const CancelAllNotifications();
}
