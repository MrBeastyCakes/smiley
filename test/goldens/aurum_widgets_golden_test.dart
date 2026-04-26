import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:openclaw_client/src/core/theme/app_theme.dart';
import 'package:openclaw_client/src/presentation/widgets/widgets.dart';

void main() {
  testGoldens('All 5 Aurum widgets render in a column', (tester) async {
    final builder = GoldenBuilder.column()
      ..addScenario(
        'AurumCard',
        AurumCard(
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Card content'),
          ),
        ),
      )
      ..addScenario(
        'AurumButton primary',
        const SizedBox(
          width: double.infinity,
          child: AurumButton(
            label: 'Primary',
            variant: AurumButtonVariant.primary,
            fullWidth: true,
          ),
        ),
      )
      ..addScenario(
        'AurumButton secondary',
        const SizedBox(
          width: double.infinity,
          child: AurumButton(
            label: 'Secondary',
            variant: AurumButtonVariant.secondary,
            fullWidth: true,
          ),
        ),
      )
      ..addScenario(
        'AurumTextField',
        const AurumTextField(
          hint: 'Enter text...',
        ),
      )
      ..addScenario(
        'AurumAvatar online',
        const AurumAvatar(
          initials: 'RO',
          size: AurumAvatarSize.md,
          isOnline: true,
        ),
      )
      ..addScenario(
        'AurumAvatar offline',
        const AurumAvatar(
          initials: 'TA',
          size: AurumAvatarSize.md,
          isOnline: false,
        ),
      )
      ..addScenario(
        'AurumBadge success',
        const AurumBadge(
          label: 'Active',
          variant: AurumBadgeVariant.success,
        ),
      )
      ..addScenario(
        'AurumBadge neutral',
        const AurumBadge(
          label: '42',
          variant: AurumBadgeVariant.neutral,
        ),
      );

    await tester.pumpWidgetBuilder(
      builder.build(),
      wrapper: materialAppWrapper(
        theme: AppTheme.dark,
      ),
      surfaceSize: Device.iphone11.size,
    );

    await screenMatchesGolden(tester, 'aurum_widgets');
  });
}
