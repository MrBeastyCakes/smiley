import 'package:flutter_test/flutter_test.dart';
import 'package:openclaw_client/src/domain/entities/session.dart';

void main() {
  group('Session', () {
    final session = Session(id: 's1', title: 'Test', createdAt: DateTime(2026, 4, 25), updatedAt: DateTime(2026, 4, 25), messageCount: 5);

    test('properties', () {
      expect(session.id, 's1');
      expect(session.title, 'Test');
      expect(session.messageCount, 5);
      expect(session.isPinned, false);
    });

    test('copyWith', () {
      final updated = session.copyWith(title: 'Updated', isPinned: true);
      expect(updated.title, 'Updated');
      expect(updated.isPinned, true);
      expect(updated.id, session.id);
    });

    test('equality', () {
      final s2 = Session(id: 's1', title: 'Test', createdAt: DateTime(2026, 4, 25), updatedAt: DateTime(2026, 4, 25), messageCount: 5);
      expect(session, s2);
    });
  });
}
