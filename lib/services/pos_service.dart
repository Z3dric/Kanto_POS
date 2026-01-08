import 'package:flutter/foundation.dart';
import 'package:kanto_pos/models/sale.dart';
import 'package:uuid/uuid.dart';
import '../models/product.dart';
import '../models/customer.dart';
import '../models/expense.dart';
import 'database_service.dart';

class POSService extends ChangeNotifier {
  final Uuid _uuid = const Uuid();

  final List<Sale> _transactions = [];
  final List<TransactionItem> _cartItems = [];
  Customer? _selectedCustomer;
  PaymentMethod? _paymentMethod = PaymentMethod.cash;
  double _taxRate = 0.0;
  double _discountAmount = 0.0;
  
  // Cache for summary data
  Map<String, dynamic>? _cachedSummary;
  DateTime? _lastSummaryCacheTime;
  static const int _summaryCacheDurationSeconds = 5;
  String? _currentUserId;

  POSService() {
    _loadTransactions();
  }
  
  // Get current database service instance
  DatabaseService get _databaseService => DatabaseService.instance;

  // Getters
  List<Sale> get transactions => _transactions;
  List<TransactionItem> get cartItems => _cartItems;
  Customer? get selectedCustomer => _selectedCustomer;
  PaymentMethod? get paymentMethod => _paymentMethod;
  double get taxRate => _taxRate;
  double get discountAmount => _discountAmount;

  double get cartSubtotal =>
      _cartItems.fold(0.0, (sum, item) => sum + item.subtotal);

  double get cartTax => cartSubtotal * _taxRate;

  double get cartTotal => cartSubtotal + cartTax - _discountAmount;

  int get cartItemCount =>
      _cartItems.fold(0, (sum, item) => sum + item.quantity);

  // Handle user change
  void updateUser(String? userId) {
    if (_currentUserId != userId) {
      _currentUserId = userId;
      // Clear local state
      _cartItems.clear();
      _selectedCustomer = null;
      _paymentMethod = PaymentMethod.cash;
      _transactions.clear();
      _clearSummaryCache();
      _loadTransactions();
    }
  }

  // Cart operations
  void addToCart(Product product, {int quantity = 1}) {
    final existingItemIndex =
        _cartItems.indexWhere((item) => item.productId == product.id);

    if (existingItemIndex >= 0) {
      final existingItem = _cartItems[existingItemIndex];
      _cartItems[existingItemIndex] = TransactionItem(
        productId: product.id,
        productName: product.name,
        price: product.price,
        quantity: existingItem.quantity + quantity,
        subtotal: product.price * (existingItem.quantity + quantity),
      );
    } else {
      _cartItems.add(TransactionItem(
        productId: product.id,
        productName: product.name,
        price: product.price,
        quantity: quantity,
        subtotal: product.price * quantity,
      ));
    }

    notifyListeners();
  }

  void removeFromCart(String productId) {
    _cartItems.removeWhere((item) => item.productId == productId);
    notifyListeners();
  }

  void updateCartQuantity(String productId, int newQuantity) {
    if (newQuantity <= 0) {
      removeFromCart(productId);
      return;
    }

    final index = _cartItems.indexWhere((item) => item.productId == productId);
    if (index >= 0) {
      final item = _cartItems[index];
      _cartItems[index] = TransactionItem(
        productId: item.productId,
        productName: item.productName,
        price: item.price,
        quantity: newQuantity,
        subtotal: item.price * newQuantity,
      );
      notifyListeners();
    }
  }

  void clearCart() {
    _cartItems.clear();
    _selectedCustomer = null;
    _discountAmount = 0.0;
    notifyListeners();
  }

  // Customer selection
  void selectCustomer(Customer customer) {
    _selectedCustomer = customer;
    notifyListeners();
  }

  void clearCustomer() {
    _selectedCustomer = null;
    notifyListeners();
  }

  // Payment method
  void setPaymentMethod(PaymentMethod? method) {
    _paymentMethod = method;
    notifyListeners();
  }

  // Discount
  void setDiscount(double amount) {
    _discountAmount = amount.clamp(0.0, cartSubtotal);
    notifyListeners();
  }

  // Tax rate
  void setTaxRate(double rate) {
    _taxRate = rate.clamp(0.0, 1.0);
    notifyListeners();
  }

