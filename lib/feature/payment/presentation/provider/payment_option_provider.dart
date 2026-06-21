import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database_helper.dart';
import '../../data/datasources/payment_option_local_datasource.dart';
import '../../data/repositories/payment_option_repository_impl.dart';
import '../../domain/entities/payment_option.dart';
import '../../domain/repositories/payment_option_repository.dart';
import '../../domain/usecases/delete_payment_option.dart';
import '../../domain/usecases/get_payment_options.dart';
import '../../domain/usecases/save_payment_option.dart';

// 1. Database & Source Providers
final paymentOptionDatabaseHelperProvider = Provider<DatabaseHelper>((ref) => DatabaseHelper.instance);

final paymentOptionLocalDataSourceProvider = Provider<PaymentOptionLocalDataSource>((ref) {
  return PaymentOptionLocalDataSourceImpl(ref.watch(paymentOptionDatabaseHelperProvider));
});

// 2. Repository Provider
final paymentOptionRepositoryProvider = Provider<PaymentOptionRepository>((ref) {
  return PaymentOptionRepositoryImpl(ref.watch(paymentOptionLocalDataSourceProvider));
});

// 3. Use Case Providers
final getPaymentOptionsUseCaseProvider = Provider<GetPaymentOptions>((ref) {
  return GetPaymentOptions(ref.watch(paymentOptionRepositoryProvider));
});

final savePaymentOptionUseCaseProvider = Provider<SavePaymentOption>((ref) {
  return SavePaymentOption(ref.watch(paymentOptionRepositoryProvider));
});

final deletePaymentOptionUseCaseProvider = Provider<DeletePaymentOption>((ref) {
  return DeletePaymentOption(ref.watch(paymentOptionRepositoryProvider));
});

// 4. State Notifier managing the List of Payment Options
class PaymentOptionListNotifier extends StateNotifier<AsyncValue<List<PaymentOption>>> {
  final GetPaymentOptions getPaymentOptions;
  final SavePaymentOption savePaymentOption;
  final DeletePaymentOption deletePaymentOption;
  bool? _currentOnlyActiveFilter;

  PaymentOptionListNotifier({
    required this.getPaymentOptions,
    required this.savePaymentOption,
    required this.deletePaymentOption,
  }) : super(const AsyncValue.loading()) {
    loadPaymentOptions();
  }

  /// Reloads all payment options from the database.
  Future<void> loadPaymentOptions({bool? onlyActive}) async {
    _currentOnlyActiveFilter = onlyActive;
    state = const AsyncValue.loading();
    final result = await getPaymentOptions(GetPaymentOptionsParams(onlyActive: onlyActive));
    result.fold(
      (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
      (options) => state = AsyncValue.data(options),
    );
  }

  /// Saves a payment option (insert or update). Returns true on success.
  Future<bool> saveOption(PaymentOption option) async {
    final result = await savePaymentOption(option);
    return result.fold(
      (failure) => false,
      (savedId) {
        loadPaymentOptions(onlyActive: _currentOnlyActiveFilter); // Reactive reload list
        return true;
      },
    );
  }

  /// Deletes a payment option by its ID. Returns true on success.
  Future<bool> deleteOption(int id) async {
    final result = await deletePaymentOption(id);
    return result.fold(
      (failure) => false,
      (success) {
        loadPaymentOptions(onlyActive: _currentOnlyActiveFilter); // Reactive reload list
        return true;
      },
    );
  }
}

// 5. Global Payment Option List Provider
final paymentOptionListProvider = StateNotifierProvider<PaymentOptionListNotifier, AsyncValue<List<PaymentOption>>>((ref) {
  return PaymentOptionListNotifier(
    getPaymentOptions: ref.watch(getPaymentOptionsUseCaseProvider),
    savePaymentOption: ref.watch(savePaymentOptionUseCaseProvider),
    deletePaymentOption: ref.watch(deletePaymentOptionUseCaseProvider),
  );
});
