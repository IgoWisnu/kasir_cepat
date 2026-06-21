import '../../../../core/database/database_helper.dart';
import '../models/printer_model.dart';

abstract class PrinterLocalDataSource {
  Future<List<PrinterModel>> getPrinters();
  Future<int> savePrinter(PrinterModel printer);
  Future<void> deletePrinter(int id);
  Future<void> setDefaultPrinter(int id);
  Future<PrinterModel?> getDefaultPrinter();
}

class PrinterLocalDataSourceImpl implements PrinterLocalDataSource {
  final DatabaseHelper databaseHelper;

  PrinterLocalDataSourceImpl(this.databaseHelper);

  @override
  Future<List<PrinterModel>> getPrinters() async {
    final db = await databaseHelper.database;
    final results = await db.query('printers', orderBy: 'id ASC');
    return results.map((map) => PrinterModel.fromMap(map)).toList();
  }

  @override
  Future<int> savePrinter(PrinterModel printer) async {
    final db = await databaseHelper.database;
    
    if (printer.id != null) {
      await db.update(
        'printers',
        printer.toMap(),
        where: 'id = ?',
        whereArgs: [printer.id],
      );
      return printer.id!;
    } else {
      return await db.insert('printers', printer.toMap());
    }
  }

  @override
  Future<void> deletePrinter(int id) async {
    final db = await databaseHelper.database;
    await db.delete(
      'printers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> setDefaultPrinter(int id) async {
    final db = await databaseHelper.database;
    
    await db.transaction((txn) async {
      // 1. Clear all defaults
      await txn.update(
        'printers',
        {'is_default': 0},
      );
      
      // 2. Set this printer as default
      await txn.update(
        'printers',
        {'is_default': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  @override
  Future<PrinterModel?> getDefaultPrinter() async {
    final db = await databaseHelper.database;
    final results = await db.query(
      'printers',
      where: 'is_default = 1',
      limit: 1,
    );
    if (results.isEmpty) return null;
    return PrinterModel.fromMap(results.first);
  }
}
