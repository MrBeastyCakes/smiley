import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openclaw_client/src/presentation/blocs/connection/connection_bloc.dart';
import 'package:openclaw_client/src/presentation/screens/home_screen.dart';

void main() {
  group('HomeScreen', () {
    testWidgets('displays bottom navigation tabs', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(
            create: (_) => ConnectionBloc(),
            child: const HomeScreen(),
          ),
        ),
      );

      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.text('Chat'), findsOneWidget);
      expect(find.text('Agents'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('starts on Chat tab and shows session list', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(
            create: (_) => ConnectionBloc(),
            child: const HomeScreen(),
          ),
        ),
      );

      expect(find.text('Chats'), findsOneWidget);
      // Verify mock session titles render
      expect(find.text('General chat'), findsOneWidget);
      expect(find.text('Code review helper'), findsOneWidget);
      expect(find.text('Trip planner'), findsOneWidget);
    });

    testWidgets('tapping Agents tab shows agent directory', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(
            create: (_) => ConnectionBloc(),
            child: const HomeScreen(),
          ),
        ),
      );

      await tester.tap(find.text('Agents'));
      await tester.pumpAndSettle();

      // Agent names should be visible instead of checking duplicate 'Agents' text
      expect(find.text('Rosalina'), findsOneWidget);
      expect(find.text('CodeBot'), findsOneWidget);
      expect(find.text('Planner'), findsOneWidget);
    });

    testWidgets('tapping Settings tab shows settings screen', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(
            create: (_) => ConnectionBloc(),
            child: const HomeScreen(),
          ),
        ),
      );

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      // Check for unique settings content (section headers are uppercased)
      expect(find.text('GATEWAY'), findsOneWidget);
      expect(find.text('APPEARANCE'), findsOneWidget);
    });

    testWidgets('session cards render with message counts', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(
            create: (_) => ConnectionBloc(),
            child: const HomeScreen(),
          ),
        ),
      );

      expect(find.text('42'), findsOneWidget); // General chat message count
      expect(find.text('18'), findsOneWidget); // Code review helper message count
      expect(find.text('7'), findsOneWidget);  // Trip planner message count
    });
  });
}
