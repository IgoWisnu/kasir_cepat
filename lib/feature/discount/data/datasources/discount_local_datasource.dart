import '../../../../core/database/database_helper.dart';
import '../models/discount_model.dart';

abstract class DiscountLocalDataSource {
  /// Fetches all discounts from the local database.
  Future<List<DiscountModel>> getDiscounts();

  /// Saves (inserts or updates) a discount in the local database.
  Future<int> saveDiscount(DiscountModel discount);

  /// Deletes a discount from the local database.
  Future<void> deleteDiscount(int id);
}

class DiscountLocalDataSourceImpl implements DiscountLocalDataSource {
  final DatabaseHelper databaseHelper;

  DiscountLocalDataSourceImpl(this.databaseHelper);

  @override
  Future<List<DiscountModel>> getDiscounts() async {
    final db = await databaseHelper.database;
    final results = await db.query('discounts', orderBy: 'name ASC');
    return results.map((map) => DiscountModel.fromMap(map)).toList();
  }

  @override
  Future<int> saveDiscount(DiscountModel discount) async {
    final db = await databaseHelper.database;
    if (discount.id != null) {
      await db.update(
        'discounts',
        discount.toMap(),
        where: 'id = ?',
        whereArgs: [discount.id],
      );
      return discount.id!;
    } else {
      return await db.insert('discounts', discount.toMap());
    }
  }

  @override
  Future<void> deleteDiscount(int id) async {
    final db = await databaseHelper.database;
    await db.delete(
      'discounts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
