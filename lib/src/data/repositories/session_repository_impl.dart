import 'dart:async';

import 'package:dartz/dartz.dart';

import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/session.dart';
import '../../domain/repositories/session_repository.dart';
import '../datasources/session_remote_datasource.dart';
import '../models/session_model.dart';

class SessionRepositoryImpl implements SessionRepository {
  final SessionRemoteDataSource remoteDataSource;

  const SessionRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Session>>> getSessions() async {
    try {
      final models = await remoteDataSource.listSessions();
      final entities = models.map((m) => m.toEntity()).toList();
      return Right(entities);
    } on GatewayException catch (e) {
      return Left(GatewayFailure(e.message, code: e.code));
    } catch (e) {
      return Left(NetworkFailure('Failed to get sessions: $e'));
    }
  }

  @override
  Future<Either<Failure, Session>> getSessionById(String id) async {
    try {
      final model = await remoteDataSource.getSessionById(id);
      return Right(model.toEntity());
    } on GatewayException catch (e) {
      return Left(GatewayFailure(e.message, code: e.code));
    } catch (e) {
      return Left(NetworkFailure('Failed to get session: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> pinSession(String id, bool pinned) async {
    try {
      await remoteDataSource.pinSession(id, pinned);
      return const Right(null);
    } on GatewayException catch (e) {
      return Left(GatewayFailure(e.message, code: e.code));
    } catch (e) {
      return Left(NetworkFailure('Failed to pin session: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> archiveSession(String id) async {
    try {
      await remoteDataSource.archiveSession(id);
      return const Right(null);
    } on GatewayException catch (e) {
      return Left(GatewayFailure(e.message, code: e.code));
    } catch (e) {
      return Left(NetworkFailure('Failed to archive session: $e'));
    }
  }

  @override
  Stream<Either<Failure, List<Session>>> watchSessions() {
    return remoteDataSource.watchSessions().transform(
      StreamTransformer<List<SessionModel>, Either<Failure, List<Session>>>.fromHandlers(
        handleData: (models, sink) {
          try {
            final entities = models.map((m) => m.toEntity()).toList();
            sink.add(Right(entities));
          } catch (e) {
            sink.add(Left(NetworkFailure('Failed to parse session update: $e')));
          }
        },
        handleError: (Object error, StackTrace stackTrace, EventSink<Either<Failure, List<Session>>> sink) {
          if (error is GatewayException) {
            sink.add(Left(GatewayFailure(error.message, code: error.code)));
          } else {
            sink.add(Left(NetworkFailure('Session stream error: $error')));
          }
        },
      ),
    );
  }
}
