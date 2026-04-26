import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../entities/session.dart';

abstract class SessionRepository {
  Future<Either<Failure, List<Session>>> getSessions();
  Future<Either<Failure, Session>> getSessionById(String id);
  Future<Either<Failure, Session>> createSession({String? title, String? agentId});
  Future<Either<Failure, void>> pinSession(String id, bool pinned);
  Future<Either<Failure, void>> archiveSession(String id);
  Stream<Either<Failure, List<Session>>> watchSessions();
}
