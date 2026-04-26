import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openclaw_client/src/core/di/service_locator.dart';
import 'package:openclaw_client/src/presentation/blocs/connection/connection_bloc.dart';
import 'package:openclaw_client/src/presentation/screens/connect_screen.dart';

void main() {
  setUpAll(() {
    ServiceLocator.init();
  });

  group('ConnectScreen', () {
    testWidgets('displays OpenClaw title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(create: (_) => ConnectionBloc(), child: const ConnectScreen()),
        ),
      );
      expect(find.text('OpenClaw'), findsOneWidget);
      expect(find.text('Connect to your gateway'), findsOneWidget);
    });

    testWidgets('has host, port, token fields', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(create: (_) => ConnectionBloc(), child: const ConnectScreen()),
        ),
      );
      expect(find.widgetWithText(TextField, '127.0.0.1'), findsOneWidget);
      expect(find.widgetWithText(TextField, '18789'), findsOneWidget);
      expect(find.text('Connect'), findsOneWidget);
    });

    testWidgets('connect button is tappable', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(create: (_) => ConnectionBloc(), child: const ConnectScreen()),
        ),
      );
      await tester.tap(find.text('Connect'));
      await tester.pump();
      // Should trigger bloc event; state change depends on connection logic
    });
  });
}
