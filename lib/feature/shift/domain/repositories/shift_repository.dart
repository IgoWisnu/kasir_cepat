import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/shift.dart';

abstract class ShiftRepository {
  /// Starts a new shift with the starting cash amount.
  Future<Either<Failure, int>> startShift({
    required double cashStart,
    int? userId,
    String? notes,
  });

  /// Closes the active shift with the closing cash amount.
  Future<Either<Failure, void>> closeShift({
    required int shiftId,
    required double cashEnd,
    String? notes,
  });

  /// Gets the currently open active shift, if any.
  Future<Either<Failure, Shift?>> getActiveShift();

  /// Fetches all shifts history.
  Future<Either<Failure, List<Shift>>> getShifts();

  /// Fetches a specific shift by its ID.
  Future<Either<Failure, Shift?>> getShiftById(int id);

  /// Gets the sum of cash sales completed during a shift.
  Future<Either<Failure, double>> getShiftCashSales(int shiftId);
}
