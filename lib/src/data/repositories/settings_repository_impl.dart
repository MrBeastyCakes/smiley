import 'package:dartz/dartz.dart';

import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/gateway_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_local_datasource.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsLocalDataSource localDataSource;

  const SettingsRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, GatewaySettings?>> getSettings() async {
    try {
      final settings = await localDataSource.getSettings();
      return Right(settings);
    } on StorageException catch (e) {
      return Left(StorageFailure(e.message, code: e.code));
    } catch (e) {
      return Left(StorageFailure('Unexpected error while reading settings'));
    }
  }

  @override
  Future<Either<Failure, void>> saveSettings(GatewaySettings settings) async {
    try {
      await localDataSource.saveSettings(settings);
      return const Right(null);
    } on StorageException catch (e) {
      return Left(StorageFailure(e.message, code: e.code));
    } catch (e) {
      return Left(StorageFailure('Unexpected error while saving settings'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteSettings() async {
    try {
      await localDataSource.deleteSettings();
      return const Right(null);
    } on StorageException catch (e) {
      return Left(StorageFailure(e.message, code: e.code));
    } catch (e) {
      return Left(StorageFailure('Unexpected error while deleting settings'));
    }
  }
}
