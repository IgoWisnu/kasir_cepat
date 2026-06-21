import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/usecase/usecase.dart';
import '../../data/datasources/unit_local_datasource.dart';
import '../../data/repositories/unit_repository_impl.dart';
import '../../domain/entities/unit_entity.dart';
import '../../domain/repositories/unit_repository.dart';
import '../../domain/usecases/delete_unit.dart';
import '../../domain/usecases/get_units.dart';
import '../../domain/usecases/save_unit.dart';

// 1. Database & Source Providers
final unitDatabaseHelperProvider = Provider<DatabaseHelper>((ref) => DatabaseHelper.instance);

final unitLocalDataSourceProvider = Provider<UnitLocalDataSource>((ref) {
  return UnitLocalDataSourceImpl(ref.watch(unitDatabaseHelperProvider));
});

// 2. Repository Provider
final unitRepositoryProvider = Provider<UnitRepository>((ref) {
  return UnitRepositoryImpl(ref.watch(unitLocalDataSourceProvider));
});

// 3. Use Case Providers
final getUnitsUseCaseProvider = Provider<GetUnits>((ref) {
  return GetUnits(ref.watch(unitRepositoryProvider));
});

final saveUnitUseCaseProvider = Provider<SaveUnit>((ref) {
  return SaveUnit(ref.watch(unitRepositoryProvider));
});

final deleteUnitUseCaseProvider = Provider<DeleteUnit>((ref) {
  return DeleteUnit(ref.watch(unitRepositoryProvider));
});

// 4. State Notifier managing the List of Units
class UnitListNotifier extends StateNotifier<AsyncValue<List<Unit>>> {
  final GetUnits getUnits;
  final SaveUnit saveUnit;
  final DeleteUnit deleteUnit;

  UnitListNotifier({
    required this.getUnits,
    required this.saveUnit,
    required this.deleteUnit,
  }) : super(const AsyncValue.loading()) {
    loadUnits();
  }

  /// Reloads all units from the database.
  Future<void> loadUnits() async {
    state = const AsyncValue.loading();
    final result = await getUnits(NoParams());
    result.fold(
      (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
      (units) => state = AsyncValue.data(units),
    );
  }

  /// Saves a unit (insert or update). Returns true on success.
  Future<bool> saveUnitProfile(Unit unit) async {
    final result = await saveUnit(unit);
    return result.fold(
      (failure) => false,
      (savedId) {
        loadUnits(); // Reactive reload list
        return true;
      },
    );
  }

  /// Deletes a unit by its ID. Returns true on success.
  Future<bool> deleteUnitProfile(int id) async {
    final result = await deleteUnit(id);
    return result.fold(
      (failure) => false,
      (success) {
        loadUnits(); // Reactive reload list
        return true;
      },
    );
  }
}

// 5. Global Unit List Provider
final unitListProvider = StateNotifierProvider<UnitListNotifier, AsyncValue<List<Unit>>>((ref) {
  return UnitListNotifier(
    getUnits: ref.watch(getUnitsUseCaseProvider),
    saveUnit: ref.watch(saveUnitUseCaseProvider),
    deleteUnit: ref.watch(deleteUnitUseCaseProvider),
  );
});
