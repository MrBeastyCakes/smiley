import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:openclaw_client/src/core/di/service_locator.dart';
import 'package:openclaw_client/src/presentation/blocs/connection/connection_bloc.dart';
import 'package:openclaw_client/src/presentation/screens/connect_screen.dart';
import 'package:openclaw_client/src/services/gateway_websocket.dart';

class MockGatewayWebSocketClient extends Mock implements GatewayWebSocketClient {}

void main() {
  setUpAll(() {
    ServiceLocator.init();
  });

  group('ConnectScreen', () {
    testWidgets('displays OpenClaw title', (tester) async {
      final client = MockGatewayWebSocketClient();
      when(() => client.statusStream).thenAnswer((_) => const Stream.empty());
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(create: (_) => ConnectionBloc(client: client), child: const ConnectScreen()),
        ),
      );
      expect(find.text('OpenClaw'), findsOneWidget);
      expect(find.text('Connect to your gateway'), findsOneWidget);
    });

    testWidgets('has host, port, token fields with default values', (tester) async {
      final client = MockGatewayWebSocketClient();
      when(() => client.statusStream).thenAnswer((_) => const Stream.empty());
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(create: (_) => ConnectionBloc(client: client), child: const ConnectScreen()),
        ),
      );
      expect(find.widgetWithText(TextField, '192.168.92.79'), findsOneWidget);
      expect(find.widgetWithText(TextField, '18789'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'F6fTiO8Lugn5'), findsOneWidget);
      expect(find.text('Connect'), findsOneWidget);
    });

    testWidgets('connect button triggers loading state', (tester) async {
      final client = MockGatewayWebSocketClient();
      when(() => client.statusStream).thenAnswer((_) => const Stream.empty());
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(create: (_) => ConnectionBloc(client: client), child: const ConnectScreen()),
        ),
      );
      await tester.tap(find.text('Connect'));
      await tester.pump();
      expect(find.text('Connecting…'), findsOneWidget);
      // Clean up pending timers from ping
      await tester.pumpAndSettle(const Duration(seconds: 6));
    });

    testWidgets('error banner appears on ConnectionError state', (tester) async {
      final client = MockGatewayWebSocketClient();
      when(() => client.statusStream).thenAnswer((_) => const Stream.empty());
      final bloc = ConnectionBloc(client: client);
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: const ConnectScreen(),
          ),
        ),
      );
      bloc.emit(const ConnectionError(message: 'Connection refused', code: ConnectionErrorCode.connectionRefused));
      await tester.pump();
      expect(find.textContaining('Connection refused'), findsOneWidget);
    });
  });
}
