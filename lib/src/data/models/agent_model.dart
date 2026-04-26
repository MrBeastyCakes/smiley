import 'package:openclaw_client/src/domain/entities/agent.dart';

/// AgentModel — JSON-serializable representation of Agent entity.
class AgentModel {
  final String id;
  final String name;
  final String? avatarUrl;
  final String? description;
  final List<String> capabilities;
  final String defaultAutonomy;
  final bool isActive;
  final String? lastActiveAt;

  const AgentModel({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.description,
    this.capabilities = const [],
    this.defaultAutonomy = 'suggest',
    this.isActive = false,
    this.lastActiveAt,
  });

  factory AgentModel.fromJson(Map<String, dynamic> json) {
    return AgentModel(
      id: json['id'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      description: json['description'] as String?,
      capabilities: (json['capabilities'] as List<dynamic>?)?.cast<String>() ?? const [],
      defaultAutonomy: json['defaultAutonomy'] as String? ?? 'suggest',
      isActive: json['isActive'] as bool? ?? false,
      lastActiveAt: json['lastActiveAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatarUrl': avatarUrl,
      'description': description,
      'capabilities': capabilities,
      'defaultAutonomy': defaultAutonomy,
      'isActive': isActive,
      'lastActiveAt': lastActiveAt,
    };
  }

  Agent toEntity() {
    return Agent(
      id: id,
      name: name,
      avatarUrl: avatarUrl,
      description: description,
      capabilities: capabilities,
      defaultAutonomy: _parseAutonomyLevel(defaultAutonomy),
      isActive: isActive,
      lastActiveAt: lastActiveAt != null ? DateTime.tryParse(lastActiveAt!) : null,
    );
  }

  factory AgentModel.fromEntity(Agent entity) {
    return AgentModel(
      id: entity.id,
      name: entity.name,
      avatarUrl: entity.avatarUrl,
      description: entity.description,
      capabilities: entity.capabilities,
      defaultAutonomy: entity.defaultAutonomy.name,
      isActive: entity.isActive,
      lastActiveAt: entity.lastActiveAt?.toIso8601String(),
    );
  }

  static AutonomyLevel _parseAutonomyLevel(String value) {
    return AutonomyLevel.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AutonomyLevel.suggest,
    );
  }
}
