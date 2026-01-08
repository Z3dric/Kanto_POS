import 'package:flutter/material.dart';

/* ==========================  ENUM  ========================== */
enum ExpenseCategory {
  rent,
  utilities,
  supplies,
  inventory,
  marketing,
  salaries,
  maintenance,
  transportation,
  personal,
  other,
}

/* ====================  EXTENSION ON ENUM  =================== */
extension ExpenseCategoryX on ExpenseCategory {
  /// Human-readable caption used in chips, dropdowns, cards, etc.
  String get categoryDisplayName {
    switch (this) {
      case ExpenseCategory.rent:
        return 'Rent';
      case ExpenseCategory.utilities:
        return 'Utilities';
      case ExpenseCategory.supplies:
        return 'Supplies';
      case ExpenseCategory.inventory:
        return 'Inventory';
      case ExpenseCategory.marketing:
        return 'Marketing';
      case ExpenseCategory.salaries:
        return 'Salaries';
      case ExpenseCategory.maintenance:
        return 'Maintenance';
      case ExpenseCategory.transportation:
        return 'Transportation';
      case ExpenseCategory.personal:
        return 'Personal';
      case ExpenseCategory.other:
        return 'Other';
    }
  }

  /// Icon that belongs to the category.
  IconData get icon {
    switch (this) {
      case ExpenseCategory.rent:
        return Icons.home;
      case ExpenseCategory.utilities:
        return Icons.bolt;
      case ExpenseCategory.supplies:
        return Icons.shopping_basket;
      case ExpenseCategory.inventory:
        return Icons.inventory;
      case ExpenseCategory.marketing:
        return Icons.campaign;
      case ExpenseCategory.salaries:
        return Icons.people;
      case ExpenseCategory.maintenance:
        return Icons.build;
      case ExpenseCategory.transportation:
        return Icons.directions_car;
      case ExpenseCategory.personal:
        return Icons.person;
      case ExpenseCategory.other:
        return Icons.more_horiz;
    }
  }

  /// Colour that belongs to the category.
  Color get color {
    switch (this) {
      case ExpenseCategory.rent:
        return const Color(0xFF6200EE); // primary
      case ExpenseCategory.utilities:
        return const Color(0xFF2196F3); // info
      case ExpenseCategory.supplies:
        return const Color(0xFF4CAF50); // success
      case ExpenseCategory.inventory:
        return const Color(0xFFFF9800); // warning
      case ExpenseCategory.marketing:
        return const Color(0xFF03DAC6); // secondary
      case ExpenseCategory.salaries:
        return const Color(0xFFB00020); // error
      case ExpenseCategory.maintenance:
        return Colors.purple;
      case ExpenseCategory.transportation:
        return Colors.orange;
      case ExpenseCategory.personal:
        return Colors.pink;
      case ExpenseCategory.other:
        return const Color(0xFF757575); // muted
    }
  }
}

/* =========================  MODEL  ========================== */
class Expense {
  final String id;
  final double amount;
  final ExpenseCategory category;
  final String description;
  final DateTime date;
  final String? receiptPath;
  final String? vendor;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Expense({
    required this.id,
    required this.amount,
    required this.category,
    required this.description,
    required this.date,
    this.receiptPath,
    this.vendor,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  /* --------------------  COPY-WITH  -------------------- */
  Expense copyWith({
    String? id,
    double? amount,
    ExpenseCategory? category,
    String? description,
    DateTime? date,
    String? receiptPath,
    String? vendor,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Expense(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      description: description ?? this.description,
      date: date ?? this.date,
      receiptPath: receiptPath ?? this.receiptPath,
      vendor: vendor ?? this.vendor,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /* --------------------  TO-MAP  -------------------- */
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'category': category.name, // enum -> string
      'description': description,
      'date': date.toIso8601String(),
      'receiptPath': receiptPath,
      'vendor': vendor,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /* ------------------  FROM-MAP  ------------------ */
  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      amount: map['amount'],
      category: ExpenseCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => ExpenseCategory.other,
      ),
      description: map['description'],
      date: DateTime.parse(map['date']),
      receiptPath: map['receiptPath'],
      vendor: map['vendor'],
      notes: map['notes'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  /* ------------------  TO-STRING  ------------------ */
  @override
  String toString() =>
      'Expense(id: $id, amount: $amount, category: $category, date: $date)';
}
