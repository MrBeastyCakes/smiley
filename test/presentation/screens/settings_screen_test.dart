import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openclaw_client/src/presentation/screens/settings_screen.dart';

void main() {
  group('SettingsScreen', () {
    testWidgets('displays settings title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SettingsScreen()),
      );

      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('renders gateway connection fields', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SettingsScreen()),
      );

      expect(find.text('Host'), findsOneWidget);
      expect(find.text('Port'), findsOneWidget);
      expect(find.text('Token'), findsOneWidget);

      // Verify default values displayed
      expect(find.text('127.0.0.1'), findsOneWidget);
      expect(find.text('18789'), findsOneWidget);
      expect(find.text('••••••••'), findsOneWidget);
    });

    testWidgets('has theme toggle switch', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SettingsScreen()),
      );

      expect(find.text('Theme'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('has clear data button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SettingsScreen()),
      );

      expect(find.text('Clear all data'), findsOneWidget);
    });

    testWidgets('shows version info', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SettingsScreen()),
      );

      expect(find.text('Version'), findsOneWidget);
      expect(find.text('0.1.0+1'), findsOneWidget);
      expect(find.text('Build'), findsOneWidget);
      expect(find.text('aurum-dark'), findsOneWidget);
    });
  });
}
