import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:openclaw_client/src/core/theme/app_theme.dart';
import 'package:openclaw_client/src/presentation/screens/settings_screen.dart';

void main() {
  testGoldens('SettingsScreen renders correctly in dark theme', (tester) async {
    await tester.pumpWidgetBuilder(
      const SettingsScreen(),
      wrapper: materialAppWrapper(
        theme: AppTheme.dark,
      ),
      surfaceSize: Device.phone.size,
    );

    await tester.pumpAndSettle();

    await screenMatchesGolden(tester, 'settings_screen');
  });
}
