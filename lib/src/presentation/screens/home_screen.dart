import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/design_tokens.dart';
import '../../domain/entities/agent.dart';
import '../../domain/entities/session.dart';
import '../blocs/chat/chat_bloc.dart';
import '../widgets/widgets.dart';
import 'agent_detail_screen.dart';
import 'chat_screen.dart';
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

  static final _mockSessions = [
    Session(
      id: 'session-1', title: 'General chat', agentId: 'agent-1',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      updatedAt: DateTime.now().subtract(const Duration(minutes: 5)),
      messageCount: 42, lastMessagePreview: 'Let me check that for you...',
    ),
    Session(
      id: 'session-2', title: 'Code review helper', agentId: 'agent-2',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
      messageCount: 18, isPinned: true,
      lastMessagePreview: 'Looks good, but consider...',
    ),
    Session(
      id: 'session-3', title: 'Trip planner',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 6)),
      messageCount: 7, lastMessagePreview: 'Here are the best flights...',
    ),
  ];

  static final _mockAgents = [
    Agent(
      id: 'agent-1', name: 'Rosalina',
      description: 'Queen of the galaxy. Warm, sarcastic, and always helpful.',
      capabilities: const ['chat', 'search', 'summarize', 'weather'],
      defaultAutonomy: AutonomyLevel.suggest, isActive: true,
      lastActiveAt: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
    Agent(
      id: 'agent-2', name: 'CodeBot',
      description: 'Specialized in code review, debugging, and architecture.',
      capabilities: const ['code_review', 'debug', 'refactor', 'explain'],
      defaultAutonomy: AutonomyLevel.confirm, isActive: true,
      lastActiveAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    Agent(
      id: 'agent-3', name: 'Planner',
      description: 'Travel, scheduling, and logistics assistant.',
      capabilities: const ['travel', 'calendar', 'booking'],
      defaultAutonomy: AutonomyLevel.observe, isActive: false,
      lastActiveAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTokens.forBrightness(Brightness.dark);

    return Scaffold(
      backgroundColor: tokens.bgDeep,
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: [
            _ChatTab(sessions: _mockSessions),
            _AgentsTab(agents: _mockAgents),
            const SettingsScreen(),
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
  final List<Session> sessions;
  const _ChatTab({required this.sessions});

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
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _SessionCard(session: sessions[index]),
            childCount: sessions.length,
          ),
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
  final List<Agent> agents;
  const _AgentsTab({required this.agents});

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
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _AgentCard(agent: agents[index]),
            childCount: agents.length,
          ),
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
