import 'package:sqflite/sqflite.dart' hide DatabaseException;
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'dart:io';

// Removed unused model imports and uuid package (not used in this service)
import '../utils/constants.dart';
import '../utils/app_exceptions.dart';
import '../utils/error_handler.dart';

/// Database service for managing local SQLite database operations
/// 
/// Provides singleton access to the SQLite database with support for:
/// - User-specific databases (one per authenticated user)
/// - CRUD operations for products, customers, and transactions
/// - Database initialization and schema management
/// - Safe error handling and validation
/// 
/// Usage:
/// ```dart
/// final db = DatabaseService.instance;
/// await db.initializeDatabase();
/// final products = await db.getAllProducts();
/// ```
class DatabaseService with ErrorHandlingMixin {
  static final Map<String, DatabaseService> _instances = {};
  static DatabaseService? _currentInstance;
  
  final String? _userId;
  
  factory DatabaseService({String? userId}) {
    final key = userId ?? 'default';
    _instances.putIfAbsent(key, () => DatabaseService._internal(userId));
    _currentInstance = _instances[key];
    return _instances[key]!;
  }
  
  DatabaseService._internal(this._userId);

  static Database? _database;

  /* --------------------  initialisation  -------------------- */
  
  /// Get or create the database instance
  /// 
  /// Lazy-loads the database on first access
  Future<Database> get database async => _database ??= await _initDatabase();

  /// Initialize the database connection and create tables if needed
  /// 
  /// This should be called once during app startup
  /// Throws [DatabaseException] if initialization fails
  Future<Database> _initDatabase() async {
    try {
      final path = await getDatabasesPath();
      
      // Create user-specific database path
      final dbName = _userId != null 
          ? 'pos_user_$_userId.db'
          : AppConstants.databaseName;
      final dbPath = join(path, dbName);

      return openDatabase(
        dbPath,
        version: AppConstants.databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } catch (e, st) {
      throw DatabaseException(
        message: 'Failed to initialize database',
        originalError: e,
        stackTrace: st,
      );
    }
  }

  /// Initialize the database (triggers lazy loading if not initialized)
  Future<void> initializeDatabase() async => await database;
  
  /// Switch to a different user's database
  /// 
  /// Clears the current database connection and switches to the new user's database.
  /// If switching from an authenticated user to default, the authenticated database
  /// is deleted to prevent data leakage.
  /// 
  /// [userId]: The user ID to switch to, or null for default/anonymous database
  static Future<void> switchUser(String? userId) async {
    try {
      _database = null;
      final key = userId ?? 'default';
      _currentInstance = _instances[key] ?? DatabaseService(userId: userId);
      
      // If switching to a user-specific database, clean up the default database
      // to prevent data leakage between user sessions
      if (userId != null) {
        await _deleteDefaultDatabase();
      }
    } catch (e, st) {
      ErrorHandler.handleError(e, stackTrace: st, tag: 'switchUser');
    }
  }
  
  /// Delete the default (unauthenticated) database
  /// 
  /// Called during user login to prevent unauthorized data persistence
  static Future<void> _deleteDefaultDatabase() async {
    try {
      final path = await getDatabasesPath();
      final dbPath = join(path, AppConstants.databaseName);
      final file = File(dbPath);
      if (await file.exists()) {
        await file.delete();
        debugPrint('Deleted default database to prevent data leakage');
      }
    } catch (e) {
      debugPrint('Error deleting default database: $e');
    }
  }
  
  /// Get the current active database instance
  static DatabaseService get instance => _currentInstance ?? DatabaseService();

  /* --------------------  schema & seed  -------------------- */
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        price REAL NOT NULL,
        cost REAL NOT NULL,
        stock INTEGER NOT NULL DEFAULT 0,
        minStock INTEGER NOT NULL DEFAULT 0,
        barcode TEXT,
        imagePath TEXT,
        category TEXT NOT NULL,
        isActive INTEGER NOT NULL DEFAULT 1,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');
    await db
        .execute('CREATE INDEX idx_products_category ON products(category)');
    await db.execute('CREATE INDEX idx_products_barcode ON products(barcode)');

    await db.execute('''
      CREATE TABLE customers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        address TEXT,
        creditLimit REAL NOT NULL DEFAULT 0,
        currentBalance REAL NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        notes TEXT,
        isActive INTEGER NOT NULL DEFAULT 1
      )
    ''');
    await db.execute('CREATE INDEX idx_customers_name ON customers(name)');

    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        timestamp TEXT NOT NULL,
        items TEXT NOT NULL,
        subtotal REAL NOT NULL,
        tax REAL NOT NULL,
        discount REAL NOT NULL,
        total REAL NOT NULL,
        paymentMethod TEXT NOT NULL,
        status TEXT NOT NULL,
        customerId TEXT,
        customerName TEXT,
        notes TEXT,
        receiptNumber TEXT,
        refundedAt TEXT,
        refundedBy TEXT,
        FOREIGN KEY (customerId) REFERENCES customers(id)
      )
    ''');
    await db.execute(
        'CREATE INDEX idx_transactions_timestamp ON transactions(timestamp)');
    await db.execute(
        'CREATE INDEX idx_transactions_customer ON transactions(customerId)');

    await db.execute('''
      CREATE TABLE credit_payments (
        id TEXT PRIMARY KEY,
        customerId TEXT NOT NULL,
        amount REAL NOT NULL,
        timestamp TEXT NOT NULL,
        notes TEXT,
        transactionId TEXT,
        FOREIGN KEY (customerId) REFERENCES customers(id),
        FOREIGN KEY (transactionId) REFERENCES transactions(id)
      )
    ''');
    await db.execute(
        'CREATE INDEX idx_credit_payments_customer ON credit_payments(customerId)');

    await db.execute('''
      CREATE TABLE expenses (
        id TEXT PRIMARY KEY,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        description TEXT NOT NULL,
        date TEXT NOT NULL,
        receiptPath TEXT,
        vendor TEXT,
        notes TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_expenses_date ON expenses(date)');
    await db
        .execute('CREATE INDEX idx_expenses_category ON expenses(category)');

    // Inventory audit trail
    await db.execute('''
      CREATE TABLE inventory_audit (
        id TEXT PRIMARY KEY,
        productId TEXT NOT NULL,
        adjustment INTEGER NOT NULL,
        reason TEXT,
        timestamp TEXT NOT NULL,
        user TEXT
      )
    ''');
    await db.execute('CREATE INDEX idx_inventory_audit_product ON inventory_audit(productId)');

    // Note: Sample data insertion can be enabled via AppConstants.seedSampleData
  }

