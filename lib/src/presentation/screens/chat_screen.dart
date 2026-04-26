import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/di/service_locator.dart';
import '../../core/theme/design_tokens.dart';
import '../../domain/entities/chat_message.dart';
import '../../services/voice_service.dart';
import '../blocs/chat/chat_bloc.dart';

class ChatScreen extends StatefulWidget {
  final String sessionId;
  const ChatScreen({super.key, required this.sessionId});

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
    );
  }
}

class _Composer extends StatefulWidget {
  final TextEditingController controller;
  final String sessionId;
  final VoidCallback onSend;
  final DesignTokens tokens;

  const _Composer({
    required this.controller,
    required this.sessionId,
    required this.onSend,
    required this.tokens,
  });

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  bool _isRecording = false;
  String? _transcription;

  @override
  void initState() {
    super.initState();
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

  void _startRecording() {
    setState(() => _isRecording = true);
    // TODO: Wire to VoiceService for real transcription
  }

  void _stopRecording() {
    setState(() => _isRecording = false);
    if (_transcription != null && _transcription!.isNotEmpty) {
      context.read<ChatBloc>().add(
        MessageSent(sessionId: widget.sessionId, text: _transcription!),
      );
      _transcription = null;
    }
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
          if (_isRecording)
            _RecordingIndicator(tokens: tokens)
          else
            IconButton(
              onPressed: hasText ? widget.onSend : null,
              icon: Icon(
                hasText ? Icons.send : Icons.mic,
                color: hasText ? tokens.accentGold : tokens.textMuted,
              ),
            ),
        ],
      ),
    );
  }
}

class _RecordingIndicator extends StatefulWidget {
  final DesignTokens tokens;
  const _RecordingIndicator({required this.tokens});

  @override
  State<_RecordingIndicator> createState() => _RecordingIndicatorState();
}

class _RecordingIndicatorState extends State<_RecordingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.tokens.statusError.withValues(
              alpha: 0.3 + (_controller.value * 0.4),
            ),
          ),
          child: Center(
            child: Icon(
              Icons.mic,
              color: widget.tokens.statusError,
              size: 20,
            ),
          ),
        );
      },
    );
  }
}
