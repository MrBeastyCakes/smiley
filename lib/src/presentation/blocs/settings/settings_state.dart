part of 'settings_bloc.dart';

sealed class SettingsState extends Equatable {
  const SettingsState();
  @override List<Object?> get props => [];
}

/// Initial / loading state.
class SettingsInitial extends SettingsState {
  const SettingsInitial();
}

class SettingsLoading extends SettingsState {
  const SettingsLoading();
}

/// Settings successfully loaded.
class SettingsLoaded extends SettingsState {
  final GatewaySettings? settings;
  final String? version;
  final String? buildNumber;

  const SettingsLoaded({this.settings, this.version, this.buildNumber});
  @override List<Object?> get props => [settings, version, buildNumber];
}

/// Settings successfully saved.
class SettingsSaved extends SettingsState {
  const SettingsSaved();
}

/// Cache cleared.
class SettingsCacheCleared extends SettingsState {
  const SettingsCacheCleared();
}

/// Disconnected from gateway.
class SettingsDisconnected extends SettingsState {
  const SettingsDisconnected();
}

/// Error occurred during a settings operation.
class SettingsError extends SettingsState {
  final String message;
  const SettingsError(this.message);
  @override List<Object?> get props => [message];
}
