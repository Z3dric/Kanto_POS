import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:kanto_pos/models/sale.dart';
import 'package:kanto_pos/models/expense.dart';
import 'package:kanto_pos/models/customer.dart';
import 'database_service.dart';

class ReportService extends ChangeNotifier {
  ReportService();
  
  // Get current database service instance
  DatabaseService get _databaseService => DatabaseService.instance;

  /* ====================  SALES REPORT  ==================== */
  Future<Map<String, dynamic>> getSalesReport({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _databaseService.database;

    String whereClause = 'status = ?';
    List<dynamic> whereArgs = [TransactionStatus.completed.name];

    if (startDate != null && endDate != null) {
      whereClause += ' AND DATE(timestamp) BETWEEN DATE(?) AND DATE(?)';
      whereArgs.add(startDate.toIso8601String());
      whereArgs.add(endDate.toIso8601String());
    }

    final transactions = await db.query(
      'transactions',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'timestamp DESC',
    );

    final saleList = transactions.map((map) => Sale.fromMap(map)).toList();

    double totalSales = 0,
        totalTax = 0,
        totalDiscount = 0,
        cashSales = 0,
        creditSales = 0;
    int totalItems = 0, cashTx = 0, creditTx = 0;

    for (final sale in saleList) {
      totalSales += sale.total;
      totalTax += sale.tax;
      totalDiscount += sale.discount;
      totalItems += sale.totalItems;

      if (sale.paymentMethod == PaymentMethod.cash) {
        cashTx++;
        cashSales += sale.total;
      } else if (sale.paymentMethod == PaymentMethod.credit) {
        creditTx++;
        creditSales += sale.total;
      }
    }

    final totalTx = saleList.length;
    final avgValue = totalTx > 0 ? totalSales / totalTx : 0.0;

    return {
      'sales': saleList,
      'summary': {
        'totalSales': totalSales,
        'totalTax': totalTax,
        'totalDiscount': totalDiscount,
        'totalItems': totalItems,
        'totalTransactions': totalTx,
        'averageTransactionValue': avgValue,
        'cashTransactions': cashTx,
        'creditTransactions': creditTx,
        'cashSales': cashSales,
        'creditSales': creditSales,
      },
    };
  }

  /* ====================  DAILY SALES SUMMARY  ==================== */
  Future<List<Map<String, dynamic>>> getDailySalesSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _databaseService.database;
    final args = [TransactionStatus.completed.name];
    String dateFilter = '';

    if (startDate != null && endDate != null) {
      dateFilter = 'AND DATE(timestamp) BETWEEN DATE(?) AND DATE(?)';
      args.addAll([startDate.toIso8601String(), endDate.toIso8601String()]);
    }

    return db.rawQuery('''
      SELECT 
        DATE(timestamp) as date,
        COUNT(*) as transactionCount,
        SUM(total) as totalSales,
        SUM(tax) as totalTax,
        SUM(discount) as totalDiscount,
        SUM(subtotal) as subtotal
      FROM transactions 
      WHERE status = ? $dateFilter
      GROUP BY DATE(timestamp)
      ORDER BY date DESC
    ''', args);
  }

