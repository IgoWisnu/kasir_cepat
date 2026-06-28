import 'package:dartz/dartz.dart' hide Order;
import 'package:flutter_test/flutter_test.dart';
import 'package:kasir_cepat/core/errors/failures.dart';
import 'package:kasir_cepat/core/usecase/usecase.dart';
import 'package:kasir_cepat/feature/order/domain/entities/order.dart';
import 'package:kasir_cepat/feature/printer/domain/entities/printer.dart';
import 'package:kasir_cepat/feature/printer/domain/entities/receipt_template.dart';
import 'package:kasir_cepat/feature/printer/domain/repositories/printer_repository.dart';
import 'package:kasir_cepat/feature/printer/domain/usecases/get_receipt_template.dart';
import 'package:kasir_cepat/feature/printer/domain/usecases/save_receipt_template.dart';

class FakePrinterRepository implements PrinterRepository {
  ReceiptTemplate? mockTemplate;
  bool getTemplateCalled = false;
  bool saveTemplateCalled = false;

  @override
  Future<Either<Failure, List<PrinterDevice>>> getPrinters() async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, int>> savePrinter(PrinterDevice printer) async {
    return const Right(1);
  }

  @override
  Future<Either<Failure, void>> deletePrinter(int id) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> setDefaultPrinter(int id) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, PrinterDevice?>> getDefaultPrinter() async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> printReceipt(Order order, PrinterDevice printer) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> printTestPage(PrinterDevice printer) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, ReceiptTemplate>> getReceiptTemplate() async {
    getTemplateCalled = true;
    return Right(mockTemplate ?? const ReceiptTemplate());
  }

  @override
  Future<Either<Failure, void>> saveReceiptTemplate(ReceiptTemplate template) async {
    saveTemplateCalled = true;
    mockTemplate = template;
    return const Right(null);
  }
}

void main() {
  late FakePrinterRepository repository;
  late GetReceiptTemplate getReceiptTemplate;
  late SaveReceiptTemplate saveReceiptTemplate;

  setUp(() {
    repository = FakePrinterRepository();
    getReceiptTemplate = GetReceiptTemplate(repository);
    saveReceiptTemplate = SaveReceiptTemplate(repository);
  });

  const tTemplate = ReceiptTemplate(
    id: 1,
    showLogo: true,
    showBusinessName: true,
    businessNameOverride: 'Toko Kopi Keren',
    showBusinessAddress: false,
    showTransactionId: true,
    showCustomerName: false,
    showCashierName: true,
    showProductSku: true,
    footerText: 'Sampai Jumpa!',
  );

  group('GetReceiptTemplate UseCase', () {
    test('should fetch receipt template from repository', () async {
      repository.mockTemplate = tTemplate;
      final result = await getReceiptTemplate(NoParams());
      expect(result, const Right(tTemplate));
      expect(repository.getTemplateCalled, isTrue);
    });
  });

  group('SaveReceiptTemplate UseCase', () {
    test('should save receipt template to repository', () async {
      final result = await saveReceiptTemplate(tTemplate);
      expect(result, const Right(null));
      expect(repository.saveTemplateCalled, isTrue);
      expect(repository.mockTemplate, equals(tTemplate));
    });
  });
}
