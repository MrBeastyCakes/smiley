import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openclaw_client/src/presentation/widgets/aurum_skeleton.dart';

void main() {
  group('AurumSkeleton', () {
    testWidgets('renders shimmer container', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AurumSkeleton(width: 100, height: 20)),
        ),
      );

      final container = find.byType(Container);
      expect(container, findsOneWidget);
    });
  });

  group('AurumMessageSkeleton', () {
    testWidgets('renders aligned shimmer for user message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AurumMessageSkeleton(isUser: true)),
        ),
      );

      expect(find.byType(AurumSkeleton), findsOneWidget);
    });

    testWidgets('renders aligned shimmer for assistant message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AurumMessageSkeleton(isUser: false)),
        ),
      );

      expect(find.byType(AurumSkeleton), findsOneWidget);
    });
  });

  group('AurumSessionSkeleton', () {
    testWidgets('renders avatar + text skeletons', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AurumSessionSkeleton()),
        ),
      );

      expect(find.byType(AurumSkeleton), findsNWidgets(3));
    });
  });
}
