import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../entities/gateway_settings.dart';

abstract class SettingsRepository {
  Future<Either<Failure, GatewaySettings?>> getSettings();
  Future<Either<Failure, void>> saveSettings(GatewaySettings settings);
  Future<Either<Failure, void>> deleteSettings();
}
