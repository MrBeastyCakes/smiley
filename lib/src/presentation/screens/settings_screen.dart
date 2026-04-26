import 'package:flutter/material.dart';

import '../../core/theme/design_tokens.dart';
import '../../domain/entities/gateway_settings.dart';

/// Settings screen: gateway connection, theme toggle, clear data, version.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Read-only display values (secure storage not wired yet)
  final GatewaySettings _settings = const GatewaySettings(
    host: '127.0.0.1',
    port: 18789,
    token: 'oc_demo_token',
  );

  bool _isDark = true;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTokens.forBrightness(_isDark ? Brightness.dark : Brightness.light);

    return Scaffold(
      backgroundColor: tokens.bgDeep,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(tokens.space5),
                child: Text('Settings', style: tokens.textTheme.headlineLarge),
              ),
            ),
            // ── Gateway ───────────────────────────────────
            SliverToBoxAdapter(
              child: _SectionHeader(title: 'Gateway', tokens: tokens),
            ),
            SliverToBoxAdapter(
              child: _SettingsCard(
                tokens: tokens,
                children: [
                  _ReadOnlyField(label: 'Host', value: _settings.host, tokens: tokens),
                  Divider(height: 1, color: tokens.textMuted.withValues(alpha: 0.15)),
                  _ReadOnlyField(label: 'Port', value: '${_settings.port}', tokens: tokens),
                  Divider(height: 1, color: tokens.textMuted.withValues(alpha: 0.15)),
                  _ReadOnlyField(label: 'Token', value: '••••••••', tokens: tokens),
                ],
              ),
            ),
            // ── Appearance ──────────────────────────────
            SliverToBoxAdapter(
              child: _SectionHeader(title: 'Appearance', tokens: tokens),
            ),
            SliverToBoxAdapter(
              child: _SettingsCard(
                tokens: tokens,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: tokens.space4),
                    leading: Icon(
                      _isDark ? Icons.dark_mode : Icons.light_mode,
                      color: tokens.accentGold,
                    ),
                    title: Text('Theme', style: tokens.textTheme.bodyMedium),
                    trailing: Switch(
                      value: _isDark,
                      onChanged: (v) => setState(() => _isDark = v),
                    ),
                  ),
                ],
              ),
            ),
            // ── Data ────────────────────────────────────
            SliverToBoxAdapter(
              child: _SectionHeader(title: 'Data', tokens: tokens),
            ),
            SliverToBoxAdapter(
              child: _SettingsCard(
                tokens: tokens,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: tokens.space4),
                    leading: Icon(Icons.delete_outline, color: tokens.statusError),
                    title: Text(
                      'Clear all data',
                      style: tokens.textTheme.bodyMedium?.copyWith(color: tokens.statusError),
                    ),
                    trailing: Icon(Icons.chevron_right, color: tokens.textMuted),
                    onTap: _onClearData,
                  ),
                ],
              ),
            ),
            // ── About ─────────────────────────────────────
            SliverToBoxAdapter(
              child: _SectionHeader(title: 'About', tokens: tokens),
            ),
            SliverToBoxAdapter(
              child: _SettingsCard(
                tokens: tokens,
                children: [
                  _ReadOnlyField(label: 'Version', value: '0.1.0+1', tokens: tokens),
                  Divider(height: 1, color: tokens.textMuted.withValues(alpha: 0.15)),
                  _ReadOnlyField(label: 'Build', value: 'aurum-dark', tokens: tokens),
                ],
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: tokens.space6)),
          ],
        ),
      ),
    );
  }

  void _onClearData() {
    final tokens = DesignTokens.forBrightness(Brightness.dark);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: tokens.bgSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(tokens.radiusXl)),
        title: Text('Clear all data?', style: tokens.textTheme.titleLarge),
        content: Text(
          'This will remove all local sessions, messages, and settings. This cannot be undone.',
          style: tokens.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: tokens.textTheme.labelLarge),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              // TODO: wire to secure storage / local DB wipe
            },
            child: Text(
              'Clear',
              style: tokens.textTheme.labelLarge?.copyWith(color: tokens.statusError),
            ),
          ),
        ],
      ),
    );
  }
}

// ── UI helpers ─────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final DesignTokens tokens;
  const _SectionHeader({required this.title, required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(tokens.space5, tokens.space4, tokens.space5, tokens.space2),
      child: Text(
        title.toUpperCase(),
        style: tokens.textTheme.labelSmall?.copyWith(
          color: tokens.textMuted,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final DesignTokens tokens;
  final List<Widget> children;
  const _SettingsCard({required this.tokens, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: tokens.space4),
      child: Card(
        margin: EdgeInsets.zero,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;
  final DesignTokens tokens;
  const _ReadOnlyField({required this.label, required this.value, required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: tokens.space4, vertical: tokens.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: tokens.textTheme.labelMedium?.copyWith(color: tokens.textMuted)),
          SizedBox(height: tokens.space1),
          Text(value, style: tokens.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
