import 'package:dartz/dartz.dart' hide Unit;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:kasir_cepat/core/errors/failures.dart';
import 'package:kasir_cepat/core/usecase/usecase.dart';
import 'package:kasir_cepat/feature/unit/domain/entities/unit_entity.dart';
import 'package:kasir_cepat/feature/unit/domain/repositories/unit_repository.dart';
import 'package:kasir_cepat/feature/unit/domain/usecases/delete_unit.dart';
import 'package:kasir_cepat/feature/unit/domain/usecases/get_units.dart';
import 'package:kasir_cepat/feature/unit/domain/usecases/save_unit.dart';
import 'package:kasir_cepat/feature/unit/presentation/provider/unit_provider.dart';
import 'package:kasir_cepat/feature/unit/presentation/unit_list_page.dart';

class FakeGetUnits implements GetUnits {
  final List<Unit> units;
  FakeGetUnits(this.units);

  @override
  UnitRepository get repository => throw UnimplementedError();

  @override
  Future<Either<Failure, List<Unit>>> call(NoParams params) async {
    return Right(units);
  }
}

class FakeSaveUnit implements SaveUnit {
  bool saveCalled = false;
  Unit? savedUnit;

  @override
  UnitRepository get repository => throw UnimplementedError();

  @override
  Future<Either<Failure, int>> call(Unit params) async {
    saveCalled = true;
    savedUnit = params;
    return const Right(1);
  }
}

class FakeDeleteUnit implements DeleteUnit {
  bool deleteCalled = false;
  int? deletedId;

  @override
  UnitRepository get repository => throw UnimplementedError();

  @override
  Future<Either<Failure, void>> call(int id) async {
    deleteCalled = true;
    deletedId = id;
    return const Right(null);
  }
}

void main() {
  final tDateTime = DateTime(2026, 6, 19);
  final tUnit1 = Unit(id: 1, name: 'Kilogram', abbreviation: 'kg', createdAt: tDateTime);
  final tUnit2 = Unit(id: 2, name: 'Pieces', abbreviation: 'pcs', createdAt: tDateTime);

  late FakeGetUnits fakeGet;
  late FakeSaveUnit fakeSave;
  late FakeDeleteUnit fakeDelete;
  late GoRouter router;

  setUp(() {
    fakeGet = FakeGetUnits([tUnit1, tUnit2]);
    fakeSave = FakeSaveUnit();
    fakeDelete = FakeDeleteUnit();

    router = GoRouter(
      initialLocation: '/units',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: Text('Mock Dashboard')),
        ),
        GoRoute(
          path: '/units',
          builder: (context, state) => const UnitListPage(),
        ),
      ],
    );
  });

  Widget createWidgetUnderTest() {
    return ProviderScope(
      overrides: [
        getUnitsUseCaseProvider.overrideWithValue(fakeGet),
        saveUnitUseCaseProvider.overrideWithValue(fakeSave),
        deleteUnitUseCaseProvider.overrideWithValue(fakeDelete),
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  testWidgets('UnitListPage renders unit list and handles search filter', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Verify units list renders
    expect(find.text('Kilogram'), findsOneWidget);
    expect(find.text('kg'), findsOneWidget);
    expect(find.text('Pieces'), findsOneWidget);
    expect(find.text('pcs'), findsOneWidget);

    // Enter search query
    await tester.enterText(find.byType(TextField), 'pcs');
    await tester.pump();

    // Verify search filter applied
    expect(find.text('Pieces'), findsOneWidget);
    expect(find.text('Kilogram'), findsNothing);
  });

  testWidgets('UnitListPage opens bottom sheet to add and save a unit', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Tap Floating Action Button to add unit
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // Verify bottom sheet opens
    expect(find.text('Tambah Satuan Baru'), findsOneWidget);

    // Fill form
    await tester.enterText(find.widgetWithText(TextFormField, 'Nama Satuan *'), 'Box');
    await tester.enterText(find.widgetWithText(TextFormField, 'Singkatan / Simbol *'), 'box');
    await tester.pump();

    // Tap save
    await tester.tap(find.text('Simpan Satuan'));
    await tester.pumpAndSettle();

    // Verify save usecase is triggered
    expect(fakeSave.saveCalled, isTrue);
    expect(fakeSave.savedUnit?.name, 'Box');
    expect(fakeSave.savedUnit?.abbreviation, 'box');
  });

  testWidgets('UnitListPage opens delete confirmation and deletes item', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Tap delete button on first card (Kilogram)
    // There are 2 cards, so we select the first delete button
    final deleteButton = find.byIcon(LucideIcons.trash2).first;
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();

    // Verify confirmation dialog shows
    expect(find.text('Hapus Satuan'), findsOneWidget);
    expect(find.text('Apakah Anda yakin ingin menghapus satuan "Kilogram"?'), findsOneWidget);

    // Tap Hapus button in dialog
    await tester.tap(find.widgetWithText(ElevatedButton, 'Hapus'));
    await tester.pumpAndSettle();

    // Verify delete usecase is triggered
    expect(fakeDelete.deleteCalled, isTrue);
    expect(fakeDelete.deletedId, 1);
  });
}
