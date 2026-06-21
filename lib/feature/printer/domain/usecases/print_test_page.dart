import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/printer.dart';
import '../repositories/printer_repository.dart';

class PrintTestPage implements UseCase<void, PrinterDevice> {
  final PrinterRepository repository;

  PrintTestPage(this.repository);

  @override
  Future<Either<Failure, void>> call(PrinterDevice printer) async {
    return await repository.printTestPage(printer);
  }
}
