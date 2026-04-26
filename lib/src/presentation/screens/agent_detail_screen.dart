import 'package:flutter/material.dart';

import '../../core/theme/design_tokens.dart';
import '../../domain/entities/agent.dart';

/// Agent detail: avatar, name, description, capabilities, autonomy selector, active toggle.
class AgentDetailScreen extends StatefulWidget {
  final Agent agent;
  const AgentDetailScreen({super.key, required this.agent});

  @override
  State<AgentDetailScreen> createState() => _AgentDetailScreenState();
}

class _AgentDetailScreenState extends State<AgentDetailScreen> {
  late AutonomyLevel _autonomy;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _autonomy = widget.agent.defaultAutonomy;
    _isActive = widget.agent.isActive;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTokens.forBrightness(Brightness.dark);
    final agent = widget.agent;

    return Scaffold(
      backgroundColor: tokens.bgDeep,
      body: CustomScrollView(
        slivers: [
          // ── App bar with avatar hero feel ─────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: tokens.bgDeep,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: tokens.space6),
                      _Avatar(agent: agent, size: 80, tokens: tokens),
                      SizedBox(height: tokens.space3),
                      Text(agent.name, style: tokens.textTheme.headlineMedium),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // ── Description ───────────────────────────────
          if (agent.description != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: tokens.space5),
                child: Text(agent.description!, style: tokens.textTheme.bodyMedium),
              ),
            ),
          SliverToBoxAdapter(child: SizedBox(height: tokens.space5)),
          // ── Capabilities ──────────────────────────────
          SliverToBoxAdapter(
            child: _SectionHeader(title: 'Capabilities', tokens: tokens),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: tokens.space5),
              child: Wrap(
                spacing: tokens.space2,
                runSpacing: tokens.space2,
                children: agent.capabilities.map((cap) {
                  return Chip(
                    label: Text(cap, style: tokens.textTheme.labelMedium),
                  );
                }).toList(),
              ),
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: tokens.space5)),
          // ── Autonomy selector ─────────────────────────
          SliverToBoxAdapter(
            child: _SectionHeader(title: 'Autonomy', tokens: tokens),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: tokens.space4),
              child: Card(
                child: Column(
                  children: AutonomyLevel.values.map((level) {
                    final selected = _autonomy == level;
                    return RadioListTile<AutonomyLevel>(
                      title: Text(level.label, style: tokens.textTheme.bodyMedium),
                      subtitle: Text(
                        level.description,
                        style: tokens.textTheme.bodySmall,
                      ),
                      value: level,
                      groupValue: _autonomy,
                      activeColor: tokens.accentGold,
                      onChanged: (v) => setState(() => _autonomy = v!),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: tokens.space5)),
          // ── Active toggle ─────────────────────────────
          SliverToBoxAdapter(
            child: _SectionHeader(title: 'Status', tokens: tokens),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: tokens.space4),
              child: Card(
                child: SwitchListTile(
                  title: Text(
                    _isActive ? 'Active' : 'Inactive',
                    style: tokens.textTheme.bodyMedium,
                  ),
                  subtitle: Text(
                    _isActive
                        ? 'Agent is online and responding.'
                        : 'Agent is paused and will not respond.',
                    style: tokens.textTheme.bodySmall,
                  ),
                  value: _isActive,
                  activeColor: tokens.accentGold,
                  onChanged: (v) => setState(() => _isActive = v),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: tokens.space8)),
        ],
      ),
    );
  }
}

// ── UI helpers ─────────────────────────────────────

class _Avatar extends StatelessWidget {
  final Agent agent;
  final double size;
  final DesignTokens tokens;
  const _Avatar({required this.agent, required this.size, required this.tokens});

  @override
  Widget build(BuildContext context) {
    final initials = agent.name
        .split(' ')
        .map((w) => w.isNotEmpty ? w[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: agent.isActive
            ? tokens.accentGold.withValues(alpha: 0.15)
            : tokens.textMuted.withValues(alpha: 0.15),
        border: Border.all(
          color: agent.isActive
              ? tokens.accentGold.withValues(alpha: 0.4)
              : tokens.textMuted.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: tokens.textTheme.headlineMedium?.copyWith(
            color: agent.isActive ? tokens.accentGold : tokens.textMuted,
            fontSize: size * 0.45,
          ),
        ),
      ),
    );
  }
}

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
