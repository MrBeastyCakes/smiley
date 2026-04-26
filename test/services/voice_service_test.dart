import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'package:openclaw_client/src/core/errors/exceptions.dart';
import 'package:openclaw_client/src/services/voice_service.dart';

class _FakeSpeechToText extends Fake implements SpeechToText {
  bool _available = false;
  bool _listening = false;
  SpeechResultListener? _resultListener;
  SpeechErrorListener? _errorListener;

  set available(bool value) => _available = value;

  @override
  bool get isAvailable => _available;

  @override
  bool get isListening => _listening;

  @override
  Future<bool> initialize({
    SpeechErrorListener? onError,
    SpeechStatusListener? onStatus,
    dynamic debugLogging = false,
    Duration finalTimeout = const Duration(milliseconds: 2000),
    List<dynamic>? options,
  }) async {
    _errorListener = onError;
    return _available;
  }

  @override
  Future<bool> listen({
    SpeechResultListener? onResult,
    Duration? listenFor,
    Duration? pauseFor,
    String? localeId,
    SpeechSoundLevelChange? onSoundLevelChange,
    dynamic cancelOnError = false,
    dynamic partialResults = true,
    dynamic onDevice = false,
    ListenMode listenMode = ListenMode.confirmation,
    dynamic sampleRate = 0,
    SpeechListenOptions? listenOptions,
  }) async {
    if (!_available) return false;
    _listening = true;
    _resultListener = onResult;
    return true;
  }

  @override
  Future<void> stop() async {
    _listening = false;
  }

  void emitResult(String words, {bool finalResult = true}) {
    _resultListener?.call(
      SpeechRecognitionResult(
        [
          SpeechRecognitionWords(words, [], 0.9),
        ],
        finalResult,
      ),
    );
  }

  void emitError(String msg) {
    _errorListener?.call(SpeechRecognitionError(msg, true));
  }
}

void main() {
  late _FakeSpeechToText fakeSpeech;
  late VoiceService voiceService;
  late StreamController<VoiceTranscription> controller;

  setUp(() {
    fakeSpeech = _FakeSpeechToText();
    fakeSpeech.available = true;
    controller = StreamController<VoiceTranscription>.broadcast();
    voiceService = VoiceService(
      speechToText: fakeSpeech,
      transcriptionController: controller,
    );
  });

  tearDown(() {
    voiceService.dispose();
  });

  group('initialize', () {
    test('returns true when speech is available', () async {
      fakeSpeech.available = true;
      final result = await voiceService.initialize();
      expect(result, isTrue);
      expect(voiceService.isAvailable, isTrue);
    });

    test('returns false when speech is not available', () async {
      fakeSpeech.available = false;
      final result = await voiceService.initialize();
      expect(result, isFalse);
      expect(voiceService.isAvailable, isFalse);
    });
  });

  group('startListening', () {
    test('throws VoiceException when not initialized', () async {
      expect(
        () => voiceService.startListening(),
        throwsA(isA<VoiceException>()),
      );
    });

    test('starts listening when initialized', () async {
      await voiceService.initialize();
      final result = await voiceService.startListening();
      expect(result, isTrue);
      expect(voiceService.isListening, isTrue);
    });
  });

  group('transcriptionStream', () {
    test('emits recognized words', () async {
      await voiceService.initialize();
      await voiceService.startListening();

      final emitted = <VoiceTranscription>[];
      final sub = voiceService.transcriptionStream.listen(emitted.add);

      fakeSpeech.emitResult('Hello world');
      await Future<void>.delayed(Duration.zero);

      expect(emitted.single.text, 'Hello world');
      expect(emitted.single.isFinal, isTrue);
      await sub.cancel();
    });

    test('emits partial and final results', () async {
      await voiceService.initialize();
      await voiceService.startListening();

      final emitted = <VoiceTranscription>[];
      final sub = voiceService.transcriptionStream.listen(emitted.add);

      fakeSpeech.emitResult('Hello', finalResult: false);
      fakeSpeech.emitResult('Hello there', finalResult: true);
      await Future<void>.delayed(Duration.zero);

      expect(emitted.map((e) => e.text), equals(['Hello', 'Hello there']));
      expect(emitted.map((e) => e.isFinal), equals([false, true]));
      await sub.cancel();
    });
  });

  group('stopListening', () {
    test('transitions isListening to false', () async {
      await voiceService.initialize();
      await voiceService.startListening();
      expect(voiceService.isListening, isTrue);

      await voiceService.stopListening();
      expect(voiceService.isListening, isFalse);
    });

    test('is safe to call when not listening', () async {
      await voiceService.initialize();
      expect(voiceService.isListening, isFalse);
      await voiceService.stopListening();
      expect(voiceService.isListening, isFalse);
    });
  });

  group('error handling', () {
    test('permission denied error is emitted as VoiceException', () async {
      await voiceService.initialize();
      await voiceService.startListening();

      VoiceException? captured;
      final sub = voiceService.transcriptionStream.listen(
        (_) {},
        onError: (Object e) => captured = e as VoiceException,
      );

      fakeSpeech.emitError('error_permission');
      await Future<void>.delayed(Duration.zero);

      expect(captured, isNotNull);
      expect(captured!.code, 'PERMISSION_DENIED');
      await sub.cancel();
    });

    test('no match error is emitted as VoiceException', () async {
      await voiceService.initialize();
      await voiceService.startListening();

      VoiceException? captured;
      final sub = voiceService.transcriptionStream.listen(
        (_) {},
        onError: (Object e) => captured = e as VoiceException,
      );

      fakeSpeech.emitError('error_no_match');
      await Future<void>.delayed(Duration.zero);

      expect(captured, isNotNull);
      expect(captured!.code, 'NO_SPEECH');
      await sub.cancel();
    });

    test('network error is emitted as VoiceException', () async {
      await voiceService.initialize();
      await voiceService.startListening();

      VoiceException? captured;
      final sub = voiceService.transcriptionStream.listen(
        (_) {},
        onError: (Object e) => captured = e as VoiceException,
      );

      fakeSpeech.emitError('error_network');
      await Future<void>.delayed(Duration.zero);

      expect(captured, isNotNull);
      expect(captured!.code, 'NETWORK_ERROR');
      await sub.cancel();
    });

    test('unknown error is emitted as VoiceException with raw code', () async {
      await voiceService.initialize();
      await voiceService.startListening();

      VoiceException? captured;
      final sub = voiceService.transcriptionStream.listen(
        (_) {},
        onError: (Object e) => captured = e as VoiceException,
      );

      fakeSpeech.emitError('error_unknown (42)');
      await Future<void>.delayed(Duration.zero);

      expect(captured, isNotNull);
      expect(captured!.code, 'error_unknown (42)');
      await sub.cancel();
    });
  });
}
