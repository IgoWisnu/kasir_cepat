import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/printer.dart';
import '../repositories/printer_repository.dart';

class GetDefaultPrinter implements UseCase<PrinterDevice?, NoParams> {
  final PrinterRepository repository;

  GetDefaultPrinter(this.repository);

  @override
  Future<Either<Failure, PrinterDevice?>> call(NoParams params) async {
    return await repository.getDefaultPrinter();
  }
}
