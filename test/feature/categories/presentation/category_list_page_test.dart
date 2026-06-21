import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:kasir_cepat/core/errors/failures.dart';
import 'package:kasir_cepat/core/usecase/usecase.dart';
import 'package:kasir_cepat/feature/categories/domain/entities/category.dart';
import 'package:kasir_cepat/feature/categories/domain/repositories/category_repository.dart';
import 'package:kasir_cepat/feature/categories/domain/usecases/delete_category.dart';
import 'package:kasir_cepat/feature/categories/domain/usecases/get_categories.dart';
import 'package:kasir_cepat/feature/categories/domain/usecases/save_category.dart';
import 'package:kasir_cepat/feature/categories/presentation/provider/category_provider.dart';
import 'package:kasir_cepat/feature/categories/presentation/category_list_page.dart';

class FakeGetCategories implements GetCategories {
  final List<Category> categories;
  FakeGetCategories(this.categories);

  @override
  CategoryRepository get repository => throw UnimplementedError();

  @override
  Future<Either<Failure, List<Category>>> call(NoParams params) async {
    return Right(categories);
  }
}

class FakeSaveCategory implements SaveCategory {
  bool saveCalled = false;
  Category? savedCategory;

  @override
  CategoryRepository get repository => throw UnimplementedError();

  @override
  Future<Either<Failure, int>> call(Category params) async {
    saveCalled = true;
    savedCategory = params;
    return const Right(1);
  }
}

class FakeDeleteCategory implements DeleteCategory {
  bool deleteCalled = false;
  int? deletedId;

  @override
  CategoryRepository get repository => throw UnimplementedError();

  @override
  Future<Either<Failure, void>> call(int id) async {
    deleteCalled = true;
    deletedId = id;
    return const Right(null);
  }
}

void main() {
  final tDateTime = DateTime(2026, 6, 19);
  final tCategory1 = Category(id: 1, name: 'Makanan', description: 'Kategori makanan', createdAt: tDateTime);
  final tCategory2 = Category(id: 2, name: 'Minuman', description: 'Kategori minuman', createdAt: tDateTime);

  late FakeGetCategories fakeGet;
  late FakeSaveCategory fakeSave;
  late FakeDeleteCategory fakeDelete;
  late GoRouter router;

  setUp(() {
    fakeGet = FakeGetCategories([tCategory1, tCategory2]);
    fakeSave = FakeSaveCategory();
    fakeDelete = FakeDeleteCategory();

    router = GoRouter(
      initialLocation: '/categories',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: Text('Mock Dashboard')),
        ),
        GoRoute(
          path: '/categories',
          builder: (context, state) => const CategoryListPage(),
        ),
      ],
    );
  });

  Widget createWidgetUnderTest() {
    return ProviderScope(
      overrides: [
        getCategoriesUseCaseProvider.overrideWithValue(fakeGet),
        saveCategoryUseCaseProvider.overrideWithValue(fakeSave),
        deleteCategoryUseCaseProvider.overrideWithValue(fakeDelete),
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  testWidgets('CategoryListPage renders categories list and handles search filter', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Verify categories list renders
    expect(find.text('Makanan'), findsOneWidget);
    expect(find.text('Kategori makanan'), findsOneWidget);
    expect(find.text('Minuman'), findsOneWidget);
    expect(find.text('Kategori minuman'), findsOneWidget);

    // Enter search query
    await tester.enterText(find.byType(TextField), 'minum');
    await tester.pump();

    // Verify search filter applied
    expect(find.text('Minuman'), findsOneWidget);
    expect(find.text('Makanan'), findsNothing);
  });

  testWidgets('CategoryListPage opens bottom sheet to add and save a category', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Tap Floating Action Button to add category
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // Verify bottom sheet opens
    expect(find.text('Tambah Kategori Baru'), findsOneWidget);

    // Fill form
    await tester.enterText(find.widgetWithText(TextFormField, 'Nama Kategori *'), 'Snack');
    await tester.enterText(find.widgetWithText(TextFormField, 'Deskripsi (Opsional)'), 'Camilan ringan');
    await tester.pump();

    // Tap save
    await tester.tap(find.text('Simpan Kategori'));
    await tester.pumpAndSettle();

    // Verify save usecase is triggered
    expect(fakeSave.saveCalled, isTrue);
    expect(fakeSave.savedCategory?.name, 'Snack');
    expect(fakeSave.savedCategory?.description, 'Camilan ringan');
  });

  testWidgets('CategoryListPage opens delete confirmation and deletes item', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Tap delete button on first card (Makanan)
    final deleteButton = find.byIcon(LucideIcons.trash2).first;
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();

    // Verify confirmation dialog shows
    expect(find.text('Hapus Kategori'), findsOneWidget);
    expect(find.text('Apakah Anda yakin ingin menghapus kategori "Makanan"?'), findsOneWidget);

    // Tap Hapus button in dialog
    await tester.tap(find.widgetWithText(ElevatedButton, 'Hapus'));
    await tester.pumpAndSettle();

    // Verify delete usecase is triggered
    expect(fakeDelete.deleteCalled, isTrue);
    expect(fakeDelete.deletedId, 1);
  });
}
