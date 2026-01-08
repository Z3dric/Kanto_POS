/* Result wrapper for safe return values from operations
 
 This module provides a Result type that can hold either a success value or an error */

import 'app_exceptions.dart';

/// Result type that can hold either a value (success) or an error (failure)
/// 
/// Usage:
/// ```dart
/// Result<Product> result = await productService.getProduct(id);
/// result.when(
///   success: (product) => print('Got product: ${product.name}'),
///   error: (error) => print('Error: ${error.message}'),
/// );
/// ```
abstract class Result<T> {
  /// Create a success result
  factory Result.success(T value) => Success(value);

  /// Create an error result
  factory Result.error(AppException error) => Error(error);

  /// Create an error result from a generic exception
  factory Result.errorFromException(
    dynamic exception,
    StackTrace? stackTrace,
  ) =>
      Error(BusinessLogicException(
        message: exception.toString(),
        originalError: exception,
        stackTrace: stackTrace,
      ));

  /// Execute callbacks based on result state
  Future<R> when<R>({
    required Future<R> Function(T value) success,
    required Future<R> Function(AppException error) error,
  });

  /// Execute callbacks based on result state (synchronous)
  R whenSync<R>({
    required R Function(T value) success,
    required R Function(AppException error) error,
  });

  /// Map success value to another type
  Result<R> map<R>(R Function(T value) mapper) {
    return whenSync(
      success: (value) => Result.success(mapper(value)),
      error: (error) => Result.error(error),
    );
  }

  /// Flat map (chain) operations
  Result<R> flatMap<R>(Result<R> Function(T value) mapper) {
    return whenSync(
      success: (value) => mapper(value),
      error: (error) => Result.error(error),
    );
  }

  /// Get value or null
  T? getOrNull();

  /// Get error or null
  AppException? getErrorOrNull();

  /// Check if result is success
  bool get isSuccess;

  /// Check if result is error
  bool get isError;

  /// Get the value or throw error
  T getOrThrow();
}

/// Success result containing a value
class Success<T> implements Result<T> {
  final T value;

  Success(this.value);

  @override
  Future<R> when<R>({
    required Future<R> Function(T value) success,
    required Future<R> Function(AppException error) error,
  }) {
    return success(value);
  }

  @override
  R whenSync<R>({
    required R Function(T value) success,
    required R Function(AppException error) error,
  }) {
    return success(value);
  }

  @override
  Result<R> map<R>(R Function(T value) mapper) {
    return Result.success(mapper(value));
  }

  @override
  Result<R> flatMap<R>(Result<R> Function(T value) mapper) {
    return mapper(value);
  }

  @override
  T? getOrNull() => value;

  @override
  AppException? getErrorOrNull() => null;

  @override
  bool get isSuccess => true;

  @override
  bool get isError => false;

  @override
  T getOrThrow() => value;

  @override
  String toString() => 'Success($value)';
}

/// Error result containing an exception
class Error<T> implements Result<T> {
  final AppException error;

  Error(this.error);

  @override
  Future<R> when<R>({
    required Future<R> Function(T value) success,
    required Future<R> Function(AppException error) error,
  }) {
    return error(this.error);
  }

  @override
  R whenSync<R>({
    required R Function(T value) success,
    required R Function(AppException error) error,
  }) {
    return error(this.error);
  }

  @override
  Result<R> map<R>(R Function(T value) mapper) {
    return Result.error(error);
  }

  @override
  Result<R> flatMap<R>(Result<R> Function(T value) mapper) {
    return Result.error(error);
  }

  @override
  T? getOrNull() => null;

  @override
  AppException? getErrorOrNull() => error;

  @override
  bool get isSuccess => false;

  @override
  bool get isError => true;

  @override
  T getOrThrow() => throw error;

  @override
  String toString() => 'Error($error)';
}

/// Extension for easier Result creation and handling
extension FutureResultExt<T> on Future<T> {
  /// Convert a Future to a Result, catching any exceptions
  Future<Result<T>> asResult() async {
    try {
      return Result.success(await this);
    } catch (e, st) {
      return Result.errorFromException(e, st);
    }
  }
}
