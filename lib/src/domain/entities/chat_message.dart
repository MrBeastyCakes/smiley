import 'package:equatable/equatable.dart';

class ChatMessage extends Equatable {
  final String id;
  final String sessionId;
  final String role;
  final String text;
  final List<MessageAttachment> attachments;
  final MessageStatus status;
  final DateTime timestamp;
  final DateTime? editedAt;
  final String? agentId;
  final ThinkingBlock? thinking;
  final List<ActionCard> actionCards;
  final MessageMetadata? metadata;

  const ChatMessage({
    required this.id, required this.sessionId, required this.role,
    required this.text, this.attachments = const [],
    this.status = MessageStatus.sent, required this.timestamp,
    this.editedAt, this.agentId, this.thinking,
    this.actionCards = const [], this.metadata,
  });

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';
  bool get isStreaming => status == MessageStatus.streaming;
  bool get hasFailed => status == MessageStatus.failed;

  ChatMessage copyWith({
    String? id, String? sessionId, String? role, String? text,
    List<MessageAttachment>? attachments, MessageStatus? status,
    DateTime? timestamp, DateTime? editedAt, String? agentId,
    ThinkingBlock? thinking, List<ActionCard>? actionCards,
    MessageMetadata? metadata,
  }) => ChatMessage(
    id: id ?? this.id, sessionId: sessionId ?? this.sessionId,
    role: role ?? this.role, text: text ?? this.text,
    attachments: attachments ?? this.attachments, status: status ?? this.status,
    timestamp: timestamp ?? this.timestamp, editedAt: editedAt ?? this.editedAt,
    agentId: agentId ?? this.agentId, thinking: thinking ?? this.thinking,
    actionCards: actionCards ?? this.actionCards, metadata: metadata ?? this.metadata,
  );

  @override List<Object?> get props => [id, sessionId, role, text, attachments, status, timestamp, editedAt, agentId, thinking, actionCards, metadata];
}

enum MessageStatus { pending, streaming, sent, failed, cancelled }

class MessageAttachment extends Equatable {
  final String id; final String type; final String name;
  final String? uri; final int? sizeBytes; final String? mimeType;
  const MessageAttachment({required this.id, required this.type, required this.name, this.uri, this.sizeBytes, this.mimeType});
  @override List<Object?> get props => [id, type, name, uri, sizeBytes, mimeType];
}

class ThinkingBlock extends Equatable {
  final String content; final bool isExpanded;
  final DateTime? startedAt; final DateTime? completedAt;
  const ThinkingBlock({required this.content, this.isExpanded = false, this.startedAt, this.completedAt});
  ThinkingBlock copyWith({String? content, bool? isExpanded, DateTime? startedAt, DateTime? completedAt}) => ThinkingBlock(content: content ?? this.content, isExpanded: isExpanded ?? this.isExpanded, startedAt: startedAt ?? this.startedAt, completedAt: completedAt ?? this.completedAt);
  @override List<Object?> get props => [content, isExpanded, startedAt, completedAt];
}

class ActionCard extends Equatable {
  final String id; final String title; final String? description;
  final String actionType; final List<ActionButton> buttons;
  final String? rationale; final double? confidence;
  const ActionCard({required this.id, required this.title, this.description, required this.actionType, this.buttons = const [], this.rationale, this.confidence});
  @override List<Object?> get props => [id, title, description, actionType, buttons, rationale, confidence];
}

class ActionButton extends Equatable {
  final String id; final String label; final String action; final bool isPrimary;
  const ActionButton({required this.id, required this.label, required this.action, this.isPrimary = false});
  @override List<Object?> get props => [id, label, action, isPrimary];
}

class MessageMetadata extends Equatable {
  final int? tokenCount; final Duration? latency; final String? modelName; final List<String>? citations;
  const MessageMetadata({this.tokenCount, this.latency, this.modelName, this.citations});
  @override List<Object?> get props => [tokenCount, latency, modelName, citations];
}
