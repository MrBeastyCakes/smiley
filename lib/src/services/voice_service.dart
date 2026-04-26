import 'dart:async';

import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../core/errors/exceptions.dart';

/// VoiceService — speech-to-text for talking to agents.
///
/// Responsibilities:
/// - Initialize speech recognition
/// - Start/stop listening
/// - Stream of transcription results (partial + final)
/// - Handle errors (no speech, no permission, network unavailable)
/// - Check microphone permission before starting
class VoiceService {
  final SpeechToText _speech;
  final StreamController<VoiceTranscription> _transcriptionController;

  bool _initialized = false;

  VoiceService({
    SpeechToText? speechToText,
    StreamController<VoiceTranscription>? transcriptionController,
  })  : _speech = speechToText ?? SpeechToText(),
        _transcriptionController =
            transcriptionController ?? StreamController<VoiceTranscription>.broadcast();

  /// Stream of transcription results (partial and final).
  Stream<VoiceTranscription> get transcriptionStream => _transcriptionController.stream;

  /// Whether the service is currently listening.
  bool get isListening => _speech.isListening;

  /// Whether speech recognition is available on this device.
  bool get isAvailable => _speech.isAvailable;

  /// Initializes speech recognition. Returns true if available.
  Future<bool> initialize() async {
    try {
      final available = await _speech.initialize(
        onError: _onError,
        onStatus: _onStatus,
      );
      _initialized = available;
      return available;
    } catch (e) {
      throw VoiceException(
        'Failed to initialize speech recognition: $e',
        code: 'INIT_FAILED',
      );
    }
  }

  /// Starts listening for speech and emits transcriptions to [transcriptionStream].
  /// Throws [VoiceException] if not initialized or already listening.
  Future<bool> startListening({String localeId = 'en_US'}) async {
    if (!_initialized) {
      throw const VoiceException(
        'VoiceService not initialized. Call initialize() first.',
        code: 'NOT_INITIALIZED',
      );
    }
    if (_speech.isListening) {
      throw const VoiceException(
        'Already listening. Call stopListening() before starting again.',
        code: 'ALREADY_LISTENING',
      );
    }
    try {
      return await _speech.listen(
        onResult: _onResult,
        localeId: localeId,
        cancelOnError: false,
        partialResults: true,
      );
    } catch (e) {
      throw VoiceException(
        'Failed to start listening: $e',
        code: 'LISTEN_FAILED',
      );
    }
  }

  /// Stops listening.
  Future<void> stopListening() async {
    if (!_speech.isListening) return;
    try {
      await _speech.stop();
    } catch (e) {
      throw VoiceException(
        'Failed to stop listening: $e',
        code: 'STOP_FAILED',
      );
    }
  }

  /// Disposes internal resources.
  void dispose() {
    _transcriptionController.close();
  }

  void _onResult(SpeechRecognitionResult result) {
    _transcriptionController.add(
      VoiceTranscription(
        text: result.recognizedWords,
        isFinal: result.finalResult,
      ),
    );
  }

  void _onError(SpeechRecognitionError error) {
    final code = error.errorMsg;
    switch (code) {
      case 'error_permission':
        _transcriptionController.addError(
          const VoiceException(
            'Microphone permission denied.',
            code: 'PERMISSION_DENIED',
          ),
        );
        return;
      case 'error_no_match':
        _transcriptionController.addError(
          const VoiceException(
            'No speech detected.',
            code: 'NO_SPEECH',
          ),
        );
        return;
      case 'error_network':
      case 'error_network_timeout':
        _transcriptionController.addError(
          const VoiceException(
            'Network error during speech recognition.',
            code: 'NETWORK_ERROR',
          ),
        );
        return;
      default:
        _transcriptionController.addError(
          VoiceException(
            'Speech recognition error: ${error.errorMsg}',
            code: error.errorMsg,
          ),
        );
        return;
    }
  }

  void _onStatus(String status) {
    // Status changes are handled via isListening / isAvailable getters.
    // Could emit a status stream in the future if needed.
  }
}

class VoiceTranscription {
  final String text;
  final bool isFinal;

  const VoiceTranscription({
    required this.text,
    required this.isFinal,
  });
}
