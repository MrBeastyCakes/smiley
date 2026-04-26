import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/errors/exceptions.dart';
import '../../domain/entities/gateway_settings.dart';

abstract class SettingsLocalDataSource {
  Future<GatewaySettings?> getSettings();
  Future<void> saveSettings(GatewaySettings settings);
  Future<void> deleteSettings();
}

class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  final FlutterSecureStorage secureStorage;
  static const String _settingsKey = 'gateway_settings';

  const SettingsLocalDataSourceImpl({required this.secureStorage});

  @override
  Future<GatewaySettings?> getSettings() async {
    try {
      final jsonString = await secureStorage.read(key: _settingsKey);
      if (jsonString == null || jsonString.isEmpty) {
        return null;
      }
      final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      return _mapJsonToGatewaySettings(jsonMap);
    } on StorageException {
      rethrow;
    } catch (e) {
      throw StorageException('Failed to read settings: \$e');
    }
  }

  @override
  Future<void> saveSettings(GatewaySettings settings) async {
    try {
      final jsonMap = _mapGatewaySettingsToJson(settings);
      final jsonString = jsonEncode(jsonMap);
      await secureStorage.write(key: _settingsKey, value: jsonString);
    } on StorageException {
      rethrow;
    } catch (e) {
      throw StorageException('Failed to save settings: \$e');
    }
  }

  @override
  Future<void> deleteSettings() async {
    try {
      await secureStorage.delete(key: _settingsKey);
    } on StorageException {
      rethrow;
    } catch (e) {
      throw StorageException('Failed to delete settings: \$e');
    }
  }

  GatewaySettings _mapJsonToGatewaySettings(Map<String, dynamic> json) {
    return GatewaySettings(
      host: json['host'] as String,
      port: json['port'] as int,
      token: json['token'] as String,
      password: json['password'] as String?,
      useTls: json['useTls'] as bool? ?? false,
    );
  }

  Map<String, dynamic> _mapGatewaySettingsToJson(GatewaySettings settings) {
    return {
      'host': settings.host,
      'port': settings.port,
      'token': settings.token,
      'password': settings.password,
      'useTls': settings.useTls,
    };
  }
}
