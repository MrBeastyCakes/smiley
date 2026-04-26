import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart';

/// Aurum-styled badge for status labels.
///
/// Variants:
/// - [AurumBadgeVariant.success]
/// - [AurumBadgeVariant.warning]
/// - [AurumBadgeVariant.error]
/// - [AurumBadgeVariant.info]
/// - [AurumBadgeVariant.neutral]
class AurumBadge extends StatelessWidget {
  final String label;
  final AurumBadgeVariant variant;

  const AurumBadge({
    super.key,
    required this.label,
    this.variant = AurumBadgeVariant.neutral,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTokens.forBrightness(Theme.of(context).brightness);

    final Color background;
    final Color foreground;

    switch (variant) {
      case AurumBadgeVariant.success:
        background = tokens.statusSuccess.withValues(alpha: 0.15);
        foreground = tokens.statusSuccess;
      case AurumBadgeVariant.warning:
        background = tokens.statusWarning.withValues(alpha: 0.15);
        foreground = tokens.statusWarning;
      case AurumBadgeVariant.error:
        background = tokens.statusError.withValues(alpha: 0.15);
        foreground = tokens.statusError;
      case AurumBadgeVariant.info:
        background = tokens.statusInfo.withValues(alpha: 0.15);
        foreground = tokens.statusInfo;
      case AurumBadgeVariant.neutral:
        background = tokens.textMuted.withValues(alpha: 0.15);
        foreground = tokens.textSecondary;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.space3,
        vertical: tokens.space1,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(tokens.radiusPill),
      ),
      child: Text(
        label,
        style: tokens.textTheme.labelMedium?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

enum AurumBadgeVariant {
  success,
  warning,
  error,
  info,
  neutral,
}
