/* Error handling utilities for the POS application
 
 This module provides centralized error handling, logging, and user notification */

import 'package:flutter/foundation.dart';
import 'app_exceptions.dart';

/// Callback type for error logging
typedef ErrorLogCallback = void Function(String message);

/// Central error handler for the application
class ErrorHandler {
  static final ErrorHandler _instance = ErrorHandler._internal();
  static ErrorLogCallback? _logCallback;

  factory ErrorHandler() {
    return _instance;
  }

  ErrorHandler._internal();

  /// Set error log callback (for integration with logging services)
  static void setLogCallback(ErrorLogCallback callback) {
    _logCallback = callback;
  }

  /// Handle and log an error
  static void handleError(
    dynamic error, {
    StackTrace? stackTrace,
    String? tag,
    bool shouldRethrow = false,
  }) {
    final AppException appException = _toAppException(error, stackTrace);

    _logError(appException, tag: tag);

    if (shouldRethrow) {
      throw appException;
    }
  }

  /// Convert any error to AppException
  static AppException _toAppException(
    dynamic error,
    StackTrace? stackTrace,
  ) {
    if (error is AppException) {
      return error;
    }

    if (error is Exception) {
      return BusinessLogicException(
        message: error.toString(),
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    return BusinessLogicException(
      message: 'An unexpected error occurred: $error',
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  /// Log error with optional tag
  static void _logError(
    AppException exception, {
    String? tag,
  }) {
    final timestamp = DateTime.now().toIso8601String();
    final tagStr = tag != null ? '[$tag] ' : '';
    final message =
        '$timestamp $tagStr${exception.getDetailedMessage()}';

    debugPrint(message);

    // Call custom log callback if set
    _logCallback?.call(message);
  }

  /// Safely execute a function with error handling
  static Future<T?> safeAsync<T>(
    Future<T> Function() operation, {
    String? operationName,
    T? defaultValue,
  }) async {
    try {
      return await operation();
    } catch (e, st) {
      handleError(e, stackTrace: st, tag: operationName);
      return defaultValue;
    }
  }

  /// Safely execute a synchronous function with error handling
  static T? safeSync<T>(
    T Function() operation, {
    String? operationName,
    T? defaultValue,
  }) {
    try {
      return operation();
    } catch (e, st) {
      handleError(e, stackTrace: st, tag: operationName);
      return defaultValue;
    }
  }

  /// Get user-friendly error message
  static String getUserMessage(dynamic error) {
    if (error is AppException) {
      return error.getUserMessage();
    }
    return 'An unexpected error occurred. Please try again.';
  }

  /// Check if error is a validation error
  static bool isValidationError(dynamic error) {
    return error is ValidationException;
  }

  /// Check if error is a network error
  static bool isNetworkError(dynamic error) {
    return error is NetworkException;
  }

  /// Check if error is a not found error
  static bool isNotFoundError(dynamic error) {
    return error is NotFoundException;
  }

  /// Check if error is an inventory error
  static bool isInventoryError(dynamic error) {
    return error is InventoryException;
  }
}

/// Mixin for error handling in widgets and services
mixin ErrorHandlingMixin {
  /// Handle error and notify listeners/UI
  void onError(dynamic error, StackTrace? stackTrace) {
    ErrorHandler.handleError(error, stackTrace: stackTrace);
  }

  /// Safely execute async operation with error handling
  Future<T?> safeAsyncOperation<T>(
    Future<T> Function() operation, {
    String? operationName,
    T? defaultValue,
  }) {
    return ErrorHandler.safeAsync<T?>(
      () => operation(),
      operationName: operationName,
      defaultValue: defaultValue,
    );
  }

  /// Safely execute sync operation with error handling
  T? safeSyncOperation<T>(
    T Function() operation, {
    String? operationName,
    T? defaultValue,
  }) {
    return ErrorHandler.safeSync<T?>(
      () => operation(),
      operationName: operationName,
      defaultValue: defaultValue,
    );
  }
}
