import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../models/printer_model.dart';
import '../models/receipt_template_model.dart';

abstract class PrinterLocalDataSource {
  Future<List<PrinterModel>> getPrinters();
  Future<int> savePrinter(PrinterModel printer);
  Future<void> deletePrinter(int id);
  Future<void> setDefaultPrinter(int id);
  Future<PrinterModel?> getDefaultPrinter();
  Future<ReceiptTemplateModel> getReceiptTemplate();
  Future<void> saveReceiptTemplate(ReceiptTemplateModel template);
  Future<Map<String, dynamic>?> getBusinessProfile();
  Future<String?> getCashierName(int userId);
  Future<String?> getProductSku(int productId);
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

  @override
  Future<ReceiptTemplateModel> getReceiptTemplate() async {
    final db = await databaseHelper.database;
    final results = await db.query(
      'receipt_templates',
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );
    if (results.isEmpty) {
      return const ReceiptTemplateModel(
        id: 1,
        showLogo: true,
        showBusinessName: true,
        showBusinessAddress: true,
        showTransactionId: true,
        showCustomerName: true,
        showCashierName: true,
        showProductSku: false,
      );
    }
    return ReceiptTemplateModel.fromMap(results.first);
  }

  @override
  Future<void> saveReceiptTemplate(ReceiptTemplateModel template) async {
    final db = await databaseHelper.database;
    await db.insert(
      'receipt_templates',
      template.copyWith(id: 1).toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<Map<String, dynamic>?> getBusinessProfile() async {
    final db = await databaseHelper.database;
    final results = await db.query('businesses', limit: 1);
    if (results.isEmpty) return null;
    return results.first;
  }

  @override
  Future<String?> getCashierName(int userId) async {
    final db = await databaseHelper.database;
    final results = await db.query(
      'users',
      columns: ['name'],
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return results.first['name'] as String?;
  }

  @override
  Future<String?> getProductSku(int productId) async {
    final db = await databaseHelper.database;
    final results = await db.query(
      'products',
      columns: ['sku'],
      where: 'id = ?',
      whereArgs: [productId],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return results.first['sku'] as String?;
  }
}
