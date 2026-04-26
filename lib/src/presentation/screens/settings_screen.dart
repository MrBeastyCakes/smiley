import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/design_tokens.dart';
import '../../domain/entities/gateway_settings.dart';
import '../blocs/settings/settings_bloc.dart';

/// Settings screen: gateway connection, theme toggle, clear data, version.
///
/// Works both with and without a [SettingsBloc] provider — falls back to
/// static UI when none is available (e.g. widget tests or bare routes).
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDark = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        try {
          context.read<SettingsBloc>().add(const LoadSettings());
        } catch (_) {
          // No SettingsBloc available; show static UI.
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTokens.forBrightness(_isDark ? Brightness.dark : Brightness.light);

    // Attempt to locate a SettingsBloc; if absent render static content.
    final bloc = _tryReadBloc(context);

    return Scaffold(
      backgroundColor: tokens.bgDeep,
      body: SafeArea(
        child: bloc == null
            ? _buildStaticContent(context, tokens)
            : BlocConsumer<SettingsBloc, SettingsState>(
                bloc: bloc,
                listener: _handleStateChange,
                builder: (context, state) {
                  final settings = state is SettingsLoaded ? state.settings : null;
                  final version = state is SettingsLoaded ? state.version : AppConstants.appVersion;
                  final buildNumber = state is SettingsLoaded ? state.buildNumber : '1';
                  final isLoading = state is SettingsLoading;
                  return _buildSlivers(
                    context, tokens, settings, version, buildNumber, isLoading, bloc,
                  );
                },
              ),
      ),
    );
  }

  SettingsBloc? _tryReadBloc(BuildContext context) {
    try {
      return context.read<SettingsBloc>();
    } catch (_) {
      return null;
    }
  }

  void _handleStateChange(BuildContext context, SettingsState state) {
    if (state is SettingsCacheCleared) {
      _showSnack(context, 'Cache cleared successfully');
      try { context.read<SettingsBloc>().add(const LoadSettings()); } catch (_) {}
    } else if (state is SettingsDisconnected) {
      _showSnack(context, 'Disconnected successfully');
      try { context.read<SettingsBloc>().add(const LoadSettings()); } catch (_) {}
    } else if (state is SettingsError) {
      _showSnack(context, state.message);
    }
  }

  Widget _buildStaticContent(BuildContext context, DesignTokens tokens) {
    return _buildSlivers(context, tokens, null, AppConstants.appVersion, '1', false, null);
  }

  Widget _buildSlivers(
    BuildContext context,
    DesignTokens tokens,
    GatewaySettings? settings,
    String? version,
    String? buildNumber,
    bool isLoading,
    SettingsBloc? bloc,
  ) {
    return CustomScrollView(
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
              _ReadOnlyField(label: 'Host', value: settings?.host ?? '—', tokens: tokens),
              Divider(height: 1, color: tokens.textMuted.withValues(alpha: 0.15)),
              _ReadOnlyField(label: 'Port', value: settings != null ? '${settings.port}' : '—', tokens: tokens),
              Divider(height: 1, color: tokens.textMuted.withValues(alpha: 0.15)),
              _ReadOnlyField(label: 'Token', value: _maskToken(settings?.token), tokens: tokens),
            ],
          ),
        ),
        // ── Connection actions ─────────────────────────
        SliverToBoxAdapter(
          child: _SectionHeader(title: 'Connection', tokens: tokens),
        ),
        SliverToBoxAdapter(
          child: _SettingsCard(
            tokens: tokens,
            children: [
              ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: tokens.space4),
                leading: Icon(Icons.link_off, color: tokens.statusError),
                title: Text(
                  'Disconnect',
                  style: tokens.textTheme.bodyMedium?.copyWith(color: tokens.statusError),
                ),
                trailing: Icon(Icons.chevron_right, color: tokens.textMuted),
                onTap: isLoading || bloc == null ? null : () => _onDisconnect(context, bloc, tokens),
              ),
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
                onTap: isLoading || bloc == null ? null : () => _onClearData(context, bloc, tokens),
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
              _ReadOnlyField(label: 'Version', value: version ?? '—', tokens: tokens),
              Divider(height: 1, color: tokens.textMuted.withValues(alpha: 0.15)),
              _ReadOnlyField(label: 'Build', value: buildNumber ?? '—', tokens: tokens),
            ],
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: tokens.space6)),
      ],
    );
  }

  String _maskToken(String? token) {
    if (token == null || token.isEmpty) return '—';
    if (token.length <= 4) return '••••';
    return '••••${token.substring(token.length - 4)}';
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _onDisconnect(BuildContext context, SettingsBloc bloc, DesignTokens tokens) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: tokens.bgSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(tokens.radiusXl)),
        title: Text('Disconnect from gateway?', style: tokens.textTheme.titleLarge),
        content: Text(
          'This will clear your saved connection settings and disconnect from the gateway.',
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
              bloc.add(const Disconnect());
            },
            child: Text(
              'Disconnect',
              style: tokens.textTheme.labelLarge?.copyWith(color: tokens.statusError),
            ),
          ),
        ],
      ),
    );
  }

  void _onClearData(BuildContext context, SettingsBloc bloc, DesignTokens tokens) {
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
              bloc.add(const ClearCache());
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
