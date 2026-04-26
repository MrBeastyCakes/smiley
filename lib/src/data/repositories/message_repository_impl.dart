import 'dart:async';
import 'package:async/async.dart';

import 'package:dartz/dartz.dart';

import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/message_repository.dart';
import '../datasources/message_remote_datasource.dart';
import '../local/message_local_datasource.dart';
import '../models/chat_message_model.dart';

/// Local-first repository for [ChatMessage] operations.
///
/// Messages are written to SQLite immediately and optionally synced to the
/// gateway when a connection is available.
class MessageRepositoryImpl implements MessageRepository {
  final MessageLocalDataSource localDataSource;
  final MessageRemoteDataSource? remoteDataSource;

  const MessageRepositoryImpl({
    required this.localDataSource,
    this.remoteDataSource,
  });

  bool get _hasRemote => remoteDataSource != null;

  List<ChatMessage> _modelsToEntities(List<ChatMessageModel> models) =>
      models.map((m) => m.toEntity()).toList();

  @override
  Future<Either<Failure, List<ChatMessage>>> getMessages(String sessionId) async {
    try {
      final localModels = await localDataSource.listMessages(sessionId);
      final localEntities = _modelsToEntities(localModels);

      if (_hasRemote) {
        unawaited(_syncMessagesFromRemote(sessionId));
      }

      return Right(localEntities);
    } on StorageException catch (e) {
      return Left(StorageFailure(e.message, code: e.code));
    } catch (e) {
      return Left(UnexpectedFailure('Failed to get messages: $e'));
    }
  }

  Future<void> _syncMessagesFromRemote(String sessionId) async {
    try {
      final remoteModels = await remoteDataSource!.listMessages(sessionId);
      await localDataSource.saveMessages(remoteModels);
    } catch (_) {
      // Local cache remains authoritative.
    }
  }

  @override
  Future<Either<Failure, ChatMessage>> sendMessage(String sessionId, String text) async {
    try {
      // 1. Save locally immediately (pending status).
      final localModel = await localDataSource.sendMessage(sessionId, text);

      // 2. Attempt remote send.
      if (_hasRemote) {
        try {
          final remoteModel = await remoteDataSource!.sendMessage(sessionId, text);
          // Overwrite local pending copy with server-confirmed message.
          await localDataSource.saveMessage(remoteModel);
          return Right(remoteModel.toEntity());
        } catch (_) {
          // Remote failed — mark local message failed so UI can show retry affordance.
          final failedLocal = ChatMessageModel(
            id: localModel.id,
            sessionId: localModel.sessionId,
            role: localModel.role,
            text: localModel.text,
            timestamp: localModel.timestamp,
            status: 'failed',
            editedAt: localModel.editedAt,
            agentId: localModel.agentId,
            thinking: localModel.thinking,
            actionCards: localModel.actionCards,
            attachments: localModel.attachments,
            metadata: localModel.metadata,
          );
          await localDataSource.saveMessage(failedLocal);
          return Right(failedLocal.toEntity());
        }
      }

      return Right(localModel.toEntity());
    } on StorageException catch (e) {
      return Left(StorageFailure(e.message, code: e.code));
    } catch (e) {
      return Left(UnexpectedFailure('Failed to send message: $e'));
    }
  }

  @override
  Stream<Either<Failure, ChatMessage>> watchNewMessages(String sessionId) {
    final localStream = localDataSource.watchNewMessages(sessionId).map(
          (model) => Right<Failure, ChatMessage>(model.toEntity()),
        );

    if (!_hasRemote) return localStream;

    final remoteStream = remoteDataSource!.watchNewMessages(sessionId)
        .asyncMap((model) async {
          await localDataSource.saveMessage(model);
          return Right<Failure, ChatMessage>(model.toEntity());
        })
        .transform(StreamTransformer.fromHandlers(
          handleError: (error, stackTrace, sink) {
            sink.add(
              Left<Failure, ChatMessage>(
                error is GatewayException
                    ? GatewayFailure(error.message, code: error.code)
                    : NetworkFailure('New message stream error: $error'),
              ),
            );
          },
        ));

    return StreamGroup.merge([localStream, remoteStream]);
  }

  @override
  Stream<Either<Failure, String>> watchMessageStream(String sessionId) {
    if (!_hasRemote) return const Stream.empty();

    return remoteDataSource!.watchMessageEvents()
        .where((json) => json['type'] == 'message_chunk' && json['sessionId'] == sessionId)
        .map((json) => Right<Failure, String>(json['chunk'] as String? ?? ''))
        .transform(StreamTransformer.fromHandlers(
          handleError: (error, stackTrace, sink) {
            sink.add(
              Left<Failure, String>(
                error is GatewayException
                    ? GatewayFailure(error.message, code: error.code)
                    : NetworkFailure('Message stream error: $error'),
              ),
            );
          },
        ));
  }
}
