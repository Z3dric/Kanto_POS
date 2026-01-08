/* Custom exception classes for the POS application
 
 This module provides a comprehensive exception hierarchy for handling
 various error scenarios throughout the application. */

/// Base exception class for all POS app exceptions
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  AppException({
    required this.message,
    this.code,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() => message;

  /// Get user-friendly error message
  String getUserMessage() => message;

  /// Get detailed error information for logging
  String getDetailedMessage() {
    final buffer = StringBuffer()
      ..writeln('Error: $message')
      ..writeln('Code: $code')
      ..writeln('Type: ${runtimeType.toString()}');

    if (originalError != null) {
      buffer.writeln('Original Error: $originalError');
    }

    return buffer.toString();
  }
}

/// Database-related errors
class DatabaseException extends AppException {
  DatabaseException({
    required super.message,
    super.code = 'DB_ERROR',
    super.originalError,
    super.stackTrace,
  });
}

/// Authentication and authorization errors
class AuthException extends AppException {
  AuthException({
    required super.message,
    super.code = 'AUTH_ERROR',
    super.originalError,
    super.stackTrace,
  });
}

/// Input validation errors
class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;

  ValidationException({
    required super.message,
    super.code = 'VALIDATION_ERROR',
    this.fieldErrors,
    super.originalError,
    super.stackTrace,
  });

  @override
  String getUserMessage() {
    if (fieldErrors?.isNotEmpty ?? false) {
      return fieldErrors!.values.join('\n');
    }
    return message;
  }
}

/// Business logic errors (e.g., insufficient stock, invalid transaction)
class BusinessLogicException extends AppException {
  BusinessLogicException({
    required super.message,
    super.code = 'BUSINESS_ERROR',
    super.originalError,
    super.stackTrace,
  });
}

/// Inventory-specific errors
class InventoryException extends BusinessLogicException {
  final String? productId;
  final int? requiredQuantity;
  final int? availableQuantity;

  InventoryException({
    required super.message,
    super.code = 'INVENTORY_ERROR',
    this.productId,
    this.requiredQuantity,
    this.availableQuantity,
    super.originalError,
    super.stackTrace,
  });

  @override
  String getDetailedMessage() {
    final buffer = StringBuffer()
      ..writeln(super.getDetailedMessage())
      ..writeln('Product ID: $productId')
      ..writeln('Required: $requiredQuantity, Available: $availableQuantity');

    return buffer.toString();
  }
}

/// Network/Firebase errors
class NetworkException extends AppException {
  NetworkException({
    required super.message,
    super.code = 'NETWORK_ERROR',
    super.originalError,
    super.stackTrace,
  });
}

/// Payment processing errors
class PaymentException extends AppException {
  final double? amount;
  final String? paymentMethod;

  PaymentException({
    required super.message,
    super.code = 'PAYMENT_ERROR',
    this.amount,
    this.paymentMethod,
    super.originalError,
    super.stackTrace,
  });
}

/// Resource not found errors
class NotFoundException extends AppException {
  final String? resourceType;
  final String? resourceId;

  NotFoundException({
    required super.message,
    super.code = 'NOT_FOUND',
    this.resourceType,
    this.resourceId,
    super.originalError,
    super.stackTrace,
  });
}

/// File/IO errors
class FileException extends AppException {
  FileException({
    required super.message,
    super.code = 'FILE_ERROR',
    super.originalError,
    super.stackTrace,
  });
}
