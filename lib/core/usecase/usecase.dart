import 'package:dartz/dartz.dart';
import '../errors/failures.dart';

/// Base class for all UseCases in Clean Architecture.
///
/// [Type] is what the UseCase returns on success.
/// [Params] is the parameter class passed to the UseCase. Use [NoParams] if no params are needed.
abstract class UseCase<T, Params> {
  Future<Either<Failure, T>> call(Params params);
}

/// Helper class for UseCases that don't accept any parameters.
class NoParams {}
