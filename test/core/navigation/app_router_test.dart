import 'package:flutter_test/flutter_test.dart';
import 'package:openclaw_client/src/app.dart';

void main() {
  group('AppRoute constants', () {
    test('connect route is root', () {
      expect(AppRoute.connect, '/');
    });

    test('home route is /home', () {
      expect(AppRoute.home, '/home');
    });

    test('chat route has sessionId parameter', () {
      expect(AppRoute.chat, '/chat/:sessionId');
    });

    test('agent route has agentId parameter', () {
      expect(AppRoute.agent, '/agent/:agentId');
    });
  });
}
