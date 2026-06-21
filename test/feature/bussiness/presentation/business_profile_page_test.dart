import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kasir_cepat/core/errors/failures.dart';
import 'package:kasir_cepat/core/usecase/usecase.dart';
import 'package:kasir_cepat/feature/bussiness/domain/entities/business.dart';
import 'package:kasir_cepat/feature/bussiness/domain/repositories/business_repository.dart';
import 'package:kasir_cepat/feature/bussiness/domain/usecases/get_business.dart';
import 'package:kasir_cepat/feature/bussiness/domain/usecases/save_business.dart';
import 'package:kasir_cepat/feature/bussiness/presentation/business_profile_page.dart';
import 'package:kasir_cepat/feature/bussiness/presentation/provider/business_provider.dart';

class FakeGetBusiness implements GetBusiness {
  final Business? business;
  FakeGetBusiness(this.business);

  @override
  BusinessRepository get repository => throw UnimplementedError();

  @override
  Future<Either<Failure, Business?>> call(NoParams params) async {
    return Right(business);
  }
}

class FakeSaveBusiness implements SaveBusiness {
  bool saveCalled = false;
  Business? savedBusiness;

  @override
  BusinessRepository get repository => throw UnimplementedError();

  @override
  Future<Either<Failure, int>> call(Business params) async {
    saveCalled = true;
    savedBusiness = params;
    return const Right(1);
  }
}

void main() {
  final tDateTime = DateTime(2026, 6, 19);
  final tBusiness = Business(
    id: 1,
    name: 'Toko Kopi Asli',
    email: 'toko@kopi.com',
    phone: '0812345',
    address: 'Bandung',
    logo: 'preset:store:4291983151',
    taxRate: 5.0,
    footerMessage: 'Sampai Jumpa!',
    createdAt: tDateTime,
  );

  testWidgets('BusinessProfilePage populates form and triggers save', (WidgetTester tester) async {
    final fakeGet = FakeGetBusiness(tBusiness);
    final fakeSave = FakeSaveBusiness();

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: Text('Mock Dashboard')),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const BusinessProfilePage(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          getBusinessUseCaseProvider.overrideWithValue(fakeGet),
          saveBusinessUseCaseProvider.overrideWithValue(fakeSave),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );

    // Navigate to profile page to build stack history
    router.push('/profile');
    await tester.pumpAndSettle();

    // Assert that the fields are pre-populated with tBusiness data
    expect(find.text('Toko Kopi Asli'), findsOneWidget);
    expect(find.text('toko@kopi.com'), findsOneWidget);
    expect(find.text('0812345'), findsOneWidget);
    expect(find.text('Bandung'), findsOneWidget);
    expect(find.text('5.0'), findsOneWidget);
    expect(find.text('Sampai Jumpa!'), findsOneWidget);

    // Modify the store name field
    await tester.enterText(find.widgetWithText(TextFormField, 'Nama Toko / Bisnis *'), 'Toko Kopi Baru');
    await tester.pump();

    // Tap the save button
    await tester.ensureVisible(find.text('Simpan Perubahan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simpan Perubahan'));
    await tester.pumpAndSettle();

    // Verify that the save use case was called with updated details
    expect(fakeSave.saveCalled, isTrue);
    expect(fakeSave.savedBusiness?.name, 'Toko Kopi Baru');
    expect(fakeSave.savedBusiness?.email, 'toko@kopi.com');
    
    // Verify that the page popped back to the mock dashboard
    expect(find.text('Mock Dashboard'), findsOneWidget);
  });

  testWidgets('BusinessProfilePage shows validation error on empty store name', (WidgetTester tester) async {
    final fakeGet = FakeGetBusiness(tBusiness);
    final fakeSave = FakeSaveBusiness();

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: Text('Mock Dashboard')),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const BusinessProfilePage(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          getBusinessUseCaseProvider.overrideWithValue(fakeGet),
          saveBusinessUseCaseProvider.overrideWithValue(fakeSave),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );

    // Navigate to profile page
    router.push('/profile');
    await tester.pumpAndSettle();

    // Empty the store name
    await tester.enterText(find.widgetWithText(TextFormField, 'Nama Toko / Bisnis *'), '');
    await tester.pump();

    // Tap save
    await tester.ensureVisible(find.text('Simpan Perubahan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simpan Perubahan'));
    await tester.pump();

    // Assert that validation message is shown
    expect(find.text('Nama bisnis wajib diisi'), findsOneWidget);
    expect(fakeSave.saveCalled, isFalse); // Save shouldn't be executed
  });
}
