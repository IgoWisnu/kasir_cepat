import '../../../../core/database/database_helper.dart';
import '../models/shift_model.dart';

abstract class ShiftLocalDataSource {
  Future<int> startShift(ShiftModel shift);
  Future<void> updateShift(ShiftModel shift);
  Future<ShiftModel?> getActiveShift();
  Future<List<ShiftModel>> getShifts();
  Future<ShiftModel?> getShiftById(int id);
  Future<double> getShiftCashSales(int shiftId);
}

class ShiftLocalDataSourceImpl implements ShiftLocalDataSource {
  final DatabaseHelper databaseHelper;

  ShiftLocalDataSourceImpl(this.databaseHelper);

  @override
  Future<int> startShift(ShiftModel shift) async {
    final db = await databaseHelper.database;
    return await db.insert('shifts', shift.toMap());
  }

  @override
  Future<void> updateShift(ShiftModel shift) async {
    final db = await databaseHelper.database;
    await db.update(
      'shifts',
      shift.toMap(),
      where: 'id = ?',
      whereArgs: [shift.id],
    );
  }

  @override
  Future<ShiftModel?> getActiveShift() async {
    final db = await databaseHelper.database;
    final results = await db.query(
      'shifts',
      where: 'status = ?',
      whereArgs: ['open'],
      limit: 1,
    );
    if (results.isNotEmpty) {
      return ShiftModel.fromMap(results.first);
    }
    return null;
  }

  @override
  Future<List<ShiftModel>> getShifts() async {
    final db = await databaseHelper.database;
    final results = await db.query(
      'shifts',
      orderBy: 'start_time DESC',
    );
    return results.map((map) => ShiftModel.fromMap(map)).toList();
  }

  @override
  Future<ShiftModel?> getShiftById(int id) async {
    final db = await databaseHelper.database;
    final results = await db.query(
      'shifts',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isNotEmpty) {
      return ShiftModel.fromMap(results.first);
    }
    return null;
  }

  @override
  Future<double> getShiftCashSales(int shiftId) async {
    final db = await databaseHelper.database;
    final result = await db.rawQuery('''
      SELECT SUM(o.grand_total) as total
      FROM orders o
      LEFT JOIN payment_options p ON o.payment_option_id = p.id
      WHERE o.shift_id = ? AND o.order_status = 'completed' AND (p.type = 'cash' OR o.payment_option_id IS NULL)
    ''', [shiftId]);
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }
}