  /* ====================  PRODUCT PERFORMANCE  ==================== */
  Future<List<Map<String, dynamic>>> getProductPerformanceReport({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final args = [TransactionStatus.completed.name];
    if (startDate != null) args.add(startDate.toIso8601String());
    if (endDate != null) args.add(endDate.toIso8601String());

    return _databaseService.rawQuery('''
      SELECT 
        p.id,
        p.name,
        p.category,
        p.price,
        p.cost,
        p.stock,
        COALESCE(SUM(ti.quantity), 0) as totalQuantitySold,
        COALESCE(SUM(ti.subtotal), 0) as totalRevenue,
        COALESCE(SUM(ti.quantity * p.cost), 0) as totalCost,
        COALESCE(SUM(ti.subtotal - (ti.quantity * p.cost)), 0) as totalProfit
      FROM products p
      LEFT JOIN (
        SELECT 
          json_extract(value, '\$.productId') as productId,
          json_extract(value, '\$.quantity') as quantity,
          json_extract(value, '\$.subtotal') as subtotal
        FROM transactions, json_each(items)
        WHERE status = ?
          ${startDate != null && endDate != null ? 'AND DATE(timestamp) BETWEEN DATE(?) AND DATE(?)' : ''}
      ) ti ON p.id = ti.productId
      WHERE p.isActive = 1
      GROUP BY p.id, p.name, p.category, p.price, p.cost, p.stock
      ORDER BY totalRevenue DESC
    ''', args);
  }

  /* ====================  CATEGORY PERFORMANCE  ==================== */
  Future<List<Map<String, dynamic>>> getCategoryPerformanceReport({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final args = [TransactionStatus.completed.name];
    if (startDate != null) args.add(startDate.toIso8601String());
    if (endDate != null) args.add(endDate.toIso8601String());

    return _databaseService.rawQuery('''
      SELECT 
        p.category,
        COUNT(DISTINCT p.id) as productCount,
        COALESCE(SUM(ti.quantity), 0) as totalQuantitySold,
        COALESCE(SUM(ti.subtotal), 0) as totalRevenue,
        COALESCE(SUM(ti.quantity * p.cost), 0) as totalCost,
        COALESCE(SUM(ti.subtotal - (ti.quantity * p.cost)), 0) as totalProfit,
        COALESCE(AVG(p.stock), 0) as avgStock
      FROM products p
      LEFT JOIN (
        SELECT 
          json_extract(value, '\$.productId') as productId,
          json_extract(value, '\$.quantity') as quantity,
          json_extract(value, '\$.subtotal') as subtotal
        FROM transactions, json_each(items)
        WHERE status = ?
          ${startDate != null && endDate != null ? 'AND DATE(timestamp) BETWEEN DATE(?) AND DATE(?)' : ''}
      ) ti ON p.id = ti.productId
      WHERE p.isActive = 1
      GROUP BY p.category
      ORDER BY totalRevenue DESC
    ''', args);
  }

  /* ====================  EXPENSE REPORT  ==================== */
  Future<Map<String, dynamic>> getExpenseReport({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final whereArgs = <dynamic>[];
    var where = '1=1';
    if (startDate != null && endDate != null) {
      where += ' AND DATE(date) BETWEEN DATE(?) AND DATE(?)';
      whereArgs
          .addAll([startDate.toIso8601String(), endDate.toIso8601String()]);
    }

    final maps = await _databaseService.query('expenses',
        where: where, whereArgs: whereArgs, orderBy: 'date DESC');

    final expenseList = maps.map((e) => Expense.fromMap(e)).toList();

    final byCategory = <String, double>{};
    var total = 0.0;

    for (final e in expenseList) {
      total += e.amount;
      byCategory.update(e.category.categoryDisplayName, (v) => v + e.amount,
          ifAbsent: () => e.amount);
    }

    return {
      'expenses': expenseList,
      'totalExpenses': total,
      'categoryTotals': byCategory
    };
  }

  /* ====================  CREDIT REPORT  ==================== */
  Future<Map<String, dynamic>> getCreditReport() async {
    final db = await _databaseService.database;

    final customers = await db.rawQuery('''
      SELECT 
        c.*,
        COALESCE(SUM(t.total), 0) as totalCreditSales,
        COALESCE(SUM(cp.amount), 0) as totalPayments
      FROM customers c
      LEFT JOIN transactions t ON c.id = t.customerId 
        AND t.paymentMethod = ? AND t.status = ?
      LEFT JOIN credit_payments cp ON c.id = cp.customerId
      WHERE c.creditLimit > 0 OR c.currentBalance > 0
      GROUP BY c.id
      ORDER BY c.currentBalance DESC
    ''', [PaymentMethod.credit.name, TransactionStatus.completed.name]);

    final payments = await db.rawQuery('''
      SELECT 
        cp.*,
        c.name as customerName
      FROM credit_payments cp
      JOIN customers c ON cp.customerId = c.id
      ORDER BY cp.timestamp DESC
      LIMIT 50
    ''');

    return {
      'customers': customers.map((m) => Customer.fromMap(m)).toList(),
      'payments': payments,
    };
  }

  /* ====================  PROFIT & LOSS  ==================== */
  Future<Map<String, dynamic>> getProfitLossReport({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final sales = await getSalesReport(startDate: startDate, endDate: endDate);
    final expenses =
        await getExpenseReport(startDate: startDate, endDate: endDate);

    final cogsRes = await _databaseService.rawQuery('''
      SELECT 
        COALESCE(SUM(json_extract(value, '\$.quantity') * p.cost), 0) as totalCOGS
      FROM transactions t, json_each(t.items)
      JOIN products p ON json_extract(value, '\$.productId') = p.id
      WHERE t.status = ?
        ${startDate != null && endDate != null ? ' AND DATE(t.timestamp) BETWEEN DATE(?) AND DATE(?)' : ''}
    ''', [
      TransactionStatus.completed.name,
      if (startDate != null) startDate.toIso8601String(),
      if (endDate != null) endDate.toIso8601String(),
    ]);

    final totalCOGS = cogsRes.first['totalCOGS'] as double? ?? 0.0;
    final totalSales = sales['summary']['totalSales'] as double? ?? 0.0;
    final totalTax = sales['summary']['totalTax'] as double? ?? 0.0;
    final totalExp = expenses['totalExpenses'] as double? ?? 0.0;

    final grossProfit = totalSales - totalCOGS;
    final netProfit = grossProfit - totalExp;

    return {
      'totalSales': totalSales,
      'totalCOGS': totalCOGS,
      'grossProfit': grossProfit,
      'grossProfitMargin':
          totalSales > 0 ? (grossProfit / totalSales) * 100 : 0,
      'totalExpenses': totalExp,
      'netProfit': netProfit,
      'netProfitMargin': totalSales > 0 ? (netProfit / totalSales) * 100 : 0,
      'totalTax': totalTax,
    };
  }

  /* ====================  DASHBOARD  ==================== */
  Future<Map<String, dynamic>> getDashboardSummary() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);

    final todaySales = await getSalesReport(startDate: today, endDate: now);
    final weekSales = await getSalesReport(startDate: weekStart, endDate: now);
    final monthSales =
        await getSalesReport(startDate: monthStart, endDate: now);

    final db = await _databaseService.database;
    final creditRes = await db.rawQuery('''
      SELECT COUNT(*) as cnt, SUM(currentBalance) as outstanding
      FROM customers WHERE currentBalance > 0
    ''');
    final lowStockRes = await db.rawQuery('''
      SELECT COUNT(*) as cnt FROM products
      WHERE stock <= minStock AND minStock > 0 AND isActive = 1
    ''');

    return {
      'todaySales': todaySales['summary']['totalSales'],
      'weekSales': weekSales['summary']['totalSales'],
      'monthSales': monthSales['summary']['totalSales'],
      'outstandingCredit': creditRes.first['outstanding'] ?? 0.0,
      'creditCustomers': creditRes.first['cnt'] ?? 0,
      'lowStockProducts': lowStockRes.first['cnt'] ?? 0,
    };
  }

  /* ====================  CSV EXPORT  ==================== */
  Future<List<List<dynamic>>> getSalesExportData({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final report = await getSalesReport(startDate: startDate, endDate: endDate);
    final sales = report['sales'] as List<Sale>;

    return [
      [
        'Date',
        'Receipt #',
        'Customer',
        'Items',
        'Subtotal',
        'Tax',
        'Discount',
        'Total',
        'Payment',
        'Status'
      ],
      ...sales.map((s) => [
            DateFormat('yyyy-MM-dd HH:mm').format(s.timestamp),
            s.receiptNumber ?? '',
            s.customerName ?? 'Walk-in',
            s.totalItems,
            s.subtotal,
            s.tax,
            s.discount,
            s.total,
            s.paymentMethod.name,
            s.status.name,
          ])
    ];
  }

  Future<List<List<dynamic>>> getExpenseExportData({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final report =
        await getExpenseReport(startDate: startDate, endDate: endDate);
    final expenses = report['expenses'] as List<Expense>;

    return [
      ['Date', 'Category', 'Description', 'Amount', 'Vendor', 'Notes'],
      ...expenses.map((e) => [
            DateFormat('yyyy-MM-dd').format(e.date),
            e.category.categoryDisplayName,
            e.description,
            e.amount,
            e.vendor ?? 'N/A',
            e.notes ?? '',
          ])
    ];
  }
}
