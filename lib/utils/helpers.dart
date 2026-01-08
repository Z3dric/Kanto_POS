import 'dart:async';
import 'package:flutter/services.dart' as flutter_services;
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'constants.dart';

class HapticFeedback {
  static void lightImpact() {
    flutter_services.HapticFeedback.lightImpact();
  }

  static void mediumImpact() {
    flutter_services.HapticFeedback.mediumImpact();
  }

  static void heavyImpact() {
    flutter_services.HapticFeedback.heavyImpact();
  }
}

class Formatters {
  static String formatCurrency(double amount) {
    return '${AppConstants.currencySymbol}${amount.toStringAsFixed(2)}';
  }

  static String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  static String formatDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy hh:mm a').format(dateTime);
  }

  static String formatTime(DateTime time) {
    return DateFormat('hh:mm a').format(time);
  }
}

class Validators {
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Email is optional
    }

    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Phone is optional
    }

    final phoneRegex = RegExp(r'^[0-9\+\-\(\)\s]+$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Please enter a valid phone number';
    }

    return null;
  }

  static String? validateAmount(String? value, {bool allowZero = false}) {
    if (value == null || value.trim().isEmpty) {
      return 'Amount is required';
    }

    final amount = double.tryParse(value);
    if (amount == null) {
      return 'Please enter a valid amount';
    }

    if (!allowZero && amount <= 0) {
      return 'Amount must be greater than zero';
    }

    return null;
  }

  static String? validateInteger(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }

    final number = int.tryParse(value);
    if (number == null) {
      return 'Please enter a valid number';
    }

    if (number < 0) {
      return '$fieldName cannot be negative';
    }

    return null;
  }
}

class TextFormatters {
  static flutter_services.TextInputFormatter currency() {
    return FilteringTextInputFormatter.allow(RegExp(r'^[0-9]+\.?[0-9]{0,2}'));
  }

  static TextInputFormatter integer() {
    return FilteringTextInputFormatter.allow(RegExp(r'^[0-9]+$'));
  }

  static TextInputFormatter phone() {
    return FilteringTextInputFormatter.allow(RegExp(r'^[0-9\+\-\(\)\s]+$'));
  }

  static TextInputFormatter alphanumeric() {
    return FilteringTextInputFormatter.allow(RegExp(r'^[a-zA-Z0-9\s]+$'));
  }
}

class Debouncer {
  final Duration delay;
  VoidCallback? _action;
  Timer? _timer;

  Debouncer({this.delay = const Duration(milliseconds: 500)});

  void run(VoidCallback action) {
    _action = action;
    _timer?.cancel();
    _timer = Timer(delay, _action!);
  }

  void dispose() {
    _timer?.cancel();
  }
}
