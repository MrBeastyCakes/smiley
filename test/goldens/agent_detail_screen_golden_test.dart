import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:openclaw_client/src/core/theme/app_theme.dart';
import 'package:openclaw_client/src/domain/entities/agent.dart';
import 'package:openclaw_client/src/presentation/screens/agent_detail_screen.dart';

void main() {
  const mockAgent = Agent(
    id: 'agent-rosalina',
    name: 'Rosalina',
    description:
        'Queen of the galaxy. Warm, sarcastic, and always helpful.',
    capabilities: ['chat', 'search', 'summarize', 'weather'],
    defaultAutonomy: AutonomyLevel.suggest,
    isActive: true,
    lastActiveAt: null,
  );

  testGoldens('AgentDetailScreen renders mock agent in dark theme', (tester) async {
    await tester.pumpWidgetBuilder(
      const AgentDetailScreen(agent: mockAgent),
      wrapper: materialAppWrapper(
        theme: AppTheme.dark,
      ),
      surfaceSize: Device.phone.size,
    );

    await tester.pumpAndSettle();

    await screenMatchesGolden(tester, 'agent_detail_screen');
  });
}
