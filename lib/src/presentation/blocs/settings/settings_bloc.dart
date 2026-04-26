import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/di/service_locator.dart';
import '../../../domain/entities/gateway_settings.dart';
import '../../../domain/repositories/settings_repository.dart';
import '../connection/connection_bloc.dart' as conn;

part 'settings_event.dart';
part 'settings_state.dart';

/// Bloc that manages settings load/save, disconnect, and cache clearing.
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsRepository _settingsRepository;
  final conn.ConnectionBloc? _connectionBloc;

  SettingsBloc({
    SettingsRepository? settingsRepository,
    conn.ConnectionBloc? connectionBloc,
  })  : _settingsRepository = settingsRepository ?? ServiceLocator.get<SettingsRepository>(),
        _connectionBloc = connectionBloc,
        super(const SettingsInitial()) {
    on<LoadSettings>(_onLoadSettings);
    on<SaveSettings>(_onSaveSettings);
    on<ClearCache>(_onClearCache);
    on<Disconnect>(_onDisconnect);
  }

  Future<void> _onLoadSettings(LoadSettings event, Emitter<SettingsState> emit) async {
    emit(const SettingsLoading());
    final result = await _settingsRepository.getSettings();
    result.fold(
      (failure) => emit(SettingsError(failure.message)),
      (settings) => emit(SettingsLoaded(
        settings: settings,
        version: AppConstants.appVersion,
        buildNumber: '1',
      )),
    );
  }

  Future<void> _onSaveSettings(SaveSettings event, Emitter<SettingsState> emit) async {
    emit(const SettingsLoading());
    final result = await _settingsRepository.saveSettings(event.settings);
    result.fold(
      (failure) => emit(SettingsError(failure.message)),
      (_) => emit(const SettingsSaved()),
    );
  }

  Future<void> _onClearCache(ClearCache event, Emitter<SettingsState> emit) async {
    emit(const SettingsLoading());
    try {
      await _settingsRepository.deleteSettings();
      emit(const SettingsCacheCleared());
    } catch (e) {
      emit(SettingsError('Failed to clear cache: $e'));
    }
  }

  Future<void> _onDisconnect(Disconnect event, Emitter<SettingsState> emit) async {
    emit(const SettingsLoading());
    try {
      // Trigger connection disconnect if available
      _connectionBloc?.add(const conn.DisconnectRequested());
      // Clear persisted settings
      await _settingsRepository.deleteSettings();
      emit(const SettingsDisconnected());
    } catch (e) {
      emit(SettingsError('Failed to disconnect: $e'));
    }
  }
}
