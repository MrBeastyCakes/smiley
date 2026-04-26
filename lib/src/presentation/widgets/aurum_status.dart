import 'package:flutter/material.dart';

import '../../core/theme/design_tokens.dart';
import '../widgets/widgets.dart';

/// Full-screen error widget with retry action.
class AurumErrorView extends StatelessWidget {
  final String title;
  final String? message;
  final VoidCallback? onRetry;
  final IconData icon;

  const AurumErrorView({
    super.key,
    this.title = 'Something went wrong',
    this.message,
    this.onRetry,
    this.icon = Icons.error_outline,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTokens.forBrightness(Theme.of(context).brightness);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(tokens.space5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: tokens.statusError),
            SizedBox(height: tokens.space4),
            Text(title, style: tokens.textTheme.titleLarge),
            if (message != null) ...[
              SizedBox(height: tokens.space2),
              Text(
                message!,
                style: tokens.textTheme.bodyMedium?.copyWith(color: tokens.textMuted),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              SizedBox(height: tokens.space5),
              AurumButton(
                label: 'Retry',
                variant: AurumButtonVariant.secondary,
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Inline error banner for snackbar-style display.
class AurumErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onDismiss;

  const AurumErrorBanner({super.key, required this.message, this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTokens.forBrightness(Theme.of(context).brightness);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.space4,
        vertical: tokens.space3,
      ),
      decoration: BoxDecoration(
        color: tokens.statusError.withValues(alpha: 0.1),
        border: Border.all(
          color: tokens.statusError.withValues(alpha: 0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(tokens.radiusMd),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: tokens.statusError, size: 18),
          SizedBox(width: tokens.space3),
          Expanded(
            child: Text(
              message,
              style: tokens.textTheme.bodySmall?.copyWith(color: tokens.statusError),
            ),
          ),
          if (onDismiss != null)
            IconButton(
              icon: Icon(Icons.close, size: 18, color: tokens.textMuted),
              onPressed: onDismiss,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}

/// Empty state widget for lists with no data.
class AurumEmptyState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionLabel;

  const AurumEmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.inbox_outlined,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTokens.forBrightness(Theme.of(context).brightness);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(tokens.space5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: tokens.textMuted),
            SizedBox(height: tokens.space4),
            Text(title, style: tokens.textTheme.titleLarge),
            if (subtitle != null) ...[
              SizedBox(height: tokens.space2),
              Text(
                subtitle!,
                style: tokens.textTheme.bodyMedium?.copyWith(color: tokens.textMuted),
                textAlign: TextAlign.center,
              ),
            ],
            if (onAction != null && actionLabel != null) ...[
              SizedBox(height: tokens.space5),
              AurumButton(
                label: actionLabel!,
                variant: AurumButtonVariant.primary,
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
