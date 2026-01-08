import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'Kanto POS';
  static const String databaseName = 'kanto_pos.db';
  static const int databaseVersion = 1;
  // Toggle inserting sample/mock data when creating a fresh local database
  static const bool seedSampleData = false;
  static const String currencySymbol = '₱';
  static const String dateFormat = 'yyyy-MM-dd';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm:ss';
}

class AppColors {
  static const Color primary = Color(0xFF1565C0);  // Professional blue
  static const Color secondary = Color(0xFF00897B);  // Teal accent
  static const Color accent = Color(0xFF00BCD4);  // Cyan
  static const Color error = Color(0xFFD32F2F);  // Deep red
  static const Color warning = Color(0xFFF57C00);  // Deep orange
  static const Color success = Color(0xFF388E3C);  // Green
  static const Color info = Color(0xFF0288D1);  // Light blue

  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textMuted = Color(0xFF999999);
  static const Color border = Color(0xFFDDDDDD);

  static const MaterialColor primarySwatch = MaterialColor(0xFF1565C0, {
    50: Color(0xFFE3F2FD),
    100: Color(0xFFBBDEFB),
    200: Color(0xFF90CAF9),
    300: Color(0xFF64B5F6),
    400: Color(0xFF42A5F5),
    500: Color(0xFF2196F3),
    600: Color(0xFF1E88E5),
    700: Color(0xFF1976D2),
    800: Color(0xFF1565C0),
    900: Color(0xFF0D47A1),
  });
}

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

class AppBorderRadius {
  static const double sm = 4.0;
  static const double md = 8.0;
  static const double lg = 12.0;
  static const double xl = 16.0;
}

class AppShadows {
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x0D000000),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> elevated = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];
}

class AppSizes {
  static const double iconSm = 16.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconXl = 48.0;
  static const double buttonHeight = 48.0;
}
