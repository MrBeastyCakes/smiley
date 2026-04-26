import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openclaw_client/src/presentation/widgets/aurum_card.dart';
import 'package:openclaw_client/src/core/theme/design_tokens.dart';

void main() {
  group('AurumCard', () {
    const cardKey = Key('aurum_card');

    Widget buildSubject({
      Widget? child,
      SurfaceMaterial? material,
      VoidCallback? onTap,
      double? borderRadius,
    }) {
      return MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: AurumCard(
            key: cardKey,
            material: material,
            onTap: onTap,
            borderRadius: borderRadius,
            child: child,
          ),
        ),
      );
    }

    testWidgets('renders child', (tester) async {
      await tester.pumpWidget(
        buildSubject(child: const Text('Hello Aurum')),
      );

      expect(find.text('Hello Aurum'), findsOneWidget);
    });

    testWidgets('glass material renders by default', (tester) async {
      await tester.pumpWidget(
        buildSubject(),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byKey(cardKey),
          matching: find.byType(Container),
        ).first,
      );

      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color, DesignTokens.forBrightness(Brightness.dark).glass.background);
    });

    testWidgets('onTap is called when tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        buildSubject(
          onTap: () => tapped = true,
          child: const SizedBox(width: 200, height: 200),
        ),
      );

      await tester.tap(find.byKey(cardKey));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('custom borderRadius is applied', (tester) async {
      await tester.pumpWidget(
        buildSubject(
          borderRadius: 12,
          child: const SizedBox(),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byKey(cardKey),
          matching: find.byType(Container),
        ).first,
      );

      final decoration = container.decoration! as BoxDecoration;
      expect(
        (decoration.borderRadius! as BorderRadius).topLeft.x,
        equals(12),
      );
    });

    testWidgets('custom material overrides default glass', (tester) async {
      await tester.pumpWidget(
        buildSubject(
          material: SurfaceMaterial.satin(isDark: true),
          child: const SizedBox(),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byKey(cardKey),
          matching: find.byType(Container),
        ).first,
      );

      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color, DesignTokens.forBrightness(Brightness.dark).satin.background);
    });
  });
}
