import '../../../../core/database/database_helper.dart';
import '../models/category_model.dart';

abstract class CategoryLocalDataSource {
  /// Fetches all categories from the local database.
  Future<List<CategoryModel>> getCategories();

  /// Saves (inserts or updates) a category in the local database.
  Future<int> saveCategory(CategoryModel category);

  /// Deletes a category from the local database.
  Future<void> deleteCategory(int id);
}

class CategoryLocalDataSourceImpl implements CategoryLocalDataSource {
  final DatabaseHelper databaseHelper;

  CategoryLocalDataSourceImpl(this.databaseHelper);

  @override
  Future<List<CategoryModel>> getCategories() async {
    final db = await databaseHelper.database;
    final results = await db.query('categories', orderBy: 'name ASC');
    return results.map((map) => CategoryModel.fromMap(map)).toList();
  }

  @override
  Future<int> saveCategory(CategoryModel category) async {
    final db = await databaseHelper.database;
    if (category.id != null) {
      await db.update(
        'categories',
        category.toMap(),
        where: 'id = ?',
        whereArgs: [category.id],
      );
      return category.id!;
    } else {
      return await db.insert('categories', category.toMap());
    }
  }

  @override
  Future<void> deleteCategory(int id) async {
    final db = await databaseHelper.database;
    await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
