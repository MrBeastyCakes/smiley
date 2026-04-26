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
