import 'dart:async';

import 'package:dartz/dartz.dart';

import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/agent.dart';
import '../../domain/repositories/agent_repository.dart';
import '../datasources/agent_remote_datasource.dart';

class AgentRepositoryImpl implements AgentRepository {
  final AgentRemoteDataSource remoteDataSource;

  const AgentRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Agent>>> getAgents() async {
    try {
      final models = await remoteDataSource.getAgents();
      return Right(models.map((m) => m.toEntity()).toList());
    } on ConnectionTimeoutException catch (e) {
      return Left(NetworkFailure(e.message, code: e.code));
    } on GatewayException catch (e) {
      return Left(GatewayFailure(e.message, code: e.code));
    } catch (e) {
      return Left(UnexpectedFailure('Unexpected error while getting agents'));
    }
  }

  @override
  Future<Either<Failure, Agent>> getAgentById(String id) async {
    try {
      final model = await remoteDataSource.getAgentById(id);
      return Right(model.toEntity());
    } on ConnectionTimeoutException catch (e) {
      return Left(NetworkFailure(e.message, code: e.code));
    } on GatewayException catch (e) {
      return Left(GatewayFailure(e.message, code: e.code));
    } catch (e) {
      return Left(UnexpectedFailure('Unexpected error while getting agent'));
    }
  }

  @override
  Future<Either<Failure, void>> updateAutonomy(String id, AutonomyLevel level) async {
    try {
      await remoteDataSource.updateAutonomy(id, level);
      return const Right(null);
    } on ConnectionTimeoutException catch (e) {
      return Left(NetworkFailure(e.message, code: e.code));
    } on GatewayException catch (e) {
      return Left(GatewayFailure(e.message, code: e.code));
    } catch (e) {
      return Left(UnexpectedFailure('Unexpected error while updating autonomy'));
    }
  }

  @override
  Future<Either<Failure, void>> toggleActive(String id, bool active) async {
    try {
      await remoteDataSource.toggleActive(id, active);
      return const Right(null);
    } on ConnectionTimeoutException catch (e) {
      return Left(NetworkFailure(e.message, code: e.code));
    } on GatewayException catch (e) {
      return Left(GatewayFailure(e.message, code: e.code));
    } catch (e) {
      return Left(UnexpectedFailure('Unexpected error while toggling active state'));
    }
  }

  @override
  Stream<Either<Failure, List<Agent>>> watchAgents() {
    return remoteDataSource.watchAgents()
        .map(
          (models) => Right<Failure, List<Agent>>(
            models.map((m) => m.toEntity()).toList(),
          ),
        )
        .transform(
          StreamTransformer.fromHandlers(
            handleError: (Object error, StackTrace stackTrace, EventSink<Either<Failure, List<Agent>>> sink) {
              if (error is ConnectionTimeoutException) {
                sink.add(Left(NetworkFailure(error.message, code: error.code)));
              } else if (error is GatewayException) {
                sink.add(Left(GatewayFailure(error.message, code: error.code)));
              } else {
                sink.add(Left(UnexpectedFailure('Unexpected error in watch stream')));
              }
            },
          ),
        );
  }
}
