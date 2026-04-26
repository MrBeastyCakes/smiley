part of 'notification_bloc.dart';

sealed class NotificationState extends Equatable {
  const NotificationState();
  @override List<Object?> get props => [];
}

class NotificationInitial extends NotificationState {
  const NotificationInitial();
}

class NotificationShown extends NotificationState {
  final int id;
  const NotificationShown({required this.id});
  @override List<Object?> get props => [id];
}

class NotificationScheduled extends NotificationState {
  final int id;
  const NotificationScheduled({required this.id});
  @override List<Object?> get props => [id];
}

class NotificationCancelled extends NotificationState {
  final int id;
  const NotificationCancelled({required this.id});
  @override List<Object?> get props => [id];
}

class NotificationAllCancelled extends NotificationState {
  const NotificationAllCancelled();
}

class NotificationError extends NotificationState {
  final String message;
  const NotificationError({required this.message});
  @override List<Object?> get props => [message];
}
