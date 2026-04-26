import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../entities/chat_message.dart';

abstract class MessageRepository {
  Future<Either<Failure, List<ChatMessage>>> getMessages(String sessionId);
  Future<Either<Failure, ChatMessage>> sendMessage(String sessionId, String text);
  Stream<Either<Failure, ChatMessage>> watchNewMessages(String sessionId);
  Stream<Either<Failure, String>> watchMessageStream(String sessionId);
}
