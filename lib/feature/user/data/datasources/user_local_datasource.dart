import '../../../../core/database/database_helper.dart';
import '../models/user_model.dart';

abstract class UserLocalDataSource {
  /// Fetches all users from the local database.
  Future<List<UserModel>> getUsers();

  /// Fetches a specific user by ID.
  Future<UserModel?> getUserById(int id);

  /// Saves (inserts or updates) a user in the local database.
  Future<int> saveUser(UserModel user);

  /// Deletes a user from the local database.
  Future<void> deleteUser(int id);

  /// Fetches the user with role 'Admin' (Owner).
  Future<UserModel?> getOwner();
}

class UserLocalDataSourceImpl implements UserLocalDataSource {
  final DatabaseHelper databaseHelper;

  UserLocalDataSourceImpl(this.databaseHelper);

  @override
  Future<List<UserModel>> getUsers() async {
    final db = await databaseHelper.database;
    final results = await db.query('users', orderBy: 'name ASC');
    return results.map((map) => UserModel.fromMap(map)).toList();
  }

  @override
  Future<UserModel?> getUserById(int id) async {
    final db = await databaseHelper.database;
    final results = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isNotEmpty) {
      return UserModel.fromMap(results.first);
    }
    return null;
  }

  @override
  Future<int> saveUser(UserModel user) async {
    final db = await databaseHelper.database;
    final map = user.toMap();

    if (user.id != null) {
      await db.update(
        'users',
        map,
        where: 'id = ?',
        whereArgs: [user.id],
      );
      return user.id!;
    } else {
      return await db.insert('users', map);
    }
  }

  @override
  Future<void> deleteUser(int id) async {
    final db = await databaseHelper.database;
    await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<UserModel?> getOwner() async {
    final db = await databaseHelper.database;
    final results = await db.query(
      'users',
      where: 'role = ?',
      whereArgs: ['Admin'],
      limit: 1,
    );
    if (results.isNotEmpty) {
      return UserModel.fromMap(results.first);
    }
    return null;
  }
}
