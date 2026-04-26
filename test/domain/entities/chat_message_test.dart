import 'package:flutter_test/flutter_test.dart';
import 'package:openclaw_client/src/domain/entities/chat_message.dart';

void main() {
  group('ChatMessage', () {
    final msg = ChatMessage(id: 'm1', sessionId: 's1', role: 'assistant', text: 'Hello', timestamp: DateTime(2026, 4, 25));

    test('properties', () {
      expect(msg.id, 'm1');
      expect(msg.role, 'assistant');
      expect(msg.text, 'Hello');
      expect(msg.isUser, false);
      expect(msg.isAssistant, true);
      expect(msg.isStreaming, false);
    });

    test('isStreaming true when status streaming', () {
      final streaming = msg.copyWith(status: MessageStatus.streaming);
      expect(streaming.isStreaming, true);
    });

    test('hasFailed true when status failed', () {
      final failed = msg.copyWith(status: MessageStatus.failed);
      expect(failed.hasFailed, true);
    });

    test('copyWith', () {
      final updated = msg.copyWith(text: 'Updated');
      expect(updated.text, 'Updated');
      expect(updated.id, msg.id);
    });

    test('equality', () {
      final m2 = ChatMessage(id: 'm1', sessionId: 's1', role: 'assistant', text: 'Hello', timestamp: DateTime(2026, 4, 25));
      expect(msg, m2);
    });
  });

  group('ThinkingBlock', () {
    const block = ThinkingBlock(content: 'Thinking...');

    test('properties', () {
      expect(block.content, 'Thinking...');
      expect(block.isExpanded, false);
    });

    test('copyWith', () {
      final expanded = block.copyWith(isExpanded: true);
      expect(expanded.isExpanded, true);
      expect(expanded.content, block.content);
    });
  });

  group('ActionCard', () {
    const card = ActionCard(id: 'ac1', title: 'Run git commit', actionType: 'intent_preview', buttons: [ActionButton(id: 'b1', label: 'Proceed', action: 'proceed', isPrimary: true)]);

    test('properties', () {
      expect(card.title, 'Run git commit');
      expect(card.buttons.length, 1);
      expect(card.buttons.first.isPrimary, true);
    });
  });
}
