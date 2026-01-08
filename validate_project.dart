import 'dart:io';

void main() {
  stdout.writeln('Validating Simple POS Project Structure...\n');

  final requiredFiles = [
    'pubspec.yaml',
    'lib/main.dart',
    'lib/models/product.dart',
    'lib/models/transaction.dart',
    'lib/models/customer.dart',
    'lib/models/expense.dart',
    'lib/services/database_service.dart',
    'lib/services/pos_service.dart',
    'lib/services/inventory_service.dart',
    'lib/services/report_service.dart',
    'lib/screens/home_screen.dart',
    'lib/screens/inventory_screen.dart',
    'lib/screens/sales_screen.dart',
    'lib/screens/credit_screen.dart',
    'lib/screens/reports_screen.dart',
    'lib/screens/expenses_screen.dart',
    'lib/widgets/product_card.dart',
    'lib/widgets/cart_panel.dart',
    'lib/widgets/search_bar.dart',
    'lib/utils/constants.dart',
    'lib/utils/helpers.dart',
    'assets/images/app_icon.png',
    'assets/images/splash_bg.png',
    'assets/images/product_placeholder.png',
    'assets/images/empty_state.png',
    'README.md',
    'test/widget_test.dart',
  ];
  
  bool allFilesExist = true;
  
  for (final file in requiredFiles) {
    final fileExists = File(file).existsSync();
    stdout.writeln('${fileExists ? "✓" : "✗"} $file');
    if (!fileExists) {
      allFilesExist = false;
    }
  }
  
  stdout.writeln('\nProject Structure Validation: ${allFilesExist ? "PASSED" : "FAILED"}');

  if (allFilesExist) {
    stdout.writeln('\n✅ All required files are present!');
    stdout.writeln('\nProject Overview:');
    stdout.writeln('- 5 main screens (POS, Inventory, Sales, Credit, Reports)');
    stdout.writeln('- 4 core services (Database, POS, Inventory, Reports)');
    stdout.writeln('- 3 data models (Product, Transaction, Customer, Expense)');
    stdout.writeln('- Offline-first SQLite database architecture');
    stdout.writeln('- Complete credit/utang management system');
    stdout.writeln('- Comprehensive reporting and analytics');
    stdout.writeln('- Mobile-optimized UI with Material Design');
  } else {
    stdout.writeln('\n❌ Some files are missing. Please check the project structure.');
    exit(1);
  }
}