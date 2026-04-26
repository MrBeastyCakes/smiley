part of 'chat_bloc.dart';

sealed class ChatState extends Equatable {
  const ChatState();
  @override List<Object?> get props => [];
}

class ChatInitial extends ChatState {
  const ChatInitial();
}

class ChatLoading extends ChatState {
  const ChatLoading();
}

class ChatLoaded extends ChatState {
  final List<ChatMessage> messages;
  final bool isStreaming;
  const ChatLoaded({required this.messages, this.isStreaming = false});

  ChatLoaded copyWith({List<ChatMessage>? messages, bool? isStreaming}) =>
    ChatLoaded(messages: messages ?? this.messages, isStreaming: isStreaming ?? this.isStreaming);

  @override List<Object?> get props => [messages, isStreaming];
}

class ChatError extends ChatState {
  final String message;
  const ChatError({required this.message});
  @override List<Object?> get props => [message];
}
