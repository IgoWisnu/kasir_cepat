import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/usecase/usecase.dart';
import '../../data/datasources/category_local_datasource.dart';
import '../../data/repositories/category_repository_impl.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';
import '../../domain/usecases/delete_category.dart';
import '../../domain/usecases/get_categories.dart';
import '../../domain/usecases/save_category.dart';

// 1. Database & Source Providers
final categoryDatabaseHelperProvider = Provider<DatabaseHelper>((ref) => DatabaseHelper.instance);

final categoryLocalDataSourceProvider = Provider<CategoryLocalDataSource>((ref) {
  return CategoryLocalDataSourceImpl(ref.watch(categoryDatabaseHelperProvider));
});

// 2. Repository Provider
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepositoryImpl(ref.watch(categoryLocalDataSourceProvider));
});

// 3. Use Case Providers
final getCategoriesUseCaseProvider = Provider<GetCategories>((ref) {
  return GetCategories(ref.watch(categoryRepositoryProvider));
});

final saveCategoryUseCaseProvider = Provider<SaveCategory>((ref) {
  return SaveCategory(ref.watch(categoryRepositoryProvider));
});

final deleteCategoryUseCaseProvider = Provider<DeleteCategory>((ref) {
  return DeleteCategory(ref.watch(categoryRepositoryProvider));
});

// 4. State Notifier managing the List of Categories
class CategoryListNotifier extends StateNotifier<AsyncValue<List<Category>>> {
  final GetCategories getCategories;
  final SaveCategory saveCategory;
  final DeleteCategory deleteCategory;

  CategoryListNotifier({
    required this.getCategories,
    required this.saveCategory,
    required this.deleteCategory,
  }) : super(const AsyncValue.loading()) {
    loadCategories();
  }

  /// Reloads all categories from the database.
  Future<void> loadCategories() async {
    state = const AsyncValue.loading();
    final result = await getCategories(NoParams());
    result.fold(
      (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
      (categories) => state = AsyncValue.data(categories),
    );
  }

  /// Saves a category (insert or update). Returns true on success.
  Future<bool> saveCategoryProfile(Category category) async {
    final result = await saveCategory(category);
    return result.fold(
      (failure) => false,
      (savedId) {
        loadCategories(); // Reactive reload list
        return true;
      },
    );
  }

  /// Deletes a category by its ID. Returns true on success.
  Future<bool> deleteCategoryProfile(int id) async {
    final result = await deleteCategory(id);
    return result.fold(
      (failure) => false,
      (success) {
        loadCategories(); // Reactive reload list
        return true;
      },
    );
  }
}

// 5. Global Category List Provider
final categoryListProvider = StateNotifierProvider<CategoryListNotifier, AsyncValue<List<Category>>>((ref) {
  return CategoryListNotifier(
    getCategories: ref.watch(getCategoriesUseCaseProvider),
    saveCategory: ref.watch(saveCategoryUseCaseProvider),
    deleteCategory: ref.watch(deleteCategoryUseCaseProvider),
  );
});
