import 'dart:async';
import 'package:async/async.dart';

import 'package:dartz/dartz.dart';

import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/session.dart';
import '../../domain/repositories/session_repository.dart';
import '../datasources/session_remote_datasource.dart';
import '../local/session_local_datasource.dart';
import '../models/session_model.dart';

/// Local-first repository for [Session] operations.
///
/// Reads always return local data immediately (fast + offline-capable).
/// When the remote datasource is available, fetched data is persisted
/// locally so subsequent reads are instant.
class SessionRepositoryImpl implements SessionRepository {
  final SessionLocalDataSource localDataSource;
  final SessionRemoteDataSource? remoteDataSource;

  const SessionRepositoryImpl({
    required this.localDataSource,
    this.remoteDataSource,
  });

  bool get _hasRemote => remoteDataSource != null;

  // ── Helpers ─────────────────────────────────────

  SessionModel _entityToModel(Session e) => SessionModel.fromEntity(e);

  List<Session> _modelsToEntities(List<SessionModel> models) =>
      models.map((m) => m.toEntity()).toList();

  // ── Read ────────────────────────────────────────

  @override
  Future<Either<Failure, List<Session>>> getSessions() async {
    try {
      // 1. Return local data immediately.
      final localModels = await localDataSource.listSessions();
      final localEntities = _modelsToEntities(localModels);

      // 2. Background fetch from remote + sync to local.
      if (_hasRemote) {
        unawaited(_syncSessionsFromRemote());
      }

      return Right(localEntities);
    } on StorageException catch (e) {
      return Left(StorageFailure(e.message, code: e.code));
    } catch (e) {
      return Left(UnexpectedFailure('Failed to get sessions: $e'));
    }
  }

  /// Background sync: fetch from remote and overwrite local cache.
  Future<void> _syncSessionsFromRemote() async {
    try {
      final remoteModels = await remoteDataSource!.listSessions();
      await localDataSource.saveSessions(remoteModels);
    } catch (_) {
      // Silently fail — local data is authoritative.
    }
  }

  @override
  Future<Either<Failure, Session>> getSessionById(String id) async {
    try {
      final localModel = await localDataSource.getSessionById(id);

      // Background refresh from remote.
      if (_hasRemote) {
        unawaited(_syncSessionById(id));
      }

      return Right(localModel.toEntity());
    } on StorageException catch (e) {
      return Left(StorageFailure(e.message, code: e.code));
    } catch (e) {
      return Left(UnexpectedFailure('Failed to get session: $e'));
    }
  }

  Future<void> _syncSessionById(String id) async {
    try {
      final remoteModel = await remoteDataSource!.getSessionById(id);
      await localDataSource.saveSession(remoteModel);
    } catch (_) {
      // Silently fail.
    }
  }

  // ── Write ───────────────────────────────────────

  @override
  Future<Either<Failure, void>> pinSession(String id, bool pinned) async {
    try {
      // Local-first write.
      await localDataSource.pinSession(id, pinned);

      // Background sync to remote.
      if (_hasRemote) {
        unawaited(Future(() async {
          try {
            await remoteDataSource!.pinSession(id, pinned);
          } catch (_) {}
        }));
      }

      return const Right(null);
    } on StorageException catch (e) {
      return Left(StorageFailure(e.message, code: e.code));
    } catch (e) {
      return Left(UnexpectedFailure('Failed to pin session: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> archiveSession(String id) async {
    try {
      await localDataSource.archiveSession(id);

      if (_hasRemote) {
        unawaited(Future(() async {
          try {
            await remoteDataSource!.archiveSession(id);
          } catch (_) {}
        }));
      }

      return const Right(null);
    } on StorageException catch (e) {
      return Left(StorageFailure(e.message, code: e.code));
    } catch (e) {
      return Left(UnexpectedFailure('Failed to archive session: $e'));
    }
  }

  // ── Watch ─────────────────────────────────────

  @override
  Stream<Either<Failure, List<Session>>> watchSessions() {
    final localStream = localDataSource.watchSessions().map(
          (models) => Right<Failure, List<Session>>(_modelsToEntities(models)),
        );

    if (!_hasRemote) return localStream;

    // Merge local polling stream with remote push stream.
    final remoteStream = remoteDataSource!.watchSessions().transform(
      StreamTransformer<List<SessionModel>, Either<Failure, List<Session>>>.fromHandlers(
        handleData: (models, sink) async {
          await localDataSource.saveSessions(models);
          sink.add(Right<Failure, List<Session>>(_modelsToEntities(models)));
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

    return StreamGroup.merge([localStream, remoteStream]);
  }
}
