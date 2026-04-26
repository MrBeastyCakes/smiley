import 'package:flutter_test/flutter_test.dart';
import 'package:openclaw_client/src/app.dart';
import 'package:openclaw_client/src/core/di/service_locator.dart';

void main() {
  setUpAll(() {
    ServiceLocator.init();
  });

  testWidgets('App launches with OpenClaw title', (tester) async {
    await tester.pumpWidget(const OpenClawApp());
    expect(find.text('OpenClaw'), findsOneWidget);
  });
}
