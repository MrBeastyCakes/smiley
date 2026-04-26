import 'package:dartz/dartz.dart';

import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/message_repository.dart';
import '../datasources/message_remote_datasource.dart';

class MessageRepositoryImpl implements MessageRepository {
  final MessageRemoteDataSource remoteDataSource;

  const MessageRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<ChatMessage>>> getMessages(String sessionId) async {
    try {
      final models = await remoteDataSource.listMessages(sessionId);
      return Right(models.map((m) => m.toEntity()).toList());
    } on GatewayException catch (e) {
      return Left(GatewayFailure(e.message, code: e.code));
    } catch (e) {
      return Left(UnexpectedFailure('Unexpected error while getting messages'));
    }
  }

  @override
  Future<Either<Failure, ChatMessage>> sendMessage(String sessionId, String text) async {
    try {
      final model = await remoteDataSource.sendMessage(sessionId, text);
      return Right(model.toEntity());
    } on GatewayException catch (e) {
      return Left(GatewayFailure(e.message, code: e.code));
    } catch (e) {
      return Left(UnexpectedFailure('Unexpected error while sending message'));
    }
  }

  @override
  Stream<Either<Failure, ChatMessage>> watchNewMessages(String sessionId) {
    return remoteDataSource.watchNewMessages(sessionId).map(
          (model) => Right<Failure, ChatMessage>(model.toEntity()),
        ).handleError((Object error) {
      if (error is GatewayException) {
        return Left<Failure, ChatMessage>(
          GatewayFailure(error.message, code: error.code),
        );
      }
      return Left<Failure, ChatMessage>(
        UnexpectedFailure('Unexpected error while watching new messages'),
      );
    });
  }

  @override
  Stream<Either<Failure, String>> watchMessageStream(String sessionId) {
    return remoteDataSource.watchMessageEvents().where(
          (json) =>
              json['type'] == 'message_chunk' && json['sessionId'] == sessionId,
        ).map(
          (json) =>
              Right<Failure, String>(json['chunk'] as String? ?? ''),
        ).handleError((Object error) {
      if (error is GatewayException) {
        return Left<Failure, String>(
          GatewayFailure(error.message, code: error.code),
        );
      }
      return Left<Failure, String>(
        UnexpectedFailure('Unexpected error while watching message stream'),
      );
    });
  }
}
