import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/usecase/usecase.dart';
import '../../data/datasources/printer_local_datasource.dart';
import '../../data/repositories/printer_repository_impl.dart';
import '../../domain/entities/printer.dart';
import '../../domain/repositories/printer_repository.dart';
import '../../domain/usecases/delete_printer.dart';
import '../../domain/usecases/get_default_printer.dart';
import '../../domain/usecases/get_printers.dart';
import '../../domain/usecases/print_receipt.dart';
import '../../domain/usecases/save_printer.dart';
import '../../domain/usecases/set_default_printer.dart';
import '../../domain/usecases/print_test_page.dart';

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
