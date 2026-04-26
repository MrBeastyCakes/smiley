import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/design_tokens.dart';
import '../blocs/connection/connection_bloc.dart' as conn;

/// A persistent banner that appears at the top of the screen when the
/// connection is lost, reconnecting, or offline.
///
/// Shows:
///   - [ConnectionReconnecting]: yellow "Reconnecting…" banner with attempt count
///   - [ConnectionOffline]: red "Offline" banner with a retry button
///   - [ConnectionConnected]: hidden
class ConnectionStatusBanner extends StatelessWidget {
  const ConnectionStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTokens.forBrightness(Theme.of(context).brightness);

    return BlocBuilder<conn.ConnectionBloc, conn.ConnectionState>(
      builder: (context, state) {
        if (state is conn.ConnectionReconnecting) {
          return _Banner(
            color: tokens.statusWarning,
            icon: Icons.sync,
            text: 'Reconnecting${state.retryCount > 0 ? ' (attempt ${state.retryCount})' : ''}…',
            tokens: tokens,
          );
        }
        if (state is conn.ConnectionOffline) {
          return _Banner(
            color: tokens.statusError,
            icon: Icons.cloud_off,
            text: 'Offline. Messages are saved locally.',
            tokens: tokens,
            action: TextButton(
              onPressed: () {
                context.read<conn.ConnectionBloc>().add(const conn.RetryNowRequested());
              },
              child: Text(
                'RETRY',
                style: tokens.textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _Banner extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String text;
  final DesignTokens tokens;
  final Widget? action;

  const _Banner({
    required this.color,
    required this.icon,
    required this.text,
    required this.tokens,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.15),
      child: SafeArea(
        bottom: false,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: tokens.space4,
            vertical: tokens.space3,
          ),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: color.withValues(alpha: 0.3)),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: color),
              SizedBox(width: tokens.space3),
              Expanded(
                child: Text(
                  text,
                  style: tokens.textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (action != null) action!,
            ],
          ),
        ),
      ),
    );
  }
}
