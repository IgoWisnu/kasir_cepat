import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('kasir_cepat.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    if (kDebugMode) {
      // In development, you might want to print db location
      print('Database path: $path');
    }

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  Future _onConfigure(Database db) async {
    // Enable Foreign Key support
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // 1. Create shifts table
      await db.execute('''
        CREATE TABLE shifts (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          start_time TEXT NOT NULL,
          end_time TEXT,
          status TEXT NOT NULL,
          user_id INTEGER,
          cash_start REAL NOT NULL,
          cash_end REAL,
          cash_different REAL,
          notes TEXT,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE SET NULL
        )
      ''');
      // 2. Add shift_id column to orders table
      await db.execute('ALTER TABLE orders ADD COLUMN shift_id INTEGER');
    }
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const textNullableType = 'TEXT';
    const integerType = 'INTEGER NOT NULL';
    const realType = 'REAL NOT NULL';
    const realDefaultZero = 'REAL NOT NULL DEFAULT 0.0';

    // 1. Business Table
    await db.execute('''
      CREATE TABLE businesses (
        id $idType,
        name $textType,
        email $textNullableType,
        phone $textNullableType,
        address $textNullableType,
        logo $textNullableType,
        tax_rate $realDefaultZero,
        footer_message $textNullableType,
        created_at $textType
      )
    ''');

    // 2. Users Table (Cashiers)
    await db.execute('''
      CREATE TABLE users (
        id $idType,
        name $textType,
        username $textType UNIQUE,
        pin $textType,
        role $textType,
        is_active $integerType DEFAULT 1,
        created_at $textType
      )
    ''');

    // 3. Categories Table
    await db.execute('''
      CREATE TABLE categories (
        id $idType,
        name $textType UNIQUE,
        description $textNullableType,
        created_at $textType
      )
    ''');

    // 4. Units Table (Pcs, Box, Kg, etc.)
    await db.execute('''
      CREATE TABLE units (
        id $idType,
        name $textType UNIQUE,
        abbreviation $textType,
        created_at $textType
      )
    ''');

    // 5. Products Table
    await db.execute('''
      CREATE TABLE products (
        id $idType,
        name $textType,
        barcode $textNullableType,
        sku $textNullableType UNIQUE,
        description $textNullableType,
        price $realType,
        cost_price REAL,
        stock_quantity $realDefaultZero,
        category_id INTEGER,
        unit_id INTEGER,
        image_path $textNullableType,
        is_active $integerType DEFAULT 1,
        status TEXT NOT NULL DEFAULT 'available',
        is_track_stock INTEGER NOT NULL DEFAULT 0,
        created_at $textType,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE SET NULL,
        FOREIGN KEY (unit_id) REFERENCES units (id) ON DELETE SET NULL
      )
    ''');

    // 6. Discounts Table
    await db.execute('''
      CREATE TABLE discounts (
        id $idType,
        name $textType,
        description $textNullableType,
        value_type $textType, -- 'percentage' or 'fixed'
        value $realType,
        start_date $textNullableType,
        end_date $textNullableType,
        is_active $integerType DEFAULT 1,
        created_at $textType
      )
    ''');

    // 7. Shifts Table
    await db.execute('''
      CREATE TABLE shifts (
        id $idType,
        start_time $textType,
        end_time $textNullableType,
        status $textType,
        user_id INTEGER,
        cash_start $realType,
        cash_end REAL,
        cash_different REAL,
        notes $textNullableType,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE SET NULL
      )
    ''');

    // 8. Orders Header Table
    await db.execute('''
      CREATE TABLE orders (
        id $idType,
        invoice_number TEXT UNIQUE,
        order_queue INTEGER NOT NULL,
        customer_name TEXT,
        order_type TEXT NOT NULL,                  -- 'dine-in', 'takeaway', 'delivery'
        order_status TEXT NOT NULL,                -- 'new', 'processing', 'preparing', 'completed', 'cancelled'
        payment_status TEXT NOT NULL,              -- 'pending', 'partial', 'paid', 'refunded'
        subtotal REAL NOT NULL,
        discount_id INTEGER,
        discount_value REAL NOT NULL DEFAULT 0.0,
        discount_type TEXT,                        -- 'percentage' or 'fixed'
        tax_rate REAL NOT NULL DEFAULT 0.0,
        tax_amount REAL NOT NULL DEFAULT 0.0,
        grand_total REAL NOT NULL,
        payment_option_id INTEGER,                 -- Link to payment_options
        cash_received REAL DEFAULT 0.0,
        change_given REAL DEFAULT 0.0,
        paid_amount REAL DEFAULT 0.0,
        notes TEXT,
        user_id INTEGER,                           -- Cashier ID
        shift_id INTEGER,                          -- Shift ID
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (payment_option_id) REFERENCES payment_options (id) ON DELETE SET NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE SET NULL,
        FOREIGN KEY (shift_id) REFERENCES shifts (id) ON DELETE SET NULL
      )
    ''');

    // 8. Order Items Table
    await db.execute('''
      CREATE TABLE order_items (
        id $idType,
        order_id INTEGER NOT NULL,
        product_id INTEGER,
        product_name TEXT NOT NULL,                -- Snapshot of product name
        price_at_purchase REAL NOT NULL,           -- Snapshot of selling price
        cost_price REAL NOT NULL,                  -- Snapshot of cost price (for profit margin)
        qty REAL NOT NULL,
        discount_id INTEGER,
        discount_value REAL NOT NULL DEFAULT 0.0,
        subtotal REAL NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE SET NULL
      )
    ''');

    // 9. Stock Batches Table
    await db.execute('''
      CREATE TABLE stock_batches (
        id $idType,
        batch_no TEXT NOT NULL UNIQUE,
        type TEXT NOT NULL, -- 'restock', 'opname'
        status TEXT NOT NULL DEFAULT 'completed',
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // 10. Stock Transactions Table (Inventory Movement Logs)
    await db.execute('''
      CREATE TABLE stock_transactions (
        id $idType,
        product_id INTEGER,
        batch_id INTEGER,
        quantity $realType, -- Positive for stock-in, Negative for stock-out
        type $textType, -- 'stock_in', 'stock_out', 'sale', 'adjustment', 'restock', 'opname'
        reference $textNullableType, -- e.g. Invoice number or notes
        notes $textNullableType,
        created_at $textType,
        FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE,
        FOREIGN KEY (batch_id) REFERENCES stock_batches (id) ON DELETE SET NULL
      )
    ''');

    // 11. Payment Options Table
    await db.execute('''
      CREATE TABLE payment_options (
        id $idType,
        name TEXT NOT NULL UNIQUE,
        type TEXT NOT NULL, -- 'cash' or 'non-cash'
        icon TEXT, -- 'banknote', 'qr_code', 'credit_card', etc.
        description TEXT,
        status TEXT NOT NULL DEFAULT 'active', -- 'active' or 'inactive'
        created_at TEXT NOT NULL
      )
    ''');

    // 12. Printers Table
    await db.execute('''
      CREATE TABLE printers (
        id $idType,
        name TEXT NOT NULL,
        connection_type TEXT NOT NULL,
        address TEXT NOT NULL,
        paper_size INTEGER NOT NULL DEFAULT 58,
        is_default INTEGER NOT NULL DEFAULT 0,
        is_kitchen_printer INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'active'
      )
    ''');

    // --- Seeding Default Data ---
    final now = DateTime.now().toIso8601String();

    // Seed default business
    await db.insert('businesses', {
      'name': 'Kasir Cepat POS',
      'email': 'info@kasircepat.com',
      'phone': '08123456789',
      'address': 'Jl. Utama No. 1, Jakarta',
      'logo': null,
      'tax_rate': 0.0,
      'footer_message': 'Terima kasih telah berbelanja!',
      'created_at': now,
    });

    // Seed cashiers/users
    await db.insert('users', {
      'name': 'Admin Kasir',
      'username': 'admin',
      'pin': '1234',
      'role': 'Admin',
      'is_active': 1,
      'created_at': now,
    });

    await db.insert('users', {
      'name': 'Staff Kasir',
      'username': 'cashier1',
      'pin': '0000',
      'role': 'Cashier',
      'is_active': 1,
      'created_at': now,
    });

    // Seed Categories
    final categoryIds = <String, int>{};
    for (var cat in [
      {
        'name': 'Makanan',
        'desc': 'Kategori produk makanan siap saji atau kemasan',
      },
      {
        'name': 'Minuman',
        'desc': 'Kategori produk minuman dingin, hangat, maupun instan',
      },
      {'name': 'Lainnya', 'desc': 'Kategori umum lainnya'},
    ]) {
      final id = await db.insert('categories', {
        'name': cat['name'],
        'description': cat['desc'],
        'created_at': now,
      });
      categoryIds[cat['name']!] = id;
    }

    // Seed Units
    final unitIds = <String, int>{};
    for (var unit in [
      {'name': 'Pcs', 'abbrev': 'pcs'},
      {'name': 'Box', 'abbrev': 'box'},
      {'name': 'Kilogram', 'abbrev': 'kg'},
    ]) {
      final id = await db.insert('units', {
        'name': unit['name'],
        'abbreviation': unit['abbrev'],
        'created_at': now,
      });
      unitIds[unit['name']!] = id;
    }

    // Seed sample Products
    final products = [
      {
        'name': 'Kopi Hitam Toraja',
        'barcode': '899123456001',
        'sku': 'KOPI-001',
        'description': 'Kopi hitam tubruk khas Toraja asli',
        'price': 6000.0,
        'cost_price': 3500.0,
        'stock_quantity': 50.0,
        'category_id': categoryIds['Minuman'],
        'unit_id': unitIds['Pcs'],
      },
      {
        'name': 'Roti Manis Coklat',
        'barcode': '899123456002',
        'sku': 'ROTI-002',
        'description': 'Roti manis dengan isian pasta coklat premium',
        'price': 8000.0,
        'cost_price': 4800.0,
        'stock_quantity': 25.0,
        'category_id': categoryIds['Makanan'],
        'unit_id': unitIds['Pcs'],
      },
      {
        'name': 'Air Mineral 600ml',
        'barcode': '899123456003',
        'sku': 'AIR-003',
        'description': 'Air mineral pegunungan segar 600ml',
        'price': 3500.0,
        'cost_price': 1800.0,
        'stock_quantity': 100.0,
        'category_id': categoryIds['Minuman'],
        'unit_id': unitIds['Pcs'],
      },
    ];

    for (var prod in products) {
      final prodId = await db.insert('products', {
        'name': prod['name'],
        'barcode': prod['barcode'],
        'sku': prod['sku'],
        'description': prod['description'],
        'price': prod['price'],
        'cost_price': prod['cost_price'],
        'stock_quantity': prod['stock_quantity'],
        'category_id': prod['category_id'],
        'unit_id': prod['unit_id'],
        'is_active': 1,
        'status': 'available',
        'is_track_stock': 1,
        'created_at': now,
      });

      // Insert initial stock transaction logs
      await db.insert('stock_transactions', {
        'product_id': prodId,
        'quantity': prod['stock_quantity'],
        'type': 'stock_in',
        'reference': 'INITIAL_SEED',
        'notes': 'Stok awal produk pada inisialisasi aplikasi',
        'created_at': now,
      });
    }

    // Seed default Payment Options
    final defaultPaymentOptions = [
      {
        'name': 'Tunai',
        'type': 'cash',
        'icon': 'banknote',
        'description': 'Pembayaran tunai/cash',
        'status': 'active',
        'created_at': now,
      },
      {
        'name': 'QRIS',
        'type': 'non-cash',
        'icon': 'qr_code',
        'description':
            'Pembayaran non-tunai dengan QR code (Gopay, OVO, Dana, LinkAja, dll)',
        'status': 'active',
        'created_at': now,
      },
      {
        'name': 'Kartu Debit/Kredit',
        'type': 'non-cash',
        'icon': 'credit_card',
        'description': 'Pembayaran geser kartu debit atau kredit EDC',
        'status': 'active',
        'created_at': now,
      },
    ];

    for (var option in defaultPaymentOptions) {
      await db.insert('payment_options', option);
    }
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
