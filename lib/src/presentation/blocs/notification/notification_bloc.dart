import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../core/di/service_locator.dart';
import '../../../services/notification_service.dart';

part 'notification_event.dart';
part 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationService _service;

  NotificationBloc({NotificationService? service})
    : _service = service ?? ServiceLocator.get<NotificationService>(),
      super(const NotificationInitial()) {
    on<ShowNotification>(_onShow);
    on<ScheduleNotification>(_onSchedule);
    on<CancelNotification>(_onCancel);
    on<CancelAllNotifications>(_onCancelAll);
  }

  Future<void> _onShow(ShowNotification event, Emitter<NotificationState> emit) async {
    try {
      await _service.showNotification(
        id: event.id,
        title: event.title,
        body: event.body,
        payload: event.payload,
      );
      emit(NotificationShown(id: event.id));
    } catch (e) {
      emit(NotificationError(message: e.toString()));
    }
  }

  Future<void> _onSchedule(ScheduleNotification event, Emitter<NotificationState> emit) async {
    try {
      await _service.scheduleNotification(
        id: event.id,
        title: event.title,
        body: event.body,
        scheduledDate: event.scheduledDate,
        payload: event.payload,
      );
      emit(NotificationScheduled(id: event.id));
    } catch (e) {
      emit(NotificationError(message: e.toString()));
    }
  }

  Future<void> _onCancel(CancelNotification event, Emitter<NotificationState> emit) async {
    try {
      await _service.cancelNotification(event.id);
      emit(NotificationCancelled(id: event.id));
    } catch (e) {
      emit(NotificationError(message: e.toString()));
    }
  }

  Future<void> _onCancelAll(CancelAllNotifications event, Emitter<NotificationState> emit) async {
    try {
      await _service.cancelAll();
      emit(const NotificationAllCancelled());
    } catch (e) {
      emit(NotificationError(message: e.toString()));
    }
  }
}
