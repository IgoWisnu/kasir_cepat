import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database_helper.dart';
import '../../data/datasources/product_local_datasource.dart';
import '../../data/repositories/product_repository_impl.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/usecases/delete_product.dart';
import '../../domain/usecases/get_products.dart';
import '../../domain/usecases/save_product.dart';

// 1. Database & Source Providers
final productDatabaseHelperProvider = Provider<DatabaseHelper>((ref) => DatabaseHelper.instance);

final productLocalDataSourceProvider = Provider<ProductLocalDataSource>((ref) {
  return ProductLocalDataSourceImpl(ref.watch(productDatabaseHelperProvider));
});

// 2. Repository Provider
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepositoryImpl(ref.watch(productLocalDataSourceProvider));
});

// 3. Use Case Providers
final getProductsUseCaseProvider = Provider<GetProducts>((ref) {
  return GetProducts(ref.watch(productRepositoryProvider));
});

final saveProductUseCaseProvider = Provider<SaveProduct>((ref) {
  return SaveProduct(ref.watch(productRepositoryProvider));
});

final deleteProductUseCaseProvider = Provider<DeleteProduct>((ref) {
  return DeleteProduct(ref.watch(productRepositoryProvider));
});

// 4. State Notifier managing the List of Products
class ProductListNotifier extends StateNotifier<AsyncValue<List<Product>>> {
  final GetProducts getProducts;
  final SaveProduct saveProduct;
  final DeleteProduct deleteProduct;
  int? _currentCategoryIdFilter;

  ProductListNotifier({
    required this.getProducts,
    required this.saveProduct,
    required this.deleteProduct,
  }) : super(const AsyncValue.loading()) {
    loadProducts();
  }

  /// Reloads all products from the database, optionally filtered by category.
  Future<void> loadProducts({int? categoryId}) async {
    _currentCategoryIdFilter = categoryId;
    state = const AsyncValue.loading();
    final result = await getProducts(GetProductsParams(categoryId: categoryId));
    result.fold(
      (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
      (products) => state = AsyncValue.data(products),
    );
  }

  /// Saves a product (insert or update). Returns true on success.
  Future<bool> saveProductProfile(Product product) async {
    final result = await saveProduct(product);
    return result.fold(
      (failure) => false,
      (savedId) {
        loadProducts(categoryId: _currentCategoryIdFilter); // Reactive reload list
        return true;
      },
    );
  }

  /// Deletes a product by its ID. Returns true on success.
  Future<bool> deleteProductProfile(int id) async {
    final result = await deleteProduct(id);
    return result.fold(
      (failure) => false,
      (success) {
        loadProducts(categoryId: _currentCategoryIdFilter); // Reactive reload list
        return true;
      },
    );
  }
}

// 5. Global Product List Provider
final productListProvider = StateNotifierProvider<ProductListNotifier, AsyncValue<List<Product>>>((ref) {
  return ProductListNotifier(
    getProducts: ref.watch(getProductsUseCaseProvider),
    saveProduct: ref.watch(saveProductUseCaseProvider),
    deleteProduct: ref.watch(deleteProductUseCaseProvider),
  );
});
