import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/receipt_template.dart';
import '../repositories/printer_repository.dart';

class SaveReceiptTemplate implements UseCase<void, ReceiptTemplate> {
  final PrinterRepository repository;

  SaveReceiptTemplate(this.repository);

  @override
  Future<Either<Failure, void>> call(ReceiptTemplate template) async {
    return await repository.saveReceiptTemplate(template);
  }
}
