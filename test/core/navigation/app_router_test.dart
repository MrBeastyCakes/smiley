import 'package:flutter_test/flutter_test.dart';
import 'package:openclaw_client/src/core/navigation/app_router.dart';

void main() {
  group('Routes constants', () {
    test('connect route is root', () {
      expect(Routes.connect, '/');
    });

    test('home route is /home', () {
      expect(Routes.home, '/home');
    });

    test('chat route has sessionId parameter', () {
      expect(Routes.chat, '/chat/:sessionId');
    });

    test('agent route has agentId parameter', () {
      expect(Routes.agent, '/agent/:agentId');
    });
  });
}
