import '../../../../core/database/database_helper.dart';
import '../models/unit_model.dart';

abstract class UnitLocalDataSource {
  /// Fetches all units from the local database.
  Future<List<UnitModel>> getUnits();

  /// Saves (inserts or updates) a unit in the local database.
  Future<int> saveUnit(UnitModel unit);

  /// Deletes a unit from the local database.
  Future<void> deleteUnit(int id);
}

class UnitLocalDataSourceImpl implements UnitLocalDataSource {
  final DatabaseHelper databaseHelper;

  UnitLocalDataSourceImpl(this.databaseHelper);

  @override
  Future<List<UnitModel>> getUnits() async {
    final db = await databaseHelper.database;
    final results = await db.query('units', orderBy: 'name ASC');
    return results.map((map) => UnitModel.fromMap(map)).toList();
  }

  @override
  Future<int> saveUnit(UnitModel unit) async {
    final db = await databaseHelper.database;
    if (unit.id != null) {
      await db.update(
        'units',
        unit.toMap(),
        where: 'id = ?',
        whereArgs: [unit.id],
      );
      return unit.id!;
    } else {
      return await db.insert('units', unit.toMap());
    }
  }

  @override
  Future<void> deleteUnit(int id) async {
    final db = await databaseHelper.database;
    await db.delete(
      'units',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
