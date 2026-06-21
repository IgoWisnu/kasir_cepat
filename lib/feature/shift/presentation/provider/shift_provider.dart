import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/shift.dart';
import '../../domain/usecases/start_shift.dart';
import '../../domain/usecases/close_shift.dart';
import '../../domain/usecases/get_active_shift.dart';
import '../../domain/usecases/get_shifts.dart';
import '../../domain/usecases/get_shift_cash_sales.dart';
import '../../domain/repositories/shift_repository.dart';
import '../../data/repositories/shift_repository_impl.dart';
import '../../data/datasources/shift_local_datasource.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/usecase/usecase.dart';

// Providers for repository and data sources
final shiftLocalDataSourceProvider = Provider<ShiftLocalDataSource>((ref) {
  return ShiftLocalDataSourceImpl(DatabaseHelper.instance);
});

final shiftRepositoryProvider = Provider<ShiftRepository>((ref) {
  return ShiftRepositoryImpl(ref.read(shiftLocalDataSourceProvider));
});

// Providers for usecases
final startShiftUseCaseProvider = Provider<StartShift>((ref) {
  return StartShift(ref.read(shiftRepositoryProvider));
});

final closeShiftUseCaseProvider = Provider<CloseShift>((ref) {
  return CloseShift(ref.read(shiftRepositoryProvider));
});

final getActiveShiftUseCaseProvider = Provider<GetActiveShift>((ref) {
  return GetActiveShift(ref.read(shiftRepositoryProvider));
});

final getShiftsUseCaseProvider = Provider<GetShifts>((ref) {
  return GetShifts(ref.read(shiftRepositoryProvider));
});

final getShiftCashSalesUseCaseProvider = Provider<GetShiftCashSales>((ref) {
  return GetShiftCashSales(ref.read(shiftRepositoryProvider));
});

final openShiftPromptedProvider = StateProvider<bool>((ref) => false);


// Shift notifier to hold active shift state
class ShiftNotifier extends StateNotifier<AsyncValue<Shift?>> {
  final GetActiveShift getActiveShiftUseCase;
  final StartShift startShiftUseCase;
  final CloseShift closeShiftUseCase;

  ShiftNotifier({
    required this.getActiveShiftUseCase,
    required this.startShiftUseCase,
    required this.closeShiftUseCase,
  }) : super(const AsyncValue.loading()) {
    loadActiveShift();
  }

  Future<void> loadActiveShift() async {
    state = const AsyncValue.loading();
    final result = await getActiveShiftUseCase(NoParams());
    result.fold(
      (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
      (shift) => state = AsyncValue.data(shift),
    );
  }

  Future<bool> startNewShift({
    required double cashStart,
    int? userId,
    String? notes,
  }) async {
    final result = await startShiftUseCase(StartShiftParams(
      cashStart: cashStart,
      userId: userId,
      notes: notes,
    ));

    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return false;
      },
      (id) async {
        await loadActiveShift();
        return true;
      },
    );
  }

  Future<bool> closeActiveShift({
    required int shiftId,
    required double cashEnd,
    String? notes,
  }) async {
    final result = await closeShiftUseCase(CloseShiftParams(
      shiftId: shiftId,
      cashEnd: cashEnd,
      notes: notes,
    ));

    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return false;
      },
      (_) async {
        await loadActiveShift();
        return true;
      },
    );
  }
}

final shiftProvider = StateNotifierProvider<ShiftNotifier, AsyncValue<Shift?>>((ref) {
  return ShiftNotifier(
    getActiveShiftUseCase: ref.read(getActiveShiftUseCaseProvider),
    startShiftUseCase: ref.read(startShiftUseCaseProvider),
    closeShiftUseCase: ref.read(closeShiftUseCaseProvider),
  );
});
