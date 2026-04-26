import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../domain/entities/gateway_settings.dart';

part 'connection_event.dart';
part 'connection_state.dart';

class ConnectionBloc extends Bloc<ConnectionEvent, ConnectionState> {
  ConnectionBloc() : super(const ConnectionInitial()) {
    on<ConnectRequested>(_onConnectRequested);
    on<DisconnectRequested>(_onDisconnectRequested);
  }

  Future<void> _onConnectRequested(ConnectRequested event, Emitter<ConnectionState> emit) async {
    emit(const ConnectionLoading());
    emit(ConnectionConnected(settings: event.settings));
  }

  Future<void> _onDisconnectRequested(DisconnectRequested event, Emitter<ConnectionState> emit) async {
    emit(const ConnectionInitial());
  }
}
