import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../entities/agent.dart';

/// Repository for managing agent entities.
abstract class AgentRepository {
  /// Retrieves all registered agents.
  Future<Either<Failure, List<Agent>>> getAgents();

  /// Retrieves a single agent by its unique id.
  Future<Either<Failure, Agent>> getAgentById(String id);

  /// Updates the autonomy level for the given agent.
  Future<Either<Failure, void>> updateAutonomy(String id, AutonomyLevel level);

  /// Toggles the active state of the given agent.
  Future<Either<Failure, void>> toggleActive(String id, bool active);

  /// Watches for real-time agent updates from the gateway.
  Stream<Either<Failure, List<Agent>>> watchAgents();
}