  Future<void> _onUpgrade(Database db, int oldV, int newV) async {}

  /* --------------------  generic CRUD  -------------------- */
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    final id = await db.insert(table, data);
    try {
      debugPrint('DB INSERT -> table: $table, data keys: ${data.keys.toList()}');
    } catch (_) {}
    return id;
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    return db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  Future<int> update(
    String table,
    Map<String, dynamic> data, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    final count = await db.update(table, data, where: where, whereArgs: whereArgs);
    try {
      debugPrint('DB UPDATE -> table: $table, where: $where, whereArgs: $whereArgs, keys: ${data.keys.toList()}');
    } catch (_) {}
    return count;
  }

  Future<int> delete(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    final count = await db.delete(table, where: where, whereArgs: whereArgs);
    try {
      debugPrint('DB DELETE -> table: $table, where: $where, whereArgs: $whereArgs');
    } catch (_) {}
    return count;
  }

  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<dynamic>? arguments,
  ]) async {
    final db = await database;
    final result = await db.rawQuery(sql, arguments);
    try {
      debugPrint('DB RAW QUERY -> sql: $sql, args: $arguments, rows: ${result.length}');
    } catch (_) {}
    return result;
  }

  Future<int> rawUpdate(String sql, [List<dynamic>? arguments]) async {
    final db = await database;
    final count = await db.rawUpdate(sql, arguments);
    try {
      debugPrint('DB RAW UPDATE -> sql: $sql, args: $arguments, affected: $count');
    } catch (_) {}
    return count;
  }

  /* --------------------  transactions / batch  -------------------- */
  Future<T> transaction<T>(Future<T> Function(Transaction) action) async {
    final db = await database;
    return db.transaction(action);
  }

  Future<void> batch(Function(Batch) operations) async {
    final db = await database;
    final batch = db.batch();
    operations(batch);
    await batch.commit(noResult: true);
  }

  /* --------------------  lifecycle  -------------------- */
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  Future<void> deleteDatabase() async {
    final path = await getDatabasesPath();
    final dbName = _userId != null 
        ? 'pos_user_$_userId.db'
        : AppConstants.databaseName;
    final dbPath = join(path, dbName);
    await databaseFactory.deleteDatabase(dbPath);
    _database = null;
  }
}
