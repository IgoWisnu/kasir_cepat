import '../../../../core/database/database_helper.dart';
import '../models/product_model.dart';

abstract class ProductLocalDataSource {
  /// Fetches all products, optionally filtered by category.
  Future<List<ProductModel>> getProducts({int? categoryId});

  /// Fetches a specific product by its ID.
  Future<ProductModel?> getProductById(int id);

  /// Saves (inserts or updates) a product in the local database.
  Future<int> saveProduct(ProductModel product);

  /// Deletes a product from the local database.
  Future<void> deleteProduct(int id);
}

class ProductLocalDataSourceImpl implements ProductLocalDataSource {
  final DatabaseHelper databaseHelper;

  ProductLocalDataSourceImpl(this.databaseHelper);

  @override
  Future<List<ProductModel>> getProducts({int? categoryId}) async {
    final db = await databaseHelper.database;
    
    String query = '''
      SELECT p.*, c.name AS category_name, u.abbreviation AS unit_abbreviation
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
      LEFT JOIN units u ON p.unit_id = u.id
    ''';
    
    List<dynamic> arguments = [];
    if (categoryId != null) {
      query += ' WHERE p.category_id = ?';
      arguments.add(categoryId);
    }
    
    query += ' ORDER BY p.name ASC';
    
    final results = await db.rawQuery(query, arguments);
    return results.map((map) => ProductModel.fromMap(map)).toList();
  }

  @override
  Future<ProductModel?> getProductById(int id) async {
    final db = await databaseHelper.database;
    
    final query = '''
      SELECT p.*, c.name AS category_name, u.abbreviation AS unit_abbreviation
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
      LEFT JOIN units u ON p.unit_id = u.id
      WHERE p.id = ?
      LIMIT 1
    ''';
    
    final results = await db.rawQuery(query, [id]);
    if (results.isNotEmpty) {
      return ProductModel.fromMap(results.first);
    }
    return null;
  }

  @override
  Future<int> saveProduct(ProductModel product) async {
    final db = await databaseHelper.database;
    final map = product.toMap();
    
    if (product.id != null) {
      await db.update(
        'products',
        map,
        where: 'id = ?',
        whereArgs: [product.id],
      );
      return product.id!;
    } else {
      return await db.insert('products', map);
    }
  }

  @override
  Future<void> deleteProduct(int id) async {
    final db = await databaseHelper.database;
    await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
