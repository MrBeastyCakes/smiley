part of 'chat_bloc.dart';

sealed class ChatEvent extends Equatable {
  const ChatEvent();
  @override List<Object?> get props => [];
}

class ChatStarted extends ChatEvent {
  const ChatStarted();
}

class MessageSent extends ChatEvent {
  final String sessionId;
  final String text;
  const MessageSent({required this.sessionId, required this.text});
  @override List<Object?> get props => [sessionId, text];
}

class MessageReceived extends ChatEvent {
  final ChatMessage message;
  const MessageReceived(this.message);
  @override List<Object?> get props => [message];
}

class MessageStreamed extends ChatEvent {
  final String sessionId;
  final String chunk;
  const MessageStreamed({required this.sessionId, required this.chunk});
  @override List<Object?> get props => [sessionId, chunk];
}

class ConnectionRestored extends ChatEvent {
  const ConnectionRestored();
}

/// Retry sending pending messages that failed while offline.
class RetryPendingMessages extends ChatEvent {
  final String sessionId;
  const RetryPendingMessages({required this.sessionId});
  @override List<Object?> get props => [sessionId];
}

/// Update message status after remote confirms receipt.
class MessageStatusChanged extends ChatEvent {
  final String messageId;
  final MessageStatus newStatus;
  const MessageStatusChanged({required this.messageId, required this.newStatus});
  @override List<Object?> get props => [messageId, newStatus];
}

class LoadChatMessages extends ChatEvent {
  final String sessionId;
  const LoadChatMessages({required this.sessionId});
  @override List<Object?> get props => [sessionId];
}
