import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openclaw_client/src/presentation/blocs/chat/chat_bloc.dart';
import 'package:openclaw_client/src/presentation/screens/chat_screen.dart';

import '../../helpers/test_helpers.dart' as helpers;

void main() {
  group('ChatScreen', () {
    testWidgets('displays chat title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(
            create: (_) => ChatBloc(repository: helpers.NoOpMessageRepository()),
            child: const ChatScreen(sessionId: 's1'),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Chat'), findsOneWidget);
    });

    testWidgets('has message input', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(
            create: (_) => ChatBloc(repository: helpers.NoOpMessageRepository()),
            child: const ChatScreen(sessionId: 's1'),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(TextField), findsOneWidget);
      // When empty, shows mic icon; when text entered, shows send icon
      expect(find.byIcon(Icons.mic), findsOneWidget);
    });

    testWidgets('shows send icon when text is entered', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(
            create: (_) => ChatBloc(repository: helpers.NoOpMessageRepository()),
            child: const ChatScreen(sessionId: 's1'),
          ),
        ),
      );
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'Hello');
      await tester.pump();
      expect(find.byIcon(Icons.send), findsOneWidget);
    });
  });
}
