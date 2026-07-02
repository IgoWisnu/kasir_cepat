import '../../../../core/database/database_helper.dart';
import '../../../user/data/models/user_model.dart';

abstract class AuthLocalDataSource {
  /// Queries active cashier users from the database.
  Future<List<UserModel>> getActiveCashiers();

  /// Updates user PIN and sets is_first_login to 0.
  Future<void> updatePin(int userId, String newPin);

  /// Just sets is_first_login to 0 without modifying the PIN.
  Future<void> clearFirstLoginFlag(int userId);
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final DatabaseHelper databaseHelper;

  AuthLocalDataSourceImpl(this.databaseHelper);

  @override
  Future<List<UserModel>> getActiveCashiers() async {
    final db = await databaseHelper.database;
    final results = await db.query(
      'users',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'name ASC',
    );
    return results.map((map) => UserModel.fromMap(map)).toList();
  }

  @override
  Future<void> updatePin(int userId, String newPin) async {
    final db = await databaseHelper.database;
    await db.update(
      'users',
      {
        'pin': newPin,
        'is_first_login': 0,
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  @override
  Future<void> clearFirstLoginFlag(int userId) async {
    final db = await databaseHelper.database;
    await db.update(
      'users',
      {
        'is_first_login': 0,
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }
}
