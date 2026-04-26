import 'dart:async';
import 'package:async/async.dart';

import 'package:dartz/dartz.dart';

import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/agent.dart';
import '../../domain/repositories/agent_repository.dart';
import '../datasources/agent_remote_datasource.dart';
import '../local/agent_local_datasource.dart';
import '../models/agent_model.dart';

/// Local-first repository for [Agent] operations.
///
/// Agents are cached locally; writes are local-first with background sync.
class AgentRepositoryImpl implements AgentRepository {
  final AgentLocalDataSource localDataSource;
  final AgentRemoteDataSource? remoteDataSource;

  const AgentRepositoryImpl({
    required this.localDataSource,
    this.remoteDataSource,
  });

  bool get _hasRemote => remoteDataSource != null;

  List<Agent> _modelsToEntities(List<AgentModel> models) =>
      models.map((m) => m.toEntity()).toList();

  @override
  Future<Either<Failure, List<Agent>>> getAgents() async {
    try {
      final localModels = await localDataSource.getAgents();
      final localEntities = _modelsToEntities(localModels);

      if (_hasRemote) {
        unawaited(_syncAgentsFromRemote());
      }

      return Right(localEntities);
    } on StorageException catch (e) {
      return Left(StorageFailure(e.message, code: e.code));
    } catch (e) {
      return Left(UnexpectedFailure('Failed to get agents: $e'));
    }
  }

  Future<void> _syncAgentsFromRemote() async {
    try {
      final remoteModels = await remoteDataSource!.getAgents();
      await localDataSource.saveAgents(remoteModels);
    } catch (_) {
      // Local cache remains authoritative.
    }
  }

  @override
  Future<Either<Failure, Agent>> getAgentById(String id) async {
    try {
      final localModel = await localDataSource.getAgentById(id);

      if (_hasRemote) {
        unawaited(_syncAgentById(id));
      }

      return Right(localModel.toEntity());
    } on StorageException catch (e) {
      return Left(StorageFailure(e.message, code: e.code));
    } catch (e) {
      return Left(UnexpectedFailure('Failed to get agent: $e'));
    }
  }

  Future<void> _syncAgentById(String id) async {
    try {
      final remoteModel = await remoteDataSource!.getAgentById(id);
      await localDataSource.saveAgent(remoteModel);
    } catch (_) {
      // Silently fail.
    }
  }

  @override
  Future<Either<Failure, void>> updateAutonomy(String id, AutonomyLevel level) async {
    try {
      await localDataSource.updateAutonomy(id, level);

      if (_hasRemote) {
        unawaited(
          Future(() => remoteDataSource!.updateAutonomy(id, level))
              .catchError((_) {}),
        );
      }

      return const Right(null);
    } on StorageException catch (e) {
      return Left(StorageFailure(e.message, code: e.code));
    } catch (e) {
      return Left(UnexpectedFailure('Failed to update autonomy: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> toggleActive(String id, bool active) async {
    try {
      await localDataSource.toggleActive(id, active);

      if (_hasRemote) {
        unawaited(
          Future(() => remoteDataSource!.toggleActive(id, active))
              .catchError((_) {}),
        );
      }

      return const Right(null);
    } on StorageException catch (e) {
      return Left(StorageFailure(e.message, code: e.code));
    } catch (e) {
      return Left(UnexpectedFailure('Failed to toggle active state: $e'));
    }
  }

  @override
  Stream<Either<Failure, List<Agent>>> watchAgents() {
    // Local stream is authoritative; remote sync happens in background.
    return localDataSource.watchAgents().map(
      (models) => Right<Failure, List<Agent>>(_modelsToEntities(models)),
    );
  }
}
