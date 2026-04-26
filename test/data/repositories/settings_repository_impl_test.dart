import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:openclaw_client/src/core/errors/exceptions.dart';
import 'package:openclaw_client/src/core/errors/failures.dart';
import 'package:openclaw_client/src/data/datasources/settings_local_datasource.dart';
import 'package:openclaw_client/src/data/repositories/settings_repository_impl.dart';
import 'package:openclaw_client/src/domain/entities/gateway_settings.dart';

class MockSettingsLocalDataSource extends Mock implements SettingsLocalDataSource {}

class FakeGatewaySettings extends Fake implements GatewaySettings {}

void main() {
  setUpAll(() {
    registerFallbackValue(const GatewaySettings(host: '', port: 0, token: ''));
  });

  late MockSettingsLocalDataSource mockDataSource;
  late SettingsRepositoryImpl repository;

  const tSettings = GatewaySettings(
    host: '127.0.0.1',
    port: 18789,
    token: 'test-token',
    password: 'secret',
    useTls: true,
  );

  setUp(() {
    mockDataSource = MockSettingsLocalDataSource();
    repository = SettingsRepositoryImpl(localDataSource: mockDataSource);
  });

  group('getSettings', () {
    test('should return Right(GatewaySettings) from datasource', () async {
      when(() => mockDataSource.getSettings()).thenAnswer((_) async => tSettings);

      final result = await repository.getSettings();

      expect(result, equals(const Right<Failure, GatewaySettings>(tSettings)));
      verify(() => mockDataSource.getSettings()).called(1);
    });

    test('should return Right(null) when no settings stored', () async {
      when(() => mockDataSource.getSettings()).thenAnswer((_) async => null);

      final result = await repository.getSettings();

      expect(result, equals(const Right<Failure, GatewaySettings?>(null)));
      verify(() => mockDataSource.getSettings()).called(1);
    });

    test('should return Left(StorageFailure) when datasource throws StorageException', () async {
      when(() => mockDataSource.getSettings()).thenThrow(const StorageException('read failed', code: 'READ_ERR'));

      final result = await repository.getSettings();

      expect(result, equals(const Left<Failure, GatewaySettings?>(StorageFailure('read failed', code: 'READ_ERR'))));
      verify(() => mockDataSource.getSettings()).called(1);
    });

    test('should return Left(StorageFailure) when datasource throws unexpected exception', () async {
      when(() => mockDataSource.getSettings()).thenThrow(Exception('boom'));

      final result = await repository.getSettings();

      expect(result, isA<Left<Failure, GatewaySettings?>>());
      result.fold(
        (failure) => expect(failure.message, 'Unexpected error while reading settings'),
        (_) => fail('should be Left'),
      );
      verify(() => mockDataSource.getSettings()).called(1);
    });
  });

  group('saveSettings', () {
    test('should return Right(null) when datasource succeeds', () async {
      when(() => mockDataSource.saveSettings(any())).thenAnswer((_) async {});

      final result = await repository.saveSettings(tSettings);

      expect(result, equals(const Right<Failure, void>(null)));
      verify(() => mockDataSource.saveSettings(tSettings)).called(1);
    });

    test('should return Left(StorageFailure) when datasource throws StorageException', () async {
      when(() => mockDataSource.saveSettings(any())).thenThrow(const StorageException('write failed', code: 'WRITE_ERR'));

      final result = await repository.saveSettings(tSettings);

      expect(result, equals(const Left<Failure, void>(StorageFailure('write failed', code: 'WRITE_ERR'))));
      verify(() => mockDataSource.saveSettings(tSettings)).called(1);
    });

    test('should return Left(StorageFailure) on unexpected exception', () async {
      when(() => mockDataSource.saveSettings(any())).thenThrow(Exception('boom'));

      final result = await repository.saveSettings(tSettings);

      expect(result, isA<Left<Failure, void>>());
      result.fold(
        (failure) => expect(failure.message, 'Unexpected error while saving settings'),
        (_) => fail('should be Left'),
      );
      verify(() => mockDataSource.saveSettings(tSettings)).called(1);
    });
  });

  group('deleteSettings', () {
    test('should return Right(null) when datasource succeeds', () async {
      when(() => mockDataSource.deleteSettings()).thenAnswer((_) async {});

      final result = await repository.deleteSettings();

      expect(result, equals(const Right<Failure, void>(null)));
      verify(() => mockDataSource.deleteSettings()).called(1);
    });

    test('should return Left(StorageFailure) when datasource throws StorageException', () async {
      when(() => mockDataSource.deleteSettings()).thenThrow(const StorageException('delete failed', code: 'DEL_ERR'));

      final result = await repository.deleteSettings();

      expect(result, equals(const Left<Failure, void>(StorageFailure('delete failed', code: 'DEL_ERR'))));
      verify(() => mockDataSource.deleteSettings()).called(1);
    });

    test('should return Left(StorageFailure) on unexpected exception', () async {
      when(() => mockDataSource.deleteSettings()).thenThrow(Exception('boom'));

      final result = await repository.deleteSettings();

      expect(result, isA<Left<Failure, void>>());
      result.fold(
        (failure) => expect(failure.message, 'Unexpected error while deleting settings'),
        (_) => fail('should be Left'),
      );
      verify(() => mockDataSource.deleteSettings()).called(1);
    });
  });
}
