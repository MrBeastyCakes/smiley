import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:openclaw_client/src/core/errors/exceptions.dart';
import 'package:openclaw_client/src/data/datasources/settings_local_datasource.dart';
import 'package:openclaw_client/src/domain/entities/gateway_settings.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockFlutterSecureStorage mockSecureStorage;
  late SettingsLocalDataSource dataSource;

  const tSettings = GatewaySettings(
    host: '127.0.0.1',
    port: 18789,
    token: 'test-token',
    password: 'secret',
    useTls: true,
  );

  final tSettingsJson = {
    'host': '127.0.0.1',
    'port': 18789,
    'token': 'test-token',
    'password': 'secret',
    'useTls': true,
  };

  setUp(() {
    mockSecureStorage = MockFlutterSecureStorage();
    dataSource = SettingsLocalDataSourceImpl(secureStorage: mockSecureStorage);
  });

  group('getSettings', () {
    test('should return GatewaySettings when data exists in secure storage', () async {
      when(() => mockSecureStorage.read(key: any(named: 'key')))
          .thenAnswer((_) async => jsonEncode(tSettingsJson));

      final result = await dataSource.getSettings();

      expect(result, equals(tSettings));
      verify(() => mockSecureStorage.read(key: 'gateway_settings')).called(1);
    });

    test('should return null when no data exists in secure storage', () async {
      when(() => mockSecureStorage.read(key: any(named: 'key')))
          .thenAnswer((_) async => null);

      final result = await dataSource.getSettings();

      expect(result, isNull);
      verify(() => mockSecureStorage.read(key: 'gateway_settings')).called(1);
    });

    test('should return null when stored value is empty string', () async {
      when(() => mockSecureStorage.read(key: any(named: 'key')))
          .thenAnswer((_) async => '');

      final result = await dataSource.getSettings();

      expect(result, isNull);
      verify(() => mockSecureStorage.read(key: 'gateway_settings')).called(1);
    });

    test('should throw StorageException when secure storage throws', () async {
      when(() => mockSecureStorage.read(key: any(named: 'key')))
          .thenThrow(Exception('storage error'));

      expect(
        () => dataSource.getSettings(),
        throwsA(isA<StorageException>()),
      );
      verify(() => mockSecureStorage.read(key: 'gateway_settings')).called(1);
    });
  });

  group('saveSettings', () {
    test('should write JSON-encoded settings to secure storage', () async {
      when(() => mockSecureStorage.write(key: any(named: 'key'), value: any(named: 'value')))
          .thenAnswer((_) async {});

      await dataSource.saveSettings(tSettings);

      final expectedJson = jsonEncode(tSettingsJson);
      verify(() => mockSecureStorage.write(
        key: 'gateway_settings',
        value: expectedJson,
      )).called(1);
    });

    test('should throw StorageException when secure storage throws', () async {
      when(() => mockSecureStorage.write(key: any(named: 'key'), value: any(named: 'value')))
          .thenThrow(Exception('write error'));

      expect(
        () => dataSource.saveSettings(tSettings),
        throwsA(isA<StorageException>()),
      );
      verify(() => mockSecureStorage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      )).called(1);
    });
  });

  group('deleteSettings', () {
    test('should delete settings key from secure storage', () async {
      when(() => mockSecureStorage.delete(key: any(named: 'key')))
          .thenAnswer((_) async {});

      await dataSource.deleteSettings();

      verify(() => mockSecureStorage.delete(key: 'gateway_settings')).called(1);
    });

    test('should throw StorageException when secure storage throws', () async {
      when(() => mockSecureStorage.delete(key: any(named: 'key')))
          .thenThrow(Exception('delete error'));

      expect(
        () => dataSource.deleteSettings(),
        throwsA(isA<StorageException>()),
      );
      verify(() => mockSecureStorage.delete(key: 'gateway_settings')).called(1);
    });
  });
}
