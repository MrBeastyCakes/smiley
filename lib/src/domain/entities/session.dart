import 'package:equatable/equatable.dart';

class Session extends Equatable {
  final String id;
  final String title;
  final String? agentId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int messageCount;
  final bool isPinned;
  final bool isArchived;
  final String? lastMessagePreview;

  const Session({
    required this.id, required this.title, this.agentId,
    required this.createdAt, required this.updatedAt,
    this.messageCount = 0, this.isPinned = false,
    this.isArchived = false, this.lastMessagePreview,
  });

  Session copyWith({
    String? id, String? title, String? agentId,
    DateTime? createdAt, DateTime? updatedAt,
    int? messageCount, bool? isPinned, bool? isArchived,
    String? lastMessagePreview,
  }) => Session(
    id: id ?? this.id, title: title ?? this.title, agentId: agentId ?? this.agentId,
    createdAt: createdAt ?? this.createdAt, updatedAt: updatedAt ?? this.updatedAt,
    messageCount: messageCount ?? this.messageCount, isPinned: isPinned ?? this.isPinned,
    isArchived: isArchived ?? this.isArchived, lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
  );

  @override List<Object?> get props => [id, title, agentId, createdAt, updatedAt, messageCount, isPinned, isArchived, lastMessagePreview];
}
