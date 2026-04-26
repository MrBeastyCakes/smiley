import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openclaw_client/src/presentation/widgets/aurum_text_field.dart';

void main() {
  group('AurumTextField', () {
    Widget buildSubject({
      TextEditingController? controller,
      String? hint,
      bool obscureText = false,
      bool autofocus = false,
      ValueChanged<String>? onChanged,
    }) {
      return MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: AurumTextField(
            controller: controller,
            hint: hint,
            obscureText: obscureText,
            autofocus: autofocus,
            onChanged: onChanged,
          ),
        ),
      );
    }

    testWidgets('renders hint text', (tester) async {
      await tester.pumpWidget(
        buildSubject(hint: 'Enter your name'),
      );

      expect(find.text('Enter your name'), findsOneWidget);
    });

    testWidgets('focus state applies gold border', (tester) async {
      await tester.pumpWidget(
        buildSubject(hint: 'Focus me'),
      );

      await tester.tap(find.byType(AurumTextField));
      await tester.pump();

      final textField = tester.widget<TextField>(find.byType(TextField));
      final focusedBorder = textField.decoration!.focusedBorder! as OutlineInputBorder;
      expect(focusedBorder.borderSide.color, const Color(0xFFD6B46A));
    });

    testWidgets('obscureText hides input', (tester) async {
      final controller = TextEditingController(text: 'secret');

      await tester.pumpWidget(
        buildSubject(
          controller: controller,
          obscureText: true,
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.obscureText, isTrue);
    });

    testWidgets('onChanged fires when text changes', (tester) async {
      var latest = '';

      await tester.pumpWidget(
        buildSubject(
          onChanged: (v) => latest = v,
        ),
      );

      await tester.enterText(find.byType(AurumTextField), 'hello');
      await tester.pump();

      expect(latest, equals('hello'));
    });
  });
}
