import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../user/domain/entities/user.dart';
import '../../data/datasources/auth_local_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/get_active_cashiers.dart';
import '../../domain/usecases/login_with_pin.dart';
import '../../domain/usecases/skip_first_time_pin.dart';
import '../../domain/usecases/update_first_time_pin.dart';

// 1. Data Source Provider
final authLocalDataSourceProvider = Provider<AuthLocalDataSource>((ref) {
  return AuthLocalDataSourceImpl(DatabaseHelper.instance);
});

// 2. Repository Provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(authLocalDataSourceProvider));
});

// 3. Usecase Providers
final getActiveCashiersUseCaseProvider = Provider<GetActiveCashiers>((ref) {
  return GetActiveCashiers(ref.watch(authRepositoryProvider));
});

final loginWithPinUseCaseProvider = Provider<LoginWithPin>((ref) {
  return LoginWithPin(ref.watch(authRepositoryProvider));
});

final updateFirstTimePinUseCaseProvider = Provider<UpdateFirstTimePin>((ref) {
  return UpdateFirstTimePin(ref.watch(authRepositoryProvider));
});

final skipFirstTimePinUseCaseProvider = Provider<SkipFirstTimePin>((ref) {
  return SkipFirstTimePin(ref.watch(authRepositoryProvider));
});

// 4. Reactive Active Cashiers List Provider (for login selection view)
final loginCashiersProvider = FutureProvider<List<User>>((ref) async {
  final usecase = ref.watch(getActiveCashiersUseCaseProvider);
  final result = await usecase(NoParams());
  return result.fold(
    (failure) => throw failure.message,
    (users) => users,
  );
});

// 5. Active Session State
class ActiveUserState extends StateNotifier<User?> {
  ActiveUserState() : super(null);

  void setUser(User user) {
    state = user;
  }

  void clearUser() {
    state = null;
  }
}

final activeUserProvider = StateNotifierProvider<ActiveUserState, User?>((ref) {
  return ActiveUserState();
});
