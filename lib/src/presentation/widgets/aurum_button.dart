import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart';

/// Aurum-styled button with three variants.
///
/// - [AurumButtonVariant.primary] — gold accent background.
/// - [AurumButtonVariant.secondary] — ghost surface.
/// - [AurumButtonVariant.danger] — error surface.
///
/// Compact buttons are pill-shaped; full-width buttons use the
/// standard [tokens.radiusLg] rounding.
class AurumButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;
  final AurumButtonVariant variant;
  final bool isLoading;
  final bool isDisabled;
  final bool fullWidth;

  const AurumButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.variant = AurumButtonVariant.primary,
    this.isLoading = false,
    this.isDisabled = false,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTokens.forBrightness(Theme.of(context).brightness);

    final Color background;
    final Color foreground;
    final Color? borderColor;
    final double borderWidth;

    switch (variant) {
      case AurumButtonVariant.primary:
        background = tokens.accentGold;
        foreground = tokens.textInverse;
        borderColor = null;
        borderWidth = 0;
      case AurumButtonVariant.secondary:
        background = tokens.ghost.background;
        foreground = tokens.textPrimary;
        borderColor = tokens.ghost.borderColor;
        borderWidth = tokens.ghost.borderWidth ?? 1;
      case AurumButtonVariant.danger:
        background = tokens.statusError.withValues(alpha: 0.15);
        foreground = tokens.statusError;
        borderColor = tokens.statusError.withValues(alpha: 0.3);
        borderWidth = 1;
    }

    final effectiveRadius = fullWidth ? tokens.radiusLg : tokens.radiusPill;
    final effectivePadding = EdgeInsets.symmetric(
      horizontal: tokens.space5,
      vertical: tokens.space3,
    );

    Widget child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(foreground),
            ),
          ),
          SizedBox(width: tokens.space2),
        ],
        if (icon != null && !isLoading) ...[
          Icon(icon, size: 16, color: foreground),
          SizedBox(width: tokens.space2),
        ],
        Text(
          label,
          style: tokens.textTheme.labelLarge?.copyWith(
            color: foreground,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );

    if (fullWidth) {
      child = SizedBox(width: double.infinity, child: child);
    }

    return GestureDetector(
      onTap: (isDisabled || isLoading) ? null : onPressed,
      child: Opacity(
        opacity: (isDisabled || isLoading) ? 0.5 : 1.0,
        child: Container(
          padding: effectivePadding,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(effectiveRadius),
            border: borderColor != null
                ? Border.all(color: borderColor, width: borderWidth)
                : null,
            boxShadow: variant == AurumButtonVariant.primary
                ? [
                    BoxShadow(
                      color: tokens.accentGold.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: child,
        ),
      ),
    );
  }
}

enum AurumButtonVariant { primary, secondary, danger }
