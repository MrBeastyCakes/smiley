import 'package:openclaw_client/src/domain/entities/chat_message.dart';

/// ChatMessageModel — JSON-serializable representation of ChatMessage entity.
class ChatMessageModel {
  final String id;
  final String sessionId;
  final String role;
  final String text;
  final String timestamp;
  final String status;
  final String? editedAt;
  final String? agentId;
  final ThinkingBlockModel? thinking;
  final List<ActionCardModel> actionCards;
  final List<MessageAttachmentModel> attachments;
  final MessageMetadataModel? metadata;

  const ChatMessageModel({
    required this.id,
    required this.sessionId,
    required this.role,
    required this.text,
    required this.timestamp,
    this.status = 'sent',
    this.editedAt,
    this.agentId,
    this.thinking,
    this.actionCards = const [],
    this.attachments = const [],
    this.metadata,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] as String,
      sessionId: json['sessionId'] as String,
      role: json['role'] as String,
      text: json['text'] as String,
      timestamp: json['timestamp'] as String,
      status: json['status'] as String? ?? 'sent',
      editedAt: json['editedAt'] as String?,
      agentId: json['agentId'] as String?,
      thinking: json['thinking'] != null
          ? ThinkingBlockModel.fromJson(json['thinking'] as Map<String, dynamic>)
          : null,
      actionCards: (json['actionCards'] as List<dynamic>?)
              ?.map((e) => ActionCardModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map((e) => MessageAttachmentModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      metadata: json['metadata'] != null
          ? MessageMetadataModel.fromJson(json['metadata'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sessionId': sessionId,
      'role': role,
      'text': text,
      'timestamp': timestamp,
      'status': status,
      'editedAt': editedAt,
      'agentId': agentId,
      'thinking': thinking?.toJson(),
      'actionCards': actionCards.map((e) => e.toJson()).toList(),
      'attachments': attachments.map((e) => e.toJson()).toList(),
      'metadata': metadata?.toJson(),
    };
  }

  ChatMessage toEntity() {
    return ChatMessage(
      id: id,
      sessionId: sessionId,
      role: role,
      text: text,
      timestamp: DateTime.parse(timestamp),
      status: _parseMessageStatus(status),
      editedAt: editedAt != null ? DateTime.tryParse(editedAt!) : null,
      agentId: agentId,
      thinking: thinking?.toEntity(),
      actionCards: actionCards.map((e) => e.toEntity()).toList(),
      attachments: attachments.map((e) => e.toEntity()).toList(),
      metadata: metadata?.toEntity(),
    );
  }

  factory ChatMessageModel.fromEntity(ChatMessage entity) {
    return ChatMessageModel(
      id: entity.id,
      sessionId: entity.sessionId,
      role: entity.role,
      text: entity.text,
      timestamp: entity.timestamp.toIso8601String(),
      status: entity.status.name,
      editedAt: entity.editedAt?.toIso8601String(),
      agentId: entity.agentId,
      thinking: entity.thinking != null
          ? ThinkingBlockModel.fromEntity(entity.thinking!)
          : null,
      actionCards: entity.actionCards
          .map((e) => ActionCardModel.fromEntity(e))
          .toList(),
      attachments: entity.attachments
          .map((e) => MessageAttachmentModel.fromEntity(e))
          .toList(),
      metadata: entity.metadata != null
          ? MessageMetadataModel.fromEntity(entity.metadata!)
          : null,
    );
  }

  static MessageStatus _parseMessageStatus(String value) {
    return MessageStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MessageStatus.sent,
    );
  }
}

class ThinkingBlockModel {
  final String content;
  final bool isExpanded;
  final String? startedAt;
  final String? completedAt;

  const ThinkingBlockModel({
    required this.content,
    this.isExpanded = false,
    this.startedAt,
    this.completedAt,
  });

  factory ThinkingBlockModel.fromJson(Map<String, dynamic> json) {
    return ThinkingBlockModel(
      content: json['content'] as String,
      isExpanded: json['isExpanded'] as bool? ?? false,
      startedAt: json['startedAt'] as String?,
      completedAt: json['completedAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'isExpanded': isExpanded,
      'startedAt': startedAt,
      'completedAt': completedAt,
    };
  }

  ThinkingBlock toEntity() {
    return ThinkingBlock(
      content: content,
      isExpanded: isExpanded,
      startedAt: startedAt != null ? DateTime.tryParse(startedAt!) : null,
      completedAt: completedAt != null ? DateTime.tryParse(completedAt!) : null,
    );
  }

  factory ThinkingBlockModel.fromEntity(ThinkingBlock entity) {
    return ThinkingBlockModel(
      content: entity.content,
      isExpanded: entity.isExpanded,
      startedAt: entity.startedAt?.toIso8601String(),
      completedAt: entity.completedAt?.toIso8601String(),
    );
  }
}

class ActionCardModel {
  final String id;
  final String title;
  final String? description;
  final String actionType;
  final List<ActionButtonModel> buttons;
  final String? rationale;
  final double? confidence;

  const ActionCardModel({
    required this.id,
    required this.title,
    this.description,
    required this.actionType,
    this.buttons = const [],
    this.rationale,
    this.confidence,
  });

  factory ActionCardModel.fromJson(Map<String, dynamic> json) {
    return ActionCardModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      actionType: json['actionType'] as String,
      buttons: (json['buttons'] as List<dynamic>?)
              ?.map((e) => ActionButtonModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      rationale: json['rationale'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'actionType': actionType,
      'buttons': buttons.map((e) => e.toJson()).toList(),
      'rationale': rationale,
      'confidence': confidence,
    };
  }

  ActionCard toEntity() {
    return ActionCard(
      id: id,
      title: title,
      description: description,
      actionType: actionType,
      buttons: buttons.map((e) => e.toEntity()).toList(),
      rationale: rationale,
      confidence: confidence,
    );
  }

  factory ActionCardModel.fromEntity(ActionCard entity) {
    return ActionCardModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      actionType: entity.actionType,
      buttons: entity.buttons
          .map((e) => ActionButtonModel.fromEntity(e))
          .toList(),
      rationale: entity.rationale,
      confidence: entity.confidence,
    );
  }
}

class ActionButtonModel {
  final String id;
  final String label;
  final String action;
  final bool isPrimary;

  const ActionButtonModel({
    required this.id,
    required this.label,
    required this.action,
    this.isPrimary = false,
  });

  factory ActionButtonModel.fromJson(Map<String, dynamic> json) {
    return ActionButtonModel(
      id: json['id'] as String,
      label: json['label'] as String,
      action: json['action'] as String,
      isPrimary: json['isPrimary'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'action': action,
      'isPrimary': isPrimary,
    };
  }

  ActionButton toEntity() {
    return ActionButton(
      id: id,
      label: label,
      action: action,
      isPrimary: isPrimary,
    );
  }

  factory ActionButtonModel.fromEntity(ActionButton entity) {
    return ActionButtonModel(
      id: entity.id,
      label: entity.label,
      action: entity.action,
      isPrimary: entity.isPrimary,
    );
  }
}

class MessageAttachmentModel {
  final String id;
  final String type;
  final String name;
  final String? uri;
  final int? sizeBytes;
  final String? mimeType;

  const MessageAttachmentModel({
    required this.id,
    required this.type,
    required this.name,
    this.uri,
    this.sizeBytes,
    this.mimeType,
  });

  factory MessageAttachmentModel.fromJson(Map<String, dynamic> json) {
    return MessageAttachmentModel(
      id: json['id'] as String,
      type: json['type'] as String,
      name: json['name'] as String,
      uri: json['uri'] as String?,
      sizeBytes: json['sizeBytes'] as int?,
      mimeType: json['mimeType'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'name': name,
      'uri': uri,
      'sizeBytes': sizeBytes,
      'mimeType': mimeType,
    };
  }

  MessageAttachment toEntity() {
    return MessageAttachment(
      id: id,
      type: type,
      name: name,
      uri: uri,
      sizeBytes: sizeBytes,
      mimeType: mimeType,
    );
  }

  factory MessageAttachmentModel.fromEntity(MessageAttachment entity) {
    return MessageAttachmentModel(
      id: entity.id,
      type: entity.type,
      name: entity.name,
      uri: entity.uri,
      sizeBytes: entity.sizeBytes,
      mimeType: entity.mimeType,
    );
  }
}

class MessageMetadataModel {
  final int? tokenCount;
  final int? latencyMs;
  final String? modelName;
  final List<String>? citations;

  const MessageMetadataModel({
    this.tokenCount,
    this.latencyMs,
    this.modelName,
    this.citations,
  });

  factory MessageMetadataModel.fromJson(Map<String, dynamic> json) {
    return MessageMetadataModel(
      tokenCount: json['tokenCount'] as int?,
      latencyMs: json['latencyMs'] as int?,
      modelName: json['modelName'] as String?,
      citations: (json['citations'] as List<dynamic>?)?.cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tokenCount': tokenCount,
      'latencyMs': latencyMs,
      'modelName': modelName,
      'citations': citations,
    };
  }

  MessageMetadata toEntity() {
    return MessageMetadata(
      tokenCount: tokenCount,
      latency: latencyMs != null ? Duration(milliseconds: latencyMs!) : null,
      modelName: modelName,
      citations: citations,
    );
  }

  factory MessageMetadataModel.fromEntity(MessageMetadata entity) {
    return MessageMetadataModel(
      tokenCount: entity.tokenCount,
      latencyMs: entity.latency?.inMilliseconds,
      modelName: entity.modelName,
      citations: entity.citations,
    );
  }
}
