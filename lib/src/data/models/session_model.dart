import 'package:openclaw_client/src/domain/entities/session.dart';

/// SessionModel — JSON-serializable representation of Session entity.
class SessionModel {
  final String id;
  final String title;
  final String? agentId;
  final String createdAt;
  final String updatedAt;
  final int messageCount;
  final bool isPinned;
  final bool isArchived;
  final String? lastMessagePreview;

  const SessionModel({
    required this.id,
    required this.title,
    this.agentId,
    required this.createdAt,
    required this.updatedAt,
    this.messageCount = 0,
    this.isPinned = false,
    this.isArchived = false,
    this.lastMessagePreview,
  });

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    return SessionModel(
      id: json['id'] as String,
      title: json['title'] as String,
      agentId: json['agentId'] as String?,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
      messageCount: json['messageCount'] as int? ?? 0,
      isPinned: json['isPinned'] as bool? ?? false,
      isArchived: json['isArchived'] as bool? ?? false,
      lastMessagePreview: json['lastMessagePreview'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'agentId': agentId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'messageCount': messageCount,
      'isPinned': isPinned,
      'isArchived': isArchived,
      'lastMessagePreview': lastMessagePreview,
    };
  }

  Session toEntity() {
    return Session(
      id: id,
      title: title,
      agentId: agentId,
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
      messageCount: messageCount,
      isPinned: isPinned,
      isArchived: isArchived,
      lastMessagePreview: lastMessagePreview,
    );
  }

  factory SessionModel.fromEntity(Session entity) {
    return SessionModel(
      id: entity.id,
      title: entity.title,
      agentId: entity.agentId,
      createdAt: entity.createdAt.toIso8601String(),
      updatedAt: entity.updatedAt.toIso8601String(),
      messageCount: entity.messageCount,
      isPinned: entity.isPinned,
      isArchived: entity.isArchived,
      lastMessagePreview: entity.lastMessagePreview,
    );
  }
}
