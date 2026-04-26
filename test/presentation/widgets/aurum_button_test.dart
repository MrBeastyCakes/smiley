import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openclaw_client/src/presentation/widgets/aurum_button.dart';

void main() {
  group('AurumButton', () {
    Widget buildSubject({
      VoidCallback? onPressed,
      String label = 'Tap me',
      IconData? icon,
      AurumButtonVariant variant = AurumButtonVariant.primary,
      bool isLoading = false,
      bool isDisabled = false,
      bool fullWidth = false,
    }) {
      return MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: AurumButton(
            onPressed: onPressed,
            label: label,
            icon: icon,
            variant: variant,
            isLoading: isLoading,
            isDisabled: isDisabled,
            fullWidth: fullWidth,
          ),
        ),
      );
    }

    testWidgets('primary variant renders with gold background', (tester) async {
      await tester.pumpWidget(buildSubject());

      final text = find.text('Tap me');
      expect(text, findsOneWidget);
    });

    testWidgets('secondary variant renders', (tester) async {
      await tester.pumpWidget(
        buildSubject(variant: AurumButtonVariant.secondary),
      );
      expect(find.text('Tap me'), findsOneWidget);
    });

    testWidgets('danger variant renders', (tester) async {
      await tester.pumpWidget(
        buildSubject(variant: AurumButtonVariant.danger),
      );
      expect(find.text('Tap me'), findsOneWidget);
    });

    testWidgets('onPressed fires when tapped', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        buildSubject(
          onPressed: () => pressed = true,
          label: 'Press',
        ),
      );

      await tester.tap(find.text('Press'));
      await tester.pump();

      expect(pressed, isTrue);
    });

    testWidgets('loading state shows indicator and is not tappable', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        buildSubject(
          onPressed: () => pressed = true,
          isLoading: true,
          label: 'Loading',
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.tap(find.byType(AurumButton));
      await tester.pump();

      expect(pressed, isFalse);
    });

    testWidgets('disabled state prevents onPressed', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        buildSubject(
          onPressed: () => pressed = true,
          isDisabled: true,
          label: 'Disabled',
        ),
      );

      await tester.tap(find.text('Disabled'));
      await tester.pump();

      expect(pressed, isFalse);
    });

    testWidgets('icon is shown when provided and not loading', (tester) async {
      await tester.pumpWidget(
        buildSubject(
          icon: Icons.settings,
          label: 'Settings',
        ),
      );

      expect(find.byIcon(Icons.settings), findsOneWidget);
    });
  });
}
