import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/usecase/usecase.dart';
import '../../data/datasources/business_local_datasource.dart';
import '../../data/repositories/business_repository_impl.dart';
import '../../domain/entities/business.dart';
import '../../domain/repositories/business_repository.dart';
import '../../domain/usecases/delete_business.dart';
import '../../domain/usecases/get_business.dart';
import '../../domain/usecases/save_business.dart';

// 1. Core Database Provider
final databaseHelperProvider = Provider<DatabaseHelper>((ref) => DatabaseHelper.instance);

// 2. Data Source Provider
final businessLocalDataSourceProvider = Provider<BusinessLocalDataSource>((ref) {
  return BusinessLocalDataSourceImpl(ref.watch(databaseHelperProvider));
});

// 3. Repository Provider
final businessRepositoryProvider = Provider<BusinessRepository>((ref) {
  return BusinessRepositoryImpl(ref.watch(businessLocalDataSourceProvider));
});

// 4. Use Case Providers
final getBusinessUseCaseProvider = Provider<GetBusiness>((ref) {
  return GetBusiness(ref.watch(businessRepositoryProvider));
});

final saveBusinessUseCaseProvider = Provider<SaveBusiness>((ref) {
  return SaveBusiness(ref.watch(businessRepositoryProvider));
});

final deleteBusinessUseCaseProvider = Provider<DeleteBusiness>((ref) {
  return DeleteBusiness(ref.watch(businessRepositoryProvider));
});

// 5. State Notifier managing Business Profile state
class BusinessNotifier extends StateNotifier<AsyncValue<Business?>> {
  final GetBusiness getBusiness;
  final SaveBusiness saveBusiness;
  final DeleteBusiness deleteBusiness;

  BusinessNotifier({
    required this.getBusiness,
    required this.saveBusiness,
    required this.deleteBusiness,
  }) : super(const AsyncValue.loading()) {
    loadBusiness();
  }

  /// Fetches the business details from SQLite.
  Future<void> loadBusiness() async {
    state = const AsyncValue.loading();
    final result = await getBusiness(NoParams());
    result.fold(
      (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
      (business) => state = AsyncValue.data(business),
    );
  }

  /// Saves the business profile details. Returns true on success, false on failure.
  Future<bool> saveBusinessProfile(Business business) async {
    final result = await saveBusiness(business);
    return result.fold(
      (failure) => false,
      (savedId) {
        loadBusiness(); // Refresh active profile cache
        return true;
      },
    );
  }
}

// 6. Global Business State Provider
final businessStateProvider = StateNotifierProvider<BusinessNotifier, AsyncValue<Business?>>((ref) {
  return BusinessNotifier(
    getBusiness: ref.watch(getBusinessUseCaseProvider),
    saveBusiness: ref.watch(saveBusinessUseCaseProvider),
    deleteBusiness: ref.watch(deleteBusinessUseCaseProvider),
  );
});
