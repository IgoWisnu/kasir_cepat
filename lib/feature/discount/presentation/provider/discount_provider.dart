import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/usecase/usecase.dart';
import '../../data/datasources/discount_local_datasource.dart';
import '../../data/repositories/discount_repository_impl.dart';
import '../../domain/entities/discount.dart';
import '../../domain/repositories/discount_repository.dart';
import '../../domain/usecases/delete_discount.dart';
import '../../domain/usecases/get_discounts.dart';
import '../../domain/usecases/save_discount.dart';

// 1. Database & Source Providers
final discountDatabaseHelperProvider = Provider<DatabaseHelper>((ref) => DatabaseHelper.instance);

final discountLocalDataSourceProvider = Provider<DiscountLocalDataSource>((ref) {
  return DiscountLocalDataSourceImpl(ref.watch(discountDatabaseHelperProvider));
});

// 2. Repository Provider
final discountRepositoryProvider = Provider<DiscountRepository>((ref) {
  return DiscountRepositoryImpl(ref.watch(discountLocalDataSourceProvider));
});

// 3. Use Case Providers
final getDiscountsUseCaseProvider = Provider<GetDiscounts>((ref) {
  return GetDiscounts(ref.watch(discountRepositoryProvider));
});

final saveDiscountUseCaseProvider = Provider<SaveDiscount>((ref) {
  return SaveDiscount(ref.watch(discountRepositoryProvider));
});

final deleteDiscountUseCaseProvider = Provider<DeleteDiscount>((ref) {
  return DeleteDiscount(ref.watch(discountRepositoryProvider));
});

// 4. State Notifier managing the List of Discounts
class DiscountListNotifier extends StateNotifier<AsyncValue<List<Discount>>> {
  final GetDiscounts getDiscounts;
  final SaveDiscount saveDiscount;
  final DeleteDiscount deleteDiscount;

  DiscountListNotifier({
    required this.getDiscounts,
    required this.saveDiscount,
    required this.deleteDiscount,
  }) : super(const AsyncValue.loading()) {
    loadDiscounts();
  }

  /// Reloads all discounts from the database.
  Future<void> loadDiscounts() async {
    state = const AsyncValue.loading();
    final result = await getDiscounts(NoParams());
    result.fold(
      (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
      (discounts) => state = AsyncValue.data(discounts),
    );
  }

  /// Saves a discount (insert or update). Returns true on success.
  Future<bool> saveDiscountProfile(Discount discount) async {
    final result = await saveDiscount(discount);
    return result.fold(
      (failure) => false,
      (savedId) {
        loadDiscounts(); // Reactive reload list
        return true;
      },
    );
  }

  /// Deletes a discount by its ID. Returns true on success.
  Future<bool> deleteDiscountProfile(int id) async {
    final result = await deleteDiscount(id);
    return result.fold(
      (failure) => false,
      (success) {
        loadDiscounts(); // Reactive reload list
        return true;
      },
    );
  }
}

// 5. Global Discount List Provider
final discountListProvider = StateNotifierProvider<DiscountListNotifier, AsyncValue<List<Discount>>>((ref) {
  return DiscountListNotifier(
    getDiscounts: ref.watch(getDiscountsUseCaseProvider),
    saveDiscount: ref.watch(saveDiscountUseCaseProvider),
    deleteDiscount: ref.watch(deleteDiscountUseCaseProvider),
  );
});
