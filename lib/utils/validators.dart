/* Input validators for the POS application
 
 This module provides validation functions for various user inputs
 such as product prices, quantities, customer information, etc. */

import 'app_exceptions.dart';

/// Validator class for various input types
class Validators {
  /// Validate product name
  /// 
  /// Returns: null if valid, error message if invalid
  static String? validateProductName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Product name is required';
    }
    if (value.length < 2) {
      return 'Product name must be at least 2 characters';
    }
    if (value.length > 100) {
      return 'Product name must not exceed 100 characters';
    }
    return null;
  }

  /// Validate product price
  static String? validatePrice(String? value, {bool allowZero = false}) {
    if (value == null || value.isEmpty) {
      return 'Price is required';
    }

    final price = double.tryParse(value);
    if (price == null) {
      return 'Please enter a valid price';
    }

    if (price < 0) {
      return 'Price cannot be negative';
    }

    if (!allowZero && price == 0) {
      return 'Price cannot be zero';
    }

    if (price > 999999.99) {
      return 'Price is too high';
    }

    return null;
  }

  /// Validate quantity
  static String? validateQuantity(String? value, {int maxQuantity = 999999}) {
    if (value == null || value.isEmpty) {
      return 'Quantity is required';
    }

    final quantity = int.tryParse(value);
    if (quantity == null) {
      return 'Please enter a valid quantity';
    }

    if (quantity <= 0) {
      return 'Quantity must be greater than 0';
    }

    if (quantity > maxQuantity) {
      return 'Quantity exceeds maximum allowed ($maxQuantity)';
    }

    return null;
  }

  /// Validate stock level
  static String? validateStock(String? value) {
    if (value == null || value.isEmpty) {
      return 'Stock is required';
    }

    final stock = int.tryParse(value);
    if (stock == null) {
      return 'Please enter a valid stock level';
    }

    if (stock < 0) {
      return 'Stock cannot be negative';
    }

    return null;
  }

  /// Validate barcode
  static String? validateBarcode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Barcode is required';
    }

    if (value.length < 4) {
      return 'Barcode must be at least 4 characters';
    }

    if (value.length > 50) {
      return 'Barcode must not exceed 50 characters';
    }

    return null;
  }

  /// Validate category name
  static String? validateCategory(String? value) {
    if (value == null || value.isEmpty) {
      return 'Category is required';
    }

    if (value.length < 2) {
      return 'Category must be at least 2 characters';
    }

    if (value.length > 50) {
      return 'Category must not exceed 50 characters';
    }

    return null;
  }

  /// Validate customer name
  static String? validateCustomerName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Customer name is required';
    }

    if (value.length < 2) {
      return 'Customer name must be at least 2 characters';
    }

    if (value.length > 100) {
      return 'Customer name must not exceed 100 characters';
    }

    return null;
  }

  /// Validate phone number
  static String? validatePhoneNumber(String? value, {bool required = false}) {
    if (value == null || value.isEmpty) {
      return required ? 'Phone number is required' : null;
    }

    if (value.length < 7) {
      return 'Phone number must be at least 7 characters';
    }

    if (value.length > 20) {
      return 'Phone number must not exceed 20 characters';
    }

    // Check if it contains at least one digit
    if (!value.contains(RegExp(r'\d'))) {
      return 'Phone number must contain at least one digit';
    }

    return null;
  }

  /// Validate email
  static String? validateEmail(String? value, {bool required = false}) {
    if (value == null || value.isEmpty) {
      return required ? 'Email is required' : null;
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  /// Validate discount percentage
  static String? validateDiscount(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Discount is optional
    }

    final discount = double.tryParse(value);
    if (discount == null) {
      return 'Please enter a valid discount';
    }

    if (discount < 0 || discount > 100) {
      return 'Discount must be between 0 and 100';
    }

    return null;
  }

  /// Validate minimum stock level
  static String? validateMinStock(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Min stock is optional
    }

    final minStock = int.tryParse(value);
    if (minStock == null) {
      return 'Please enter a valid minimum stock level';
    }

    if (minStock < 0) {
      return 'Minimum stock cannot be negative';
    }

    return null;
  }

  /// Validate credit limit
  static String? validateCreditLimit(String? value) {
    if (value == null || value.isEmpty) {
      return 'Credit limit is required';
    }

    final limit = double.tryParse(value);
    if (limit == null) {
      return 'Please enter a valid credit limit';
    }

    if (limit <= 0) {
      return 'Credit limit must be greater than 0';
    }

    return null;
  }

  /// Validate password
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }

    if (value.length > 100) {
      return 'Password is too long';
    }

    return null;
  }

  /// Validate that a required field is not empty
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }
}

/// Batch validator for multiple fields
class BatchValidator {
  final Map<String, String> _errors = {};

  /// Add validation error for a field
  void addError(String fieldName, String? error) {
    if (error != null) {
      _errors[fieldName] = error;
    }
  }

  /// Check if there are any errors
  bool get hasErrors => _errors.isNotEmpty;

  /// Get all errors
  Map<String, String> get errors => Map.unmodifiable(_errors);

  /// Get first error message
  String? get firstError => _errors.values.isNotEmpty ? _errors.values.first : null;

  /// Clear all errors
  void clear() => _errors.clear();

  /// Throw ValidationException if there are errors
  void throwIfInvalid() {
    if (hasErrors) {
      throw ValidationException(
        message: 'Validation failed',
        fieldErrors: errors,
      );
    }
  }
}
