import '../../../../core/database/database_helper.dart';
import '../models/business_model.dart';

abstract class BusinessLocalDataSource {
  /// Retrieves the current business profile.
  /// Returns `null` if no profile exists.
  Future<BusinessModel?> getBusiness();

  /// Saves the business profile. If a profile already exists,
  /// it updates the existing record instead of creating a duplicate.
  Future<int> saveBusiness(BusinessModel business);

  /// Deletes the business profile with the specified [id].
  Future<void> deleteBusiness(int id);
}

class BusinessLocalDataSourceImpl implements BusinessLocalDataSource {
  final DatabaseHelper databaseHelper;

  BusinessLocalDataSourceImpl(this.databaseHelper);

  @override
  Future<BusinessModel?> getBusiness() async {
    final db = await databaseHelper.database;
    final results = await db.query('businesses', limit: 1);
    
    if (results.isEmpty) {
      return null;
    }
    return BusinessModel.fromMap(results.first);
  }

  @override
  Future<int> saveBusiness(BusinessModel business) async {
    final db = await databaseHelper.database;
    
    if (business.id != null) {
      await db.update(
        'businesses',
        business.toMap(),
        where: 'id = ?',
        whereArgs: [business.id],
      );
      return business.id!;
    } else {
      // Check if a business profile already exists in the database
      final existing = await db.query('businesses', limit: 1);
      if (existing.isNotEmpty) {
        final existingId = existing.first['id'] as int;
        // Merge the business details with the existing ID
        final modelToSave = BusinessModel(
          id: existingId,
          name: business.name,
          email: business.email,
          phone: business.phone,
          address: business.address,
          logo: business.logo,
          taxRate: business.taxRate,
          footerMessage: business.footerMessage,
          createdAt: business.createdAt,
        );
        await db.update(
          'businesses',
          modelToSave.toMap(),
          where: 'id = ?',
          whereArgs: [existingId],
        );
        return existingId;
      } else {
        // Insert as new record
        return await db.insert('businesses', business.toMap());
      }
    }
  }

  @override
  Future<void> deleteBusiness(int id) async {
    final db = await databaseHelper.database;
    await db.delete(
      'businesses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
