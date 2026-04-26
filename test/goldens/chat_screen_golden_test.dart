import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:openclaw_client/src/core/theme/app_theme.dart';
import 'package:openclaw_client/src/domain/entities/chat_message.dart';
import 'package:openclaw_client/src/presentation/blocs/chat/chat_bloc.dart';
import 'package:openclaw_client/src/presentation/screens/chat_screen.dart';

import '../helpers/test_helpers.dart' as helpers;

void main() {
  testGoldens('ChatScreen renders mock messages in dark theme', (tester) async {
    final chatBloc = ChatBloc(repository: helpers.NoOpMessageRepository());

    // Seed mock messages by adding them after the bloc is created
    chatBloc.add(const ChatStarted());
    chatBloc.add(
      MessageReceived(
        ChatMessage(
          id: 'msg-1',
          sessionId: 'test-session',
          role: 'user',
          text: 'Hello, can you help me with Flutter golden tests?',
          timestamp: DateTime(2026, 4, 25, 10, 0),
        ),
      ),
    );
    chatBloc.add(
      MessageReceived(
        ChatMessage(
          id: 'msg-2',
          sessionId: 'test-session',
          role: 'assistant',
          text: 'Absolutely! Golden tests let you capture and compare widget screenshots.',
          timestamp: DateTime(2026, 4, 25, 10, 1),
        ),
      ),
    );
    chatBloc.add(
      MessageReceived(
        ChatMessage(
          id: 'msg-3',
          sessionId: 'test-session',
          role: 'user',
          text: 'Great, let\'s set them up for the OpenClaw client.',
          timestamp: DateTime(2026, 4, 25, 10, 2),
        ),
      ),
    );
    chatBloc.add(
      MessageReceived(
        ChatMessage(
          id: 'msg-4',
          sessionId: 'test-session',
          role: 'assistant',
          text: 'Done. Run flutter test test/goldens/ to generate the snapshots.',
          timestamp: DateTime(2026, 4, 25, 10, 3),
        ),
      ),
    );

    await tester.pumpWidgetBuilder(
      BlocProvider.value(
        value: chatBloc,
        child: const ChatScreen(sessionId: 'test-session'),
      ),
      wrapper: materialAppWrapper(
        theme: AppTheme.dark,
      ),
      surfaceSize: Device.phone.size,
    );

    await tester.pumpAndSettle();

    await screenMatchesGolden(tester, 'chat_screen');
  });
}
