import 'package:dartz/dartz.dart' hide Order;
import '../../../../core/errors/failures.dart';
import '../entities/printer.dart';
import '../entities/receipt_template.dart';
import '../../../order/domain/entities/order.dart';

abstract class PrinterRepository {
  /// Fetches all configured printer configurations.
  Future<Either<Failure, List<PrinterDevice>>> getPrinters();

  /// Saves or updates a printer configuration.
  Future<Either<Failure, int>> savePrinter(PrinterDevice printer);

  /// Deletes a printer configuration by its ID.
  Future<Either<Failure, void>> deletePrinter(int id);

  /// Marks a specific printer as default, clearing other defaults.
  Future<Either<Failure, void>> setDefaultPrinter(int id);

  /// Retrieves the default printer configuration.
  Future<Either<Failure, PrinterDevice?>> getDefaultPrinter();

  /// Formats the order and prints it over Bluetooth, USB, or LAN socket.
  Future<Either<Failure, void>> printReceipt(Order order, PrinterDevice printer);

  /// Prints a formatted test configuration page to verify alignment and printer state.
  Future<Either<Failure, void>> printTestPage(PrinterDevice printer);

  /// Fetches the receipt template settings.
  Future<Either<Failure, ReceiptTemplate>> getReceiptTemplate();

  /// Saves or updates the receipt template settings.
  Future<Either<Failure, void>> saveReceiptTemplate(ReceiptTemplate template);
}
