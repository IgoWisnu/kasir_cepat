import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/usecase/usecase.dart';
import '../../data/datasources/user_local_datasource.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../../domain/usecases/delete_user.dart';
import '../../domain/usecases/get_users.dart';
import '../../domain/usecases/save_user.dart';

// 1. Source & Database Providers
final userDatabaseHelperProvider = Provider<DatabaseHelper>((ref) => DatabaseHelper.instance);

final userLocalDataSourceProvider = Provider<UserLocalDataSource>((ref) {
  return UserLocalDataSourceImpl(ref.watch(userDatabaseHelperProvider));
});

// 2. Repository Provider
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepositoryImpl(ref.watch(userLocalDataSourceProvider));
});

// 3. Use Case Providers
final getUsersUseCaseProvider = Provider<GetUsers>((ref) {
  return GetUsers(ref.watch(userRepositoryProvider));
});

final saveUserUseCaseProvider = Provider<SaveUser>((ref) {
  return SaveUser(ref.watch(userRepositoryProvider));
});

final deleteUserUseCaseProvider = Provider<DeleteUser>((ref) {
  return DeleteUser(ref.watch(userRepositoryProvider));
});

// 4. State Notifier managing the List of Users
class UserListNotifier extends StateNotifier<AsyncValue<List<User>>> {
  final GetUsers getUsers;
  final SaveUser saveUser;
  final DeleteUser deleteUser;

  UserListNotifier({
    required this.getUsers,
    required this.saveUser,
    required this.deleteUser,
  }) : super(const AsyncValue.loading()) {
    loadUsers();
  }

  /// Loads all users/cashiers from the database
  Future<void> loadUsers() async {
    state = const AsyncValue.loading();
    final result = await getUsers(NoParams());
    result.fold(
      (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
      (users) => state = AsyncValue.data(users),
    );
  }

  /// Saves a user (insert/update). Enforces permissions & single-owner validation inside usecase.
  /// Returns Either a string error message on failure or null on success.
  Future<String?> saveUserProfile({
    required User userToSave,
    required User currentUser,
  }) async {
    final result = await saveUser(SaveUserParams(
      user: userToSave,
      currentUser: currentUser,
    ));

    return result.fold(
      (failure) => failure.message,
      (savedId) {
        loadUsers(); // Refresh reactive user list
        return null; // success
      },
    );
  }

  /// Deletes a user by their ID. Enforces permissions & self-deletion check inside usecase.
  /// Returns Either a string error message on failure or null on success.
  Future<String?> deleteUserProfile({
    required int idToDelete,
    required User currentUser,
  }) async {
    final result = await deleteUser(DeleteUserParams(
      userIdToDelete: idToDelete,
      currentUser: currentUser,
    ));

    return result.fold(
      (failure) => failure.message,
      (_) {
        loadUsers(); // Refresh reactive user list
        return null; // success
      },
    );
  }
}

// 5. Global User List Provider
final userListProvider = StateNotifierProvider<UserListNotifier, AsyncValue<List<User>>>((ref) {
  return UserListNotifier(
    getUsers: ref.watch(getUsersUseCaseProvider),
    saveUser: ref.watch(saveUserUseCaseProvider),
    deleteUser: ref.watch(deleteUserUseCaseProvider),
  );
});
