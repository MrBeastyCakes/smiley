import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openclaw_client/src/domain/entities/agent.dart';
import 'package:openclaw_client/src/presentation/screens/agent_detail_screen.dart';

void main() {
  const mockAgent = Agent(
    id: 'agent-test',
    name: 'TestBot',
    description: 'A helpful test agent.',
    capabilities: ['test', 'mock', 'verify'],
    defaultAutonomy: AutonomyLevel.suggest,
    isActive: true,
  );

  group('AgentDetailScreen', () {
    testWidgets('displays agent name', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: AgentDetailScreen(agent: mockAgent)),
      );

      expect(find.text('TestBot'), findsOneWidget);
    });

    testWidgets('displays agent description', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: AgentDetailScreen(agent: mockAgent)),
      );

      expect(find.text('A helpful test agent.'), findsOneWidget);
    });

    testWidgets('renders capability chips', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: AgentDetailScreen(agent: mockAgent)),
      );

      for (final cap in mockAgent.capabilities) {
        expect(find.text(cap), findsOneWidget);
      }
    });

    testWidgets('shows autonomy level selector', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: AgentDetailScreen(agent: mockAgent)),
      );

      expect(find.text('Observe'), findsOneWidget);
      expect(find.text('Suggest'), findsOneWidget);
      expect(find.text('Confirm'), findsOneWidget);
      expect(find.text('Autonomous'), findsOneWidget);

      // RadioListTile is used for autonomy selector
      expect(find.byType(RadioListTile<AutonomyLevel>), findsNWidgets(4));
    });

    testWidgets('has active/inactive toggle', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: AgentDetailScreen(agent: mockAgent)),
      );
      await tester.pumpAndSettle();

      // Scroll down to reveal the status section
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(find.byType(SwitchListTile), findsOneWidget);
    });
  });
}