  // Transaction processing
  Future<Sale?> processTransaction({String? notes}) async {
    if (_cartItems.isEmpty) {
      throw Exception('Cart is empty');
    }

    if (_paymentMethod == PaymentMethod.credit && _selectedCustomer == null) {
      throw Exception('Customer must be selected for credit transactions');
    }

    final result = await _databaseService.transaction((txn) async {
      final transactionId = _uuid.v4();
      final now = DateTime.now();

      // Create transaction
      final transaction = Sale(
        id: transactionId,
        timestamp: now,
        items: List.from(_cartItems),
        subtotal: cartSubtotal,
        tax: cartTax,
        discount: _discountAmount,
        total: cartTotal,
        paymentMethod: _paymentMethod!,
        status: TransactionStatus.completed,
        customerId: _selectedCustomer?.id,
        customerName: _selectedCustomer?.name,
        notes: notes,
        receiptNumber: _generateReceiptNumber(now),
      );

      // Insert transaction
      await txn.insert('transactions', transaction.toMap());

      // Update inventory
      for (final item in _cartItems) {
        await txn.rawUpdate('''
          UPDATE products 
          SET stock = stock - ? 
          WHERE id = ?
        ''', [item.quantity, item.productId]);
      }

      // Update customer balance if credit transaction
      if (_paymentMethod == PaymentMethod.credit && _selectedCustomer != null) {
        await txn.rawUpdate('''
          UPDATE customers 
          SET currentBalance = currentBalance + ? 
          WHERE id = ?
        ''', [cartTotal, _selectedCustomer!.id]);
      }

      // Clear cart
      clearCart();

      return transaction;
    });

    // Reload transactions and notify listeners after transaction completes
    await _loadTransactions();
    _clearSummaryCache();
    notifyListeners();

    return result;
  }

  // Refund transaction
  Future<void> refundTransaction(String transactionId, {String? reason}) async {
    await _databaseService.transaction((txn) async {
      // Get transaction
      final result = await txn.query(
        'transactions',
        where: 'id = ?',
        whereArgs: [transactionId],
      );

      if (result.isEmpty) {
        throw Exception('Transaction not found');
      }

      final transaction = Sale.fromMap(result.first);

      if (transaction.isRefunded) {
        throw Exception('Transaction already refunded');
      }

      // Update transaction status
      await txn.update(
        'transactions',
        {
          'status': TransactionStatus.refunded.name,
          'refundedAt': DateTime.now().toIso8601String(),
          'refundedBy': 'System', // TODO: Get current user
        },
        where: 'id = ?',
        whereArgs: [transactionId],
      );

      // Restore inventory
      for (final item in transaction.items) {
        await txn.rawUpdate('''
          UPDATE products 
          SET stock = stock + ? 
          WHERE id = ?
        ''', [item.quantity, item.productId]);
      }

      // Update customer balance if credit transaction
      if (transaction.isCredit && transaction.customerId != null) {
        await txn.rawUpdate('''
          UPDATE customers 
          SET currentBalance = currentBalance - ? 
          WHERE id = ?
        ''', [transaction.total, transaction.customerId]);
      }
    });

    await _loadTransactions();
    _clearSummaryCache();
  }

  // Credit payment processing
  Future<void> processCreditPayment(String customerId, double amount,
      {String? notes}) async {
    if (amount <= 0) {
      throw Exception('Invalid payment amount');
    }

    await _databaseService.transaction((txn) async {
      // Insert credit payment
      final paymentId = _uuid.v4();
      await txn.insert('credit_payments', {
        'id': paymentId,
        'customerId': customerId,
        'amount': amount,
        'timestamp': DateTime.now().toIso8601String(),
        'notes': notes,
      });

      // Update customer balance
      await txn.rawUpdate('''
        UPDATE customers 
        SET currentBalance = currentBalance - ? 
        WHERE id = ?
      ''', [amount, customerId]);
    });

    // Reload transactions to reflect changes
    await _loadTransactions();
    _clearSummaryCache();
    notifyListeners();
  }

  // Fetch customers from database
  Future<List<Customer>> getCustomers({bool activeOnly = true, String? query}) async {
    String? where = activeOnly ? 'isActive = 1' : null;
    List<dynamic>? whereArgs;

    if (query != null && query.isNotEmpty) {
      const searchClause = '(name LIKE ? OR phone LIKE ?)';
      where = where != null ? '$where AND $searchClause' : searchClause;
      whereArgs = ['%$query%', '%$query%'];
    }

    final maps = await _databaseService.query(
      'customers',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'name ASC',
    );

    return maps.map((m) => Customer.fromMap(m)).toList();
  }

  // Add a new customer to the database
  Future<Customer> addCustomer({
    required String name,
    String? phone,
    String? email,
    String? address,
    double creditLimit = 0.0,
    String? notes,
  }) async {
    final customerId = _uuid.v4();
    final now = DateTime.now();
    
    final customer = Customer(
      id: customerId,
      name: name,
      phone: phone,
      email: email,
      address: address,
      creditLimit: creditLimit,
      currentBalance: 0.0,
      createdAt: now,
      updatedAt: now,
      notes: notes,
      isActive: true,
    );

    await _databaseService.insert('customers', customer.toMap());
    return customer;
  }

  // Get credit summary statistics
  Future<Map<String, dynamic>> getCreditSummary() async {
    final customers = await getCustomers(activeOnly: true);
    
    double totalOutstanding = 0;
    int overdueAccounts = 0;
    
    for (final customer in customers) {
      if (customer.hasOutstandingBalance) {
        totalOutstanding += customer.currentBalance;
        if (customer.isOverCreditLimit) {
          overdueAccounts++;
        }
      }
    }
    
    return {
      'totalOutstanding': totalOutstanding,
      'totalCustomers': customers.length,
      'overdueAccounts': overdueAccounts,
    };
  }

