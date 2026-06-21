import '../../../../core/database/database_helper.dart';
import '../models/payment_option_model.dart';

abstract class PaymentOptionLocalDataSource {
  /// Fetches all payment options from the SQLite database.
  Future<List<PaymentOptionModel>> getPaymentOptions({bool? onlyActive});

  /// Inserts or updates a payment option.
  Future<int> savePaymentOption(PaymentOptionModel option);

  /// Deletes a payment option by ID.
  Future<void> deletePaymentOption(int id);
}

class PaymentOptionLocalDataSourceImpl implements PaymentOptionLocalDataSource {
  final DatabaseHelper databaseHelper;

  PaymentOptionLocalDataSourceImpl(this.databaseHelper);

  @override
  Future<List<PaymentOptionModel>> getPaymentOptions({bool? onlyActive}) async {
    final db = await databaseHelper.database;
    
    final whereClause = onlyActive == true ? "status = 'active'" : null;
    
    final results = await db.query(
      'payment_options',
      where: whereClause,
      orderBy: 'name ASC',
    );
    
    return results.map((map) => PaymentOptionModel.fromMap(map)).toList();
  }

  @override
  Future<int> savePaymentOption(PaymentOptionModel option) async {
    final db = await databaseHelper.database;
    final map = option.toMap();

    if (option.id != null) {
      await db.update(
        'payment_options',
        map,
        where: 'id = ?',
        whereArgs: [option.id],
      );
      return option.id!;
    } else {
      return await db.insert('payment_options', map);
    }
  }

  @override
  Future<void> deletePaymentOption(int id) async {
    final db = await databaseHelper.database;
    await db.delete(
      'payment_options',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
