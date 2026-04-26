import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:openclaw_client/src/core/di/service_locator.dart';
import 'package:openclaw_client/src/core/theme/app_theme.dart';
import 'package:openclaw_client/src/presentation/blocs/connection/connection_bloc.dart';
import 'package:openclaw_client/src/presentation/screens/connect_screen.dart';

void main() {
  setUpAll(() {
    ServiceLocator.init();
  });

  testGoldens('ConnectScreen renders correctly in dark theme', (tester) async {
    await tester.pumpWidgetBuilder(
      BlocProvider(
        create: (_) => ConnectionBloc(),
        child: const ConnectScreen(),
      ),
      wrapper: materialAppWrapper(
        theme: AppTheme.dark,
      ),
      surfaceSize: Device.phone.size,
    );

    await screenMatchesGolden(tester, 'connect_screen');
  });
}
