import 'package:equatable/equatable.dart';

class Agent extends Equatable {
  final String id;
  final String name;
  final String? avatarUrl;
  final String? description;
  final List<String> capabilities;
  final AutonomyLevel defaultAutonomy;
  final bool isActive;
  final DateTime? lastActiveAt;

  const Agent({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.description,
    this.capabilities = const [],
    this.defaultAutonomy = AutonomyLevel.suggest,
    this.isActive = false,
    this.lastActiveAt,
  });

  Agent copyWith({
    String? id, String? name, String? avatarUrl, String? description,
    List<String>? capabilities, AutonomyLevel? defaultAutonomy,
    bool? isActive, DateTime? lastActiveAt,
  }) => Agent(
    id: id ?? this.id, name: name ?? this.name,
    avatarUrl: avatarUrl ?? this.avatarUrl, description: description ?? this.description,
    capabilities: capabilities ?? this.capabilities,
    defaultAutonomy: defaultAutonomy ?? this.defaultAutonomy,
    isActive: isActive ?? this.isActive, lastActiveAt: lastActiveAt ?? this.lastActiveAt,
  );

  @override List<Object?> get props => [id, name, avatarUrl, description, capabilities, defaultAutonomy, isActive, lastActiveAt];
}

enum AutonomyLevel {
  observe, suggest, confirm, autonomous;

  String get label => switch (this) {
    observe => 'Observe', suggest => 'Suggest',
    confirm => 'Confirm', autonomous => 'Autonomous',
  };

  String get description => switch (this) {
    observe => 'Agent watches and takes notes only',
    suggest => 'Agent proposes actions for your approval',
    confirm => 'Agent executes but asks for irreversible actions',
    autonomous => 'Agent acts freely with full logging',
  };

  bool get canAct => this != AutonomyLevel.observe;
  bool get requiresConfirmation => this == AutonomyLevel.confirm;
  bool get isFullyAutonomous => this == AutonomyLevel.autonomous;
}
