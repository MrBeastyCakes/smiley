import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/design_tokens.dart';
import '../../domain/entities/agent.dart';
import '../../domain/entities/session.dart';
import '../blocs/agents/agents_bloc.dart';
import '../blocs/sessions/sessions_bloc.dart';
import '../widgets/widgets.dart';
import 'settings_screen.dart';

/// Main app shell with bottom navigation: Chat, Agents, Settings.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  static const _tabs = [
    _NavigationItem(label: 'Chat', icon: Icons.chat_bubble_outline),
    _NavigationItem(label: 'Agents', icon: Icons.smart_toy_outlined),
    _NavigationItem(label: 'Settings', icon: Icons.settings_outlined),
  ];

  @override
  void initState() {
    super.initState();
    context.read<SessionsBloc>().add(const LoadSessions());
    context.read<AgentsBloc>().add(const LoadAgents());
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTokens.forBrightness(Brightness.dark);

    return Scaffold(
      backgroundColor: tokens.bgDeep,
      body: SafeArea(
        child: Column(
          children: [
            const ConnectionStatusBanner(),
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: const [
                  _ChatTab(),
                  _AgentsTab(),
                  SettingsScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: tokens.bgSurface,
        selectedItemColor: tokens.accentGold,
        unselectedItemColor: tokens.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        items: _tabs
            .map((t) => BottomNavigationBarItem(icon: Icon(t.icon), label: t.label))
            .toList(),
      ),
    );
  }
}

class _NavigationItem {
  final String label;
  final IconData icon;
  const _NavigationItem({required this.label, required this.icon});
}

// ── Chat tab ───────────────────────────────────────

class _ChatTab extends StatelessWidget {
  const _ChatTab();

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTokens.forBrightness(Brightness.dark);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(tokens.space5),
            child: Text('Chats', style: tokens.textTheme.headlineLarge),
          ),
        ),
        BlocBuilder<SessionsBloc, SessionsState>(
          builder: (context, state) {
            if (state is SessionsLoading) {
              return const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (state is SessionsError) {
              return SliverFillRemaining(
                child: Center(child: Text(state.message, style: tokens.textTheme.bodyMedium)),
              );
            }
            if (state is SessionsLoaded) {
              final sessions = state.sessions;
              if (sessions.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'No chats yet',
                      style: tokens.textTheme.bodyMedium?.copyWith(color: tokens.textMuted),
                    ),
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _SessionCard(session: sessions[index]),
                  childCount: sessions.length,
                ),
              );
            }
            return const SliverToBoxAdapter(child: SizedBox.shrink());
          },
        ),
      ],
    );
  }
}

class _SessionCard extends StatelessWidget {
  final Session session;
  const _SessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTokens.forBrightness(Brightness.dark);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: tokens.space4, vertical: tokens.space2),
      child: AurumCard(
        material: tokens.satin,
        onTap: () {
          context.push('/chat/${session.id}');
        },
        child: Row(
          children: [
            AurumAvatar(
              initials: session.title.characters.first.toUpperCase(),
              size: AurumAvatarSize.md,
            ),
            SizedBox(width: tokens.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(session.title, style: tokens.textTheme.titleMedium),
                      ),
                      if (session.isPinned)
                        Padding(
                          padding: EdgeInsets.only(left: tokens.space2),
                          child: Icon(Icons.push_pin, size: 14, color: tokens.accentGold),
                        ),
                    ],
                  ),
                  if (session.lastMessagePreview != null)
                    Text(
                      session.lastMessagePreview!,
                      style: tokens.textTheme.bodySmall?.copyWith(color: tokens.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            SizedBox(width: tokens.space3),
            AurumBadge(
              label: '${session.messageCount}',
              variant: AurumBadgeVariant.neutral,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Agents tab ─────────────────────────────────────

class _AgentsTab extends StatelessWidget {
  const _AgentsTab();

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTokens.forBrightness(Brightness.dark);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(tokens.space5),
            child: Text('Agents', style: tokens.textTheme.headlineLarge),
          ),
        ),
        BlocBuilder<AgentsBloc, AgentsState>(
          builder: (context, state) {
            if (state is AgentsLoading) {
              return const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (state is AgentsError) {
              return SliverFillRemaining(
                child: Center(child: Text(state.message, style: tokens.textTheme.bodyMedium)),
              );
            }
            if (state is AgentsLoaded) {
              final agents = state.agents;
              if (agents.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'No agents yet',
                      style: tokens.textTheme.bodyMedium?.copyWith(color: tokens.textMuted),
                    ),
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _AgentCard(agent: agents[index]),
                  childCount: agents.length,
                ),
              );
            }
            return const SliverToBoxAdapter(child: SizedBox.shrink());
          },
        ),
      ],
    );
  }
}

class _AgentCard extends StatelessWidget {
  final Agent agent;
  const _AgentCard({required this.agent});

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTokens.forBrightness(Brightness.dark);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: tokens.space4, vertical: tokens.space2),
      child: AurumCard(
        material: tokens.satin,
        onTap: () {
          context.push('/agent/${agent.id}');
        },
        child: Row(
          children: [
            AurumAvatar(
              initials: agent.name.characters.take(2).join().toUpperCase(),
              size: AurumAvatarSize.md,
              isOnline: agent.isActive,
            ),
            SizedBox(width: tokens.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(agent.name, style: tokens.textTheme.titleMedium),
                  if (agent.description != null)
                    Text(
                      agent.description!,
                      style: tokens.textTheme.bodySmall?.copyWith(color: tokens.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            SizedBox(width: tokens.space3),
            AurumBadge(
              label: agent.isActive ? 'Active' : 'Inactive',
              variant: agent.isActive ? AurumBadgeVariant.success : AurumBadgeVariant.neutral,
            ),
          ],
        ),
      ),
    );
  }
}
