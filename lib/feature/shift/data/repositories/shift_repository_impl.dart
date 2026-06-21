import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/shift.dart';
import '../../domain/repositories/shift_repository.dart';
import '../datasources/shift_local_datasource.dart';
import '../models/shift_model.dart';

class ShiftRepositoryImpl implements ShiftRepository {
  final ShiftLocalDataSource localDataSource;

  ShiftRepositoryImpl(this.localDataSource);

  @override
  Future<Either<Failure, int>> startShift({
    required double cashStart,
    int? userId,
    String? notes,
  }) async {
    try {
      // Check if there is an active open shift
      final active = await localDataSource.getActiveShift();
      if (active != null) {
        return Left(CacheFailure('Terdapat shift yang sedang aktif. Silakan tutup shift terlebih dahulu.'));
      }

      final shift = ShiftModel(
        startTime: DateTime.now(),
        status: ShiftStatus.open,
        userId: userId,
        cashStart: cashStart,
        notes: notes,
      );

      final id = await localDataSource.startShift(shift);
      return Right(id);
    } catch (e) {
      return Left(CacheFailure('Gagal memulai shift: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> closeShift({
    required int shiftId,
    required double cashEnd,
    String? notes,
  }) async {
    try {
      final active = await localDataSource.getShiftById(shiftId);
      if (active == null) {
        return Left(CacheFailure('Shift tidak ditemukan.'));
      }
      if (active.status == ShiftStatus.closed) {
        return Left(CacheFailure('Shift sudah ditutup.'));
      }

      // Calculate cash sales under this shift to get cash_different
      final cashSales = await localDataSource.getShiftCashSales(shiftId);
      final expectedCash = active.cashStart + cashSales;
      final cashDifferent = cashEnd - expectedCash;

      final updatedShift = ShiftModel.fromEntity(active).copyWith(
        endTime: DateTime.now(),
        status: ShiftStatus.closed,
        cashEnd: cashEnd,
        cashDifferent: cashDifferent,
        notes: notes,
      );

      await localDataSource.updateShift(updatedShift);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Gagal menutup shift: $e'));
    }
  }

  @override
  Future<Either<Failure, Shift?>> getActiveShift() async {
    try {
      final model = await localDataSource.getActiveShift();
      return Right(model?.toEntity());
    } catch (e) {
      return Left(CacheFailure('Gagal mengambil shift aktif: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Shift>>> getShifts() async {
    try {
      final models = await localDataSource.getShifts();
      final entities = models.map((model) => model.toEntity()).toList();
      return Right(entities);
    } catch (e) {
      return Left(CacheFailure('Gagal mengambil riwayat shift: $e'));
    }
  }

  @override
  Future<Either<Failure, Shift?>> getShiftById(int id) async {
    try {
      final model = await localDataSource.getShiftById(id);
      return Right(model?.toEntity());
    } catch (e) {
      return Left(CacheFailure('Gagal mengambil shift dengan id $id: $e'));
    }
  }

  @override
  Future<Either<Failure, double>> getShiftCashSales(int shiftId) async {
    try {
      final total = await localDataSource.getShiftCashSales(shiftId);
      return Right(total);
    } catch (e) {
      return Left(CacheFailure('Gagal menghitung penjualan tunai shift: $e'));
    }
  }
}
