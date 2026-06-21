import 'package:dartz/dartz.dart' hide Unit;
import '../../../../core/errors/failures.dart';
import '../entities/unit_entity.dart';

abstract class UnitRepository {
  /// Fetches all stored quantity units.
  Future<Either<Failure, List<Unit>>> getUnits();

  /// Saves (creates or updates) a quantity unit.
  /// Returns the ID of the saved unit.
  Future<Either<Failure, int>> saveUnit(Unit unit);

  /// Deletes the quantity unit with the specified ID.
  Future<Either<Failure, void>> deleteUnit(int id);
}