  // Expenses
  Future<List<Expense>> getExpenses({ExpenseCategory? category, String? search}) async {
    String? where;
    final whereArgs = <dynamic>[];

    if (category != null) {
      where = 'category = ?';
      whereArgs.add(category.name);
    }

    if (search != null && search.isNotEmpty) {
      final q = '%$search%';
      if (where == null) {
        where = '(description LIKE ? OR vendor LIKE ? OR notes LIKE ?)';
      } else {
        where = '$where AND (description LIKE ? OR vendor LIKE ? OR notes LIKE ?)';
      }
      whereArgs.addAll([q, q, q]);
    }

    final maps = await _databaseService.query('expenses', where: where, whereArgs: whereArgs, orderBy: 'date DESC');
    return maps.map((m) => Expense.fromMap(m)).toList();
  }

  Future<void> addExpense(Expense expense) async {
    await _databaseService.insert('expenses', expense.toMap());
    notifyListeners();
  }

  // Data loading
  Future<void> _loadTransactions() async {
    final result = await _databaseService.query(
      'transactions',
      orderBy: 'timestamp DESC',
      limit: 100,
    );

    _transactions.clear();
    _transactions.addAll(result.map((map) => Sale.fromMap(map)).toList());
    _clearSummaryCache();
    notifyListeners();
  }

  // Analytics - with caching to prevent freezing
  Future<Map<String, dynamic>> getSalesSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Use local transactions list if no date filter (faster)
    if (startDate == null && endDate == null) {
      // Check cache first
      if (_cachedSummary != null && _lastSummaryCacheTime != null) {
        final now = DateTime.now();
        final duration = now.difference(_lastSummaryCacheTime!);
        if (duration.inSeconds < _summaryCacheDurationSeconds) {
          return _cachedSummary!;
        }
      }

      // Calculate from in-memory transactions
      final completedTransactions = _transactions
          .where((t) => t.status == TransactionStatus.completed)
          .toList();

      final totalSales =
          completedTransactions.fold(0.0, (sum, t) => sum + t.total);
      final totalTax =
          completedTransactions.fold(0.0, (sum, t) => sum + t.tax);
      final totalDiscount =
          completedTransactions.fold(0.0, (sum, t) => sum + t.discount);
      final totalItems =
          completedTransactions.fold(0, (sum, t) => sum + t.totalItems);
      final transactionCount = completedTransactions.length;

      final summary = {
        'summary': {
          'totalSales': totalSales,
          'totalTax': totalTax,
          'totalDiscount': totalDiscount,
          'totalItems': totalItems,
          'totalTransactions': transactionCount,
          'averageTransactionValue':
              transactionCount > 0 ? totalSales / transactionCount : 0,
        },
        'transactions': completedTransactions,
      };

      _cachedSummary = summary;
      _lastSummaryCacheTime = DateTime.now();
      return summary;
    }

    // For date range queries, use database
    final db = await _databaseService.database;

    String whereClause = 'status = ?';
    List<dynamic> whereArgs = [TransactionStatus.completed.name];

    if (startDate != null && endDate != null) {
      whereClause += ' AND timestamp BETWEEN ? AND ?';
      whereArgs.add(startDate.toIso8601String());
      whereArgs.add(endDate.toIso8601String());
    }

    final result = await db.query(
      'transactions',
      where: whereClause,
      whereArgs: whereArgs,
    );

    final transactions = result.map((map) => Sale.fromMap(map)).toList();

    final totalSales = transactions.fold(0.0, (sum, t) => sum + t.total);
    final totalTax = transactions.fold(0.0, (sum, t) => sum + t.tax);
    final totalDiscount = transactions.fold(0.0, (sum, t) => sum + t.discount);
    final totalItems = transactions.fold(0, (sum, t) => sum + t.totalItems);
    final transactionCount = transactions.length;

    return {
      'summary': {
        'totalSales': totalSales,
        'totalTax': totalTax,
        'totalDiscount': totalDiscount,
        'totalItems': totalItems,
        'totalTransactions': transactionCount,
        'averageTransactionValue':
            transactionCount > 0 ? totalSales / transactionCount : 0,
      },
      'transactions': transactions,
    };
  }

  // Clear cache when data changes
  void _clearSummaryCache() {
    _cachedSummary = null;
    _lastSummaryCacheTime = null;
  }

  // Helper methods
  String _generateReceiptNumber(DateTime timestamp) {
    final dateStr = timestamp.toString().substring(0, 10).replaceAll('-', '');
    final timeStr = timestamp.toString().substring(11, 19).replaceAll(':', '');
    return 'POS$dateStr$timeStr';
  }

  // Search and filtering
  Future<List<Sale>> searchTransactions(String query) async {
    final db = await _databaseService.database;
    final result = await db.rawQuery('''
      SELECT * FROM transactions 
      WHERE receiptNumber LIKE ? 
         OR customerName LIKE ? 
         OR notes LIKE ?
      ORDER BY timestamp DESC
    ''', ['%$query%', '%$query%', '%$query%']);

    return result.map((map) => Sale.fromMap(map)).toList();
  }
}
