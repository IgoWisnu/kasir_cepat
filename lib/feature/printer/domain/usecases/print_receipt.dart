import 'package:dartz/dartz.dart' hide Order;
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../order/domain/entities/order.dart';
import '../entities/printer.dart';
import '../repositories/printer_repository.dart';

class PrintReceipt implements UseCase<void, PrintReceiptParams> {
  final PrinterRepository repository;

  PrintReceipt(this.repository);

  @override
  Future<Either<Failure, void>> call(PrintReceiptParams params) async {
    return await repository.printReceipt(params.order, params.printer);
  }
}

class PrintReceiptParams {
  final Order order;
  final PrinterDevice printer;

  const PrintReceiptParams({
    required this.order,
    required this.printer,
  });
}
