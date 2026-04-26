import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:openclaw_client/src/core/theme/app_theme.dart';
import 'package:openclaw_client/src/core/di/service_locator.dart';
import 'package:openclaw_client/src/presentation/blocs/connection/connection_bloc.dart';
import 'package:openclaw_client/src/presentation/screens/home_screen.dart';

void main() {
  testGoldens('HomeScreen renders all 3 tabs correctly', (tester) async {
    ServiceLocator.init();
    final connectionBloc = ConnectionBloc();

    await tester.pumpWidgetBuilder(
      BlocProvider.value(
        value: connectionBloc,
        child: const HomeScreen(),
      ),
      wrapper: materialAppWrapper(
        theme: AppTheme.dark,
      ),
      surfaceSize: Device.phone.size,
    );

    // Default tab: Chat
    await screenMatchesGolden(tester, 'home_screen_chat_tab');

    // Tap Agents tab
    await tester.tap(find.text('Agents'));
    await tester.pumpAndSettle();
    await screenMatchesGolden(tester, 'home_screen_agents_tab');

    // Tap Settings tab
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await screenMatchesGolden(tester, 'home_screen_settings_tab');
  });
}
