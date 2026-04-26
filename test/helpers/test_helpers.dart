import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:openclaw_client/src/core/errors/failures.dart';
import 'package:openclaw_client/src/domain/entities/chat_message.dart';
import 'package:openclaw_client/src/domain/repositories/message_repository.dart';

/// Lightweight mock for widget/golden tests that need a ChatBloc
/// but don't care about repository behavior.
class NoOpMessageRepository implements MessageRepository {
  @override
  Future<Either<Failure, List<ChatMessage>>> getMessages(String sessionId) async =>
    const Right([]);

  @override
  Future<Either<Failure, ChatMessage>> sendMessage(String sessionId, String text) async =>
    Right(ChatMessage(
      id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
      sessionId: sessionId,
      role: 'user',
      text: text,
      timestamp: DateTime.now(),
    ));

  @override
  Stream<Either<Failure, ChatMessage>> watchNewMessages(String sessionId) =>
    const Stream.empty();

  @override
  Stream<Either<Failure, String>> watchMessageStream(String sessionId) =>
    const Stream.empty();
}
