import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/di/service_locator.dart';
import '../../core/theme/design_tokens.dart';
import '../../domain/entities/chat_message.dart';
import '../../services/voice_service.dart';
import '../blocs/chat/chat_bloc.dart';
import '../blocs/connection/connection_bloc.dart' as conn;
import '../widgets/widgets.dart';

class ChatScreen extends StatefulWidget {
  final String sessionId;
  final VoiceService? voiceService;

  const ChatScreen({
    super.key,
    required this.sessionId,
    this.voiceService,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<ChatBloc>().add(const ChatStarted());
    context.read<ChatBloc>().add(LoadChatMessages(sessionId: widget.sessionId));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    context.read<ChatBloc>().add(MessageSent(sessionId: widget.sessionId, text: text));
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTokens.forBrightness(Brightness.dark);

    return Scaffold(
      backgroundColor: tokens.bgDeep,
      appBar: AppBar(
        title: Text('Chat', style: tokens.textTheme.titleLarge),
        backgroundColor: tokens.bgDeep,
        foregroundColor: tokens.textPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          const ConnectionStatusBanner(),
          Expanded(
            child: BlocBuilder<ChatBloc, ChatState>(
              builder: (context, state) {
                if (state is ChatInitial) return const Center(child: CircularProgressIndicator());
                if (state is ChatLoaded) {
                  return ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(tokens.space4),
                    itemCount: state.messages.length,
                    itemBuilder: (context, index) {
                      final msg = state.messages[index];
                      return _MessageBubble(message: msg, tokens: tokens);
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          _Composer(
            controller: _controller,
            sessionId: widget.sessionId,
            onSend: _send,
            tokens: tokens,
            voiceService: widget.voiceService,
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final DesignTokens tokens;
  const _MessageBubble({required this.message, required this.tokens});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.82),
        margin: EdgeInsets.symmetric(vertical: tokens.space2),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: tokens.space4, vertical: tokens.space3),
              decoration: BoxDecoration(
                color: isUser ? tokens.accentGold.withValues(alpha: 0.15) : tokens.bgElevated,
                borderRadius: BorderRadius.circular(tokens.radiusMd),
                border: Border.all(color: isUser ? tokens.accentGold.withValues(alpha: 0.3) : tokens.textMuted.withValues(alpha: 0.1)),
              ),
              child: Text(message.text, style: tokens.textTheme.bodyMedium?.copyWith(
                color: isUser ? tokens.accentGold : tokens.textPrimary,
              )),
            ),
            SizedBox(height: tokens.space1),
            _StatusIndicator(message: message, tokens: tokens),
          ],
        ),
      ),
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  final ChatMessage message;
  final DesignTokens tokens;
  const _StatusIndicator({required this.message, required this.tokens});

  @override
  Widget build(BuildContext context) {
    if (message.status == MessageStatus.pending) {
      return SizedBox(
        width: 12,
        height: 12,
        child: CircularProgressIndicator(
          strokeWidth: 1.5,
          color: tokens.textMuted,
        ),
      );
    }
    if (message.status == MessageStatus.failed) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 12, color: tokens.statusError),
          SizedBox(width: tokens.space1),
          GestureDetector(
            onTap: () {
              context.read<ChatBloc>().add(
                RetryPendingMessages(sessionId: message.sessionId),
              );
            },
            child: Text(
              'Tap to retry',
              style: tokens.textTheme.labelSmall?.copyWith(
                color: tokens.statusError,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }
}

class _Composer extends StatefulWidget {
  final TextEditingController controller;
  final String sessionId;
  final VoidCallback onSend;
  final DesignTokens tokens;
  final VoiceService? voiceService;

  const _Composer({
    required this.controller,
    required this.sessionId,
    required this.onSend,
    required this.tokens,
    this.voiceService,
  });

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  bool _isRecording = false;
  String? _transcription;
  String? _finalTranscription;
  StreamSubscription<VoiceTranscription>? _transcriptionSub;
  late final VoiceService _voiceService;

  @override
  void initState() {
    super.initState();
    _voiceService = widget.voiceService ?? ServiceLocator.get<VoiceService>();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(covariant _Composer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTextChanged);
      widget.controller.addListener(_onTextChanged);
    }
  }

  @override
  void dispose() {
    _transcriptionSub?.cancel();
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
  }

  void _toggleVoice() {
    if (_isRecording) {
      _stopRecording();
    } else {
      _startRecording();
    }
  }

  Future<void> _startRecording() async {
    _transcriptionSub?.cancel();
    final isAvailable = await _voiceService.initialize();
    if (!isAvailable) {
      _showVoiceUnavailableMessage('Microphone permission is required to record.');
      return;
    }

    _finalTranscription = null;
    _transcription = null;
    _transcriptionSub = _voiceService.transcriptionStream.listen(
      (event) {
        if (!mounted) return;
        setState(() {
          _transcription = event.text;
          if (event.isFinal && event.text.trim().isNotEmpty) {
            _finalTranscription = event.text.trim();
          }
        });
        widget.controller.value = TextEditingValue(
          text: event.text,
          selection: TextSelection.collapsed(offset: event.text.length),
        );
      },
      onError: (Object error) {
        if (!mounted) return;
        _showVoiceUnavailableMessage('Unable to transcribe voice right now.');
        setState(() => _isRecording = false);
      },
    );

    final started = await _voiceService.startListening();
    if (!started) {
      _showVoiceUnavailableMessage('Unable to start voice capture.');
      await _transcriptionSub?.cancel();
      _transcriptionSub = null;
      return;
    }
    if (!mounted) return;
    setState(() => _isRecording = true);
  }

  Future<void> _stopRecording() async {
    await _voiceService.stopListening();
    await _transcriptionSub?.cancel();
    _transcriptionSub = null;
    if (!mounted) return;
    setState(() => _isRecording = false);

    final finalText = _finalTranscription?.trim() ?? '';
    if (finalText.isNotEmpty) {
      context.read<ChatBloc>().add(
        MessageSent(sessionId: widget.sessionId, text: finalText),
      );
    }
    _transcription = null;
    _finalTranscription = null;
  }

  void _showVoiceUnavailableMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final tokens = widget.tokens;
    final hasText = widget.controller.text.isNotEmpty;

    return Container(
      color: tokens.bgSurface,
      padding: EdgeInsets.all(tokens.space4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: widget.controller,
              style: tokens.textTheme.bodyMedium?.copyWith(color: tokens.textPrimary),
              decoration: InputDecoration(
                hintText: _isRecording ? 'Listening...' : 'Message...',
                hintStyle: tokens.textTheme.bodyMedium?.copyWith(
                  color: _isRecording ? tokens.statusError : tokens.textMuted,
                ),
                filled: true,
                fillColor: tokens.bgElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(tokens.radiusPill),
                  borderSide: _isRecording
                    ? BorderSide(color: tokens.statusError.withValues(alpha: 0.5), width: 2)
                    : BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: tokens.space4, vertical: tokens.space3),
              ),
              onSubmitted: (_) => widget.onSend(),
            ),
          ),
          SizedBox(width: tokens.space3),
          IconButton(
            onPressed: _isRecording ? _toggleVoice : (hasText ? widget.onSend : _toggleVoice),
            icon: Icon(
              _isRecording ? Icons.stop_circle_outlined : (hasText ? Icons.send : Icons.mic),
              color: _isRecording
                  ? tokens.statusError
                  : (hasText ? tokens.accentGold : tokens.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
