import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/usecase/usecase.dart';
import '../../data/datasources/printer_local_datasource.dart';
import '../../data/repositories/printer_repository_impl.dart';
import '../../domain/entities/printer.dart';
import '../../domain/entities/receipt_template.dart';
import '../../domain/repositories/printer_repository.dart';
import '../../domain/usecases/delete_printer.dart';
import '../../domain/usecases/get_default_printer.dart';
import '../../domain/usecases/get_printers.dart';
import '../../domain/usecases/print_receipt.dart';
import '../../domain/usecases/save_printer.dart';
import '../../domain/usecases/set_default_printer.dart';
import '../../domain/usecases/print_test_page.dart';
import '../../domain/usecases/get_receipt_template.dart';
import '../../domain/usecases/save_receipt_template.dart';

// 1. Database & Source Providers
final printerDatabaseHelperProvider = Provider<DatabaseHelper>((ref) => DatabaseHelper.instance);

final printerLocalDataSourceProvider = Provider<PrinterLocalDataSource>((ref) {
  return PrinterLocalDataSourceImpl(ref.watch(printerDatabaseHelperProvider));
});

// 2. Repository Provider
final printerRepositoryProvider = Provider<PrinterRepository>((ref) {
  return PrinterRepositoryImpl(ref.watch(printerLocalDataSourceProvider));
});

// 3. Use Case Providers
final getPrintersUseCaseProvider = Provider<GetPrinters>((ref) {
  return GetPrinters(ref.watch(printerRepositoryProvider));
});

final savePrinterUseCaseProvider = Provider<SavePrinter>((ref) {
  return SavePrinter(ref.watch(printerRepositoryProvider));
});

final deletePrinterUseCaseProvider = Provider<DeletePrinter>((ref) {
  return DeletePrinter(ref.watch(printerRepositoryProvider));
});

final setDefaultPrinterUseCaseProvider = Provider<SetDefaultPrinter>((ref) {
  return SetDefaultPrinter(ref.watch(printerRepositoryProvider));
});

final getDefaultPrinterUseCaseProvider = Provider<GetDefaultPrinter>((ref) {
  return GetDefaultPrinter(ref.watch(printerRepositoryProvider));
});

final printReceiptUseCaseProvider = Provider<PrintReceipt>((ref) {
  return PrintReceipt(ref.watch(printerRepositoryProvider));
});

final printTestPageUseCaseProvider = Provider<PrintTestPage>((ref) {
  return PrintTestPage(ref.watch(printerRepositoryProvider));
});

final getReceiptTemplateUseCaseProvider = Provider<GetReceiptTemplate>((ref) {
  return GetReceiptTemplate(ref.watch(printerRepositoryProvider));
});

final saveReceiptTemplateUseCaseProvider = Provider<SaveReceiptTemplate>((ref) {
  return SaveReceiptTemplate(ref.watch(printerRepositoryProvider));
});

// 4. State Notifier managing the List of Printers
class PrinterListNotifier extends StateNotifier<AsyncValue<List<PrinterDevice>>> {
  final GetPrinters getPrinters;
  final SavePrinter savePrinter;
  final DeletePrinter deletePrinter;

  PrinterListNotifier({
    required this.getPrinters,
    required this.savePrinter,
    required this.deletePrinter,
  }) : super(const AsyncValue.loading()) {
    loadPrinters();
  }

  Future<void> loadPrinters() async {
    state = const AsyncValue.loading();
    final result = await getPrinters(NoParams());
    result.fold(
      (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
      (printers) => state = AsyncValue.data(printers),
    );
  }

  Future<bool> savePrinterDevice(PrinterDevice printer) async {
    final result = await savePrinter(printer);
    return result.fold(
      (failure) => false,
      (_) {
        loadPrinters();
        return true;
      },
    );
  }

  Future<bool> deletePrinterDevice(int id) async {
    final result = await deletePrinter(id);
    return result.fold(
      (failure) => false,
      (_) {
        loadPrinters();
        return true;
      },
    );
  }
}

final printerListProvider = StateNotifierProvider<PrinterListNotifier, AsyncValue<List<PrinterDevice>>>((ref) {
  return PrinterListNotifier(
    getPrinters: ref.watch(getPrintersUseCaseProvider),
    savePrinter: ref.watch(savePrinterUseCaseProvider),
    deletePrinter: ref.watch(deletePrinterUseCaseProvider),
  );
});

// 5. State Notifier managing the default printer config
class DefaultPrinterNotifier extends StateNotifier<AsyncValue<PrinterDevice?>> {
  final GetDefaultPrinter getDefaultPrinter;
  final SetDefaultPrinter setDefaultPrinter;

  DefaultPrinterNotifier({
    required this.getDefaultPrinter,
    required this.setDefaultPrinter,
  }) : super(const AsyncValue.loading()) {
    loadDefaultPrinter();
  }

  Future<void> loadDefaultPrinter() async {
    state = const AsyncValue.loading();
    final result = await getDefaultPrinter(NoParams());
    result.fold(
      (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
      (printer) => state = AsyncValue.data(printer),
    );
  }

  Future<bool> setAsDefault(int id) async {
    final result = await setDefaultPrinter(id);
    return result.fold(
      (failure) => false,
      (_) {
        loadDefaultPrinter();
        return true;
      },
    );
  }
}

final defaultPrinterProvider = StateNotifierProvider<DefaultPrinterNotifier, AsyncValue<PrinterDevice?>>((ref) {
  return DefaultPrinterNotifier(
    getDefaultPrinter: ref.watch(getDefaultPrinterUseCaseProvider),
    setDefaultPrinter: ref.watch(setDefaultPrinterUseCaseProvider),
  );
});

// 6. State Notifier managing Receipt Template Configuration
class ReceiptTemplateNotifier extends StateNotifier<AsyncValue<ReceiptTemplate>> {
  final GetReceiptTemplate getReceiptTemplate;
  final SaveReceiptTemplate saveReceiptTemplate;

  ReceiptTemplateNotifier({
    required this.getReceiptTemplate,
    required this.saveReceiptTemplate,
  }) : super(const AsyncValue.loading()) {
    loadReceiptTemplate();
  }

  Future<void> loadReceiptTemplate() async {
    state = const AsyncValue.loading();
    final result = await getReceiptTemplate(NoParams());
    result.fold(
      (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
      (template) => state = AsyncValue.data(template),
    );
  }

  Future<bool> updateReceiptTemplate(ReceiptTemplate template) async {
    final result = await saveReceiptTemplate(template);
    return result.fold(
      (failure) => false,
      (_) {
        state = AsyncValue.data(template);
        return true;
      },
    );
  }
}

final receiptTemplateProvider = StateNotifierProvider<ReceiptTemplateNotifier, AsyncValue<ReceiptTemplate>>((ref) {
  return ReceiptTemplateNotifier(
    getReceiptTemplate: ref.watch(getReceiptTemplateUseCaseProvider),
    saveReceiptTemplate: ref.watch(saveReceiptTemplateUseCaseProvider),
  );
});
