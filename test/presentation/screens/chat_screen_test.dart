import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:openclaw_client/src/presentation/blocs/chat/chat_bloc.dart';
import 'package:openclaw_client/src/presentation/blocs/connection/connection_bloc.dart' as conn;
import 'package:openclaw_client/src/presentation/screens/chat_screen.dart';
import 'package:openclaw_client/src/services/voice_service.dart';

import '../../helpers/test_helpers.dart' as helpers;

class _MockConnectionBloc extends MockBloc<conn.ConnectionEvent, conn.ConnectionState>
    implements conn.ConnectionBloc {}

class _FakeVoiceService extends VoiceService {
  final StreamController<VoiceTranscription> _controller =
      StreamController<VoiceTranscription>.broadcast();

  bool initializeResult = true;
  bool startResult = true;
  int initializeCallCount = 0;
  int startCallCount = 0;
  int stopCallCount = 0;

  _FakeVoiceService() : super(transcriptionController: StreamController<VoiceTranscription>.broadcast());

  @override
  Stream<VoiceTranscription> get transcriptionStream => _controller.stream;

  @override
  Future<bool> initialize() async {
    initializeCallCount += 1;
    return initializeResult;
  }

  @override
  Future<bool> startListening({String localeId = 'en_US'}) async {
    startCallCount += 1;
    return startResult;
  }

  @override
  Future<void> stopListening() async {
    stopCallCount += 1;
  }

  void emitTranscript(String text, {required bool isFinal}) {
    _controller.add(VoiceTranscription(text: text, isFinal: isFinal));
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }
}

void main() {
  late _MockConnectionBloc connectionBloc;

  setUp(() {
    connectionBloc = _MockConnectionBloc();
    when(() => connectionBloc.state).thenReturn(const conn.ConnectionInitial());
    whenListen(
      connectionBloc,
      const Stream<conn.ConnectionState>.empty(),
      initialState: const conn.ConnectionInitial(),
    );
  });

  Widget _buildScreen({required _FakeVoiceService voiceService}) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => ChatBloc(repository: helpers.NoOpMessageRepository()),
        ),
        BlocProvider<conn.ConnectionBloc>.value(value: connectionBloc),
      ],
      child: MaterialApp(
        home: ChatScreen(sessionId: 's1', voiceService: voiceService),
      ),
    );
  }

  group('ChatScreen voice composer', () {
    testWidgets('start recording when mic tapped with empty text', (tester) async {
      final voiceService = _FakeVoiceService();
      addTearDown(voiceService.dispose);

      await tester.pumpWidget(_buildScreen(voiceService: voiceService));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.mic));
      await tester.pump();

      expect(voiceService.initializeCallCount, 1);
      expect(voiceService.startCallCount, 1);
      expect(find.byIcon(Icons.stop_circle_outlined), findsOneWidget);
      expect(find.text('Listening...'), findsOneWidget);
    });

    testWidgets('partial transcript appears in text field', (tester) async {
      final voiceService = _FakeVoiceService();
      addTearDown(voiceService.dispose);

      await tester.pumpWidget(_buildScreen(voiceService: voiceService));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.mic));
      await tester.pump();

      voiceService.emitTranscript('hello partial', isFinal: false);
      await tester.pump();

      expect(find.text('hello partial'), findsOneWidget);
      expect(find.byIcon(Icons.send), findsOneWidget);
    });

    testWidgets('stop recording sends final transcript', (tester) async {
      final voiceService = _FakeVoiceService();
      addTearDown(voiceService.dispose);

      await tester.pumpWidget(_buildScreen(voiceService: voiceService));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.mic));
      await tester.pump();

      voiceService.emitTranscript('draft text', isFinal: false);
      voiceService.emitTranscript('final text', isFinal: true);
      await tester.pump();

      await tester.tap(find.byIcon(Icons.stop_circle_outlined));
      await tester.pump();
      await tester.pump();

      expect(voiceService.stopCallCount, 1);
      expect(find.text('final text'), findsWidgets);
    });

    testWidgets('permission denied path shows error and stays idle', (tester) async {
      final voiceService = _FakeVoiceService()..initializeResult = false;
      addTearDown(voiceService.dispose);

      await tester.pumpWidget(_buildScreen(voiceService: voiceService));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.mic));
      await tester.pump();

      expect(voiceService.startCallCount, 0);
      expect(find.byIcon(Icons.mic), findsOneWidget);
      expect(find.text('Microphone permission is required to record.'), findsOneWidget);
    });

    testWidgets('cancel path does not send when only partial transcript exists',
        (tester) async {
      final voiceService = _FakeVoiceService();
      addTearDown(voiceService.dispose);

      await tester.pumpWidget(_buildScreen(voiceService: voiceService));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.mic));
      await tester.pump();

      voiceService.emitTranscript('only partial', isFinal: false);
      await tester.pump();

      await tester.tap(find.byIcon(Icons.stop_circle_outlined));
      await tester.pump();
      await tester.pump();

      expect(voiceService.stopCallCount, 1);
      expect(find.text('only partial'), findsOneWidget);
    });
  });
}
