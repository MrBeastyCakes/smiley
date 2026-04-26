import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/repositories/agent_repository.dart';
import 'agent_detail_screen.dart';

/// Loads an agent by id and renders the agent detail screen.
class AgentDetailLoaderScreen extends StatelessWidget {
  final String agentId;
  final AgentRepository repository;
  final String fallbackRoute;

  const AgentDetailLoaderScreen({
    super.key,
    required this.agentId,
    required this.repository,
    this.fallbackRoute = '/home',
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: repository.getAgentById(agentId),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            appBar: AppBar(title: const Text('Loading agent')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return _AgentRouteMessageState(
            title: 'Unable to load agent',
            message: 'Something went wrong while opening this agent. Please try again.',
            fallbackRoute: fallbackRoute,
          );
        }

        final result = snapshot.data;
        if (result == null) {
          return _AgentRouteMessageState(
            title: 'Unable to load agent',
            message: 'No agent data was returned for id "$agentId".',
            fallbackRoute: fallbackRoute,
          );
        }

        return result.fold(
          (failure) {
            final isNotFound = failure.message.toLowerCase().contains('not found');
            return _AgentRouteMessageState(
              title: isNotFound ? 'Agent not found' : 'Unable to load agent',
              message: isNotFound
                  ? 'No agent exists with id "$agentId".'
                  : failure.message,
              fallbackRoute: fallbackRoute,
            );
          },
          (agent) => AgentDetailScreen(agent: agent),
        );
      },
    );
  }
}

class _AgentRouteMessageState extends StatelessWidget {
  final String title;
  final String message;
  final String fallbackRoute;

  const _AgentRouteMessageState({
    required this.title,
    required this.message,
    required this.fallbackRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                    return;
                  }
                  context.go(fallbackRoute);
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
