import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:kasir_cepat/core/errors/failures.dart';
import 'package:kasir_cepat/core/usecase/usecase.dart';
import 'package:kasir_cepat/feature/discount/domain/entities/discount.dart';
import 'package:kasir_cepat/feature/discount/domain/repositories/discount_repository.dart';
import 'package:kasir_cepat/feature/discount/domain/usecases/delete_discount.dart';
import 'package:kasir_cepat/feature/discount/domain/usecases/get_discounts.dart';
import 'package:kasir_cepat/feature/discount/domain/usecases/save_discount.dart';
import 'package:kasir_cepat/feature/discount/presentation/provider/discount_provider.dart';
import 'package:kasir_cepat/feature/discount/presentation/discount_list_page.dart';

class FakeGetDiscounts implements GetDiscounts {
  final List<Discount> discounts;
  FakeGetDiscounts(this.discounts);

  @override
  DiscountRepository get repository => throw UnimplementedError();

  @override
  Future<Either<Failure, List<Discount>>> call(NoParams params) async {
    return Right(discounts);
  }
}

class FakeSaveDiscount implements SaveDiscount {
  bool saveCalled = false;
  Discount? savedDiscount;

  @override
  DiscountRepository get repository => throw UnimplementedError();

  @override
  Future<Either<Failure, int>> call(Discount params) async {
    saveCalled = true;
    savedDiscount = params;
    return const Right(1);
  }
}

class FakeDeleteDiscount implements DeleteDiscount {
  bool deleteCalled = false;
  int? deletedId;

  @override
  DiscountRepository get repository => throw UnimplementedError();

  @override
  Future<Either<Failure, void>> call(int id) async {
    deleteCalled = true;
    deletedId = id;
    return const Right(null);
  }
}

void main() {
  final tDateTime = DateTime(2026, 6, 19);
  final tDiscount1 = Discount(
    id: 1,
    name: 'Promo Merdeka',
    description: 'Promo hari kemerdekaan',
    valueType: 'percentage',
    value: 17.0,
    startDate: null,
    endDate: null,
    isActive: true,
    createdAt: tDateTime,
  );
  final tDiscount2 = Discount(
    id: 2,
    name: 'Potongan Hemat',
    description: 'Potongan belanja hemat',
    valueType: 'fixed',
    value: 5000.0,
    startDate: null,
    endDate: null,
    isActive: false,
    createdAt: tDateTime,
  );

  late FakeGetDiscounts fakeGet;
  late FakeSaveDiscount fakeSave;
  late FakeDeleteDiscount fakeDelete;
  late GoRouter router;

  setUp(() {
    fakeGet = FakeGetDiscounts([tDiscount1, tDiscount2]);
    fakeSave = FakeSaveDiscount();
    fakeDelete = FakeDeleteDiscount();

    router = GoRouter(
      initialLocation: '/discounts',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: Text('Mock Dashboard')),
        ),
        GoRoute(
          path: '/discounts',
          builder: (context, state) => const DiscountListPage(),
        ),
      ],
    );
  });

  Widget createWidgetUnderTest() {
    return ProviderScope(
      overrides: [
        getDiscountsUseCaseProvider.overrideWithValue(fakeGet),
        saveDiscountUseCaseProvider.overrideWithValue(fakeSave),
        deleteDiscountUseCaseProvider.overrideWithValue(fakeDelete),
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  testWidgets('DiscountListPage renders discounts list and badges correctly', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Verify promo 1 (percentage) details
    expect(find.text('Promo Merdeka'), findsOneWidget);
    expect(find.text('Promo hari kemerdekaan'), findsOneWidget);
    expect(find.text('17%'), findsOneWidget);
    expect(find.text('Aktif'), findsOneWidget);

    // Verify promo 2 (fixed value formatted) details
    expect(find.text('Potongan Hemat'), findsOneWidget);
    expect(find.text('Potongan belanja hemat'), findsOneWidget);
    expect(find.text('Rp 5k'), findsOneWidget);
    expect(find.text('Nonaktif'), findsOneWidget);
  });

  testWidgets('DiscountListPage handles search filter', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Enter search query
    await tester.enterText(find.byType(TextField), 'hemat');
    await tester.pump();

    // Verify search filter applied
    expect(find.text('Potongan Hemat'), findsOneWidget);
    expect(find.text('Promo Merdeka'), findsNothing);
  });

  testWidgets('DiscountListPage opens bottom sheet to add and save a discount', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Tap Floating Action Button to add discount
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // Verify bottom sheet opens
    expect(find.text('Tambah Promo Baru'), findsOneWidget);

    // Fill form
    await tester.enterText(find.widgetWithText(TextFormField, 'Nama Promo *'), 'Diskon Ultah');
    // Change value type to nominal fixed
    await tester.tap(find.text('Nominal Tetap (Rp)'));
    await tester.pump();

    await tester.enterText(find.widgetWithText(TextFormField, 'Nominal Diskon (Rp) *'), '10000');
    await tester.enterText(find.widgetWithText(TextFormField, 'Deskripsi (Opsional)'), 'Diskon ultah toko');
    await tester.pump();

    // Tap save
    await tester.ensureVisible(find.text('Simpan Promo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simpan Promo'));
    await tester.pumpAndSettle();

    // Verify save usecase is triggered
    expect(fakeSave.saveCalled, isTrue);
    expect(fakeSave.savedDiscount?.name, 'Diskon Ultah');
    expect(fakeSave.savedDiscount?.valueType, 'fixed');
    expect(fakeSave.savedDiscount?.value, 10000.0);
    expect(fakeSave.savedDiscount?.description, 'Diskon ultah toko');
  });

  testWidgets('DiscountListPage opens delete confirmation and deletes item', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Tap delete button on first card (Promo Merdeka)
    final deleteButton = find.byIcon(LucideIcons.trash2).first;
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();

    // Verify confirmation dialog shows
    expect(find.text('Hapus Promo'), findsOneWidget);
    expect(find.text('Apakah Anda yakin ingin menghapus promo "Promo Merdeka"?'), findsOneWidget);

    // Tap Hapus button in dialog
    await tester.tap(find.widgetWithText(ElevatedButton, 'Hapus'));
    await tester.pumpAndSettle();

    // Verify delete usecase is triggered
    expect(fakeDelete.deleteCalled, isTrue);
    expect(fakeDelete.deletedId, 1);
  });
}
