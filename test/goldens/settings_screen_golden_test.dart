import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:openclaw_client/src/core/errors/failures.dart';
import 'package:openclaw_client/src/core/theme/app_theme.dart';
import 'package:openclaw_client/src/domain/entities/gateway_settings.dart';
import 'package:openclaw_client/src/domain/repositories/settings_repository.dart';
import 'package:openclaw_client/src/presentation/blocs/settings/settings_bloc.dart';
import 'package:openclaw_client/src/presentation/screens/settings_screen.dart';

class _FakeSettingsRepository implements SettingsRepository {
  @override
  Future<Either<Failure, GatewaySettings?>> getSettings() async => const Right(null);
  @override
  Future<Either<Failure, void>> saveSettings(GatewaySettings settings) async => const Right(null);
  @override
  Future<Either<Failure, void>> deleteSettings() async => const Right(null);
}

class _FakeSettingsBloc extends SettingsBloc {
  _FakeSettingsBloc() : super(settingsRepository: _FakeSettingsRepository());
}

void main() {
  testGoldens('SettingsScreen renders correctly in dark theme', (tester) async {
    await tester.pumpWidgetBuilder(
      BlocProvider<SettingsBloc>(
        create: (_) => _FakeSettingsBloc(),
        child: const SettingsScreen(),
      ),
      wrapper: materialAppWrapper(
        theme: AppTheme.dark,
      ),
      surfaceSize: Device.phone.size,
    );

    await tester.pumpAndSettle();

    await screenMatchesGolden(tester, 'settings_screen');
  });
}
