part of 'settings_bloc.dart';

sealed class SettingsEvent extends Equatable {
  const SettingsEvent();
  @override List<Object?> get props => [];
}

/// Load current settings from local storage.
class LoadSettings extends SettingsEvent {
  const LoadSettings();
}

/// Save new settings to local storage.
class SaveSettings extends SettingsEvent {
  final GatewaySettings settings;
  const SaveSettings(this.settings);
  @override List<Object?> get props => [settings];
}

/// Clear local cached data (settings, sessions, messages).
class ClearCache extends SettingsEvent {
  const ClearCache();
}

/// Disconnect from gateway and clear connection state.
class Disconnect extends SettingsEvent {
  const Disconnect();
}
