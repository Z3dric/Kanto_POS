# Kanto POS - API & Architecture Documentation

## Overview

Kanto POS is a comprehensive mobile Point of Sale system built with Flutter. This document provides detailed API documentation and architectural guidance for developers.

## Error Handling Architecture

### Exception Hierarchy

The application uses a custom exception hierarchy for comprehensive error handling:

```
AppException (abstract base class)
├── DatabaseException          - Database operations failed
├── AuthException             - Authentication/authorization failed
├── ValidationException       - User input validation failed
├── BusinessLogicException    - Business rule violation
│   ├── InventoryException   - Stock/inventory issues
│   └── PaymentException     - Payment processing failed
├── NetworkException          - Network/Firebase errors
├── NotFoundException         - Resource not found
└── FileException            - File I/O errors
```

### Using Custom Exceptions

```dart
// Throwing an exception
throw InventoryException(
  message: 'Insufficient stock for product',
  code: 'INSUFFICIENT_STOCK',
  productId: productId,
  requiredQuantity: 10,
  availableQuantity: 5,
);

// Handling exceptions
try {
  final product = await inventoryService.getProduct(id);
} on InventoryException catch (e) {
  print('Inventory error: ${e.message}');
  print('Details: ${e.getDetailedMessage()}');
} catch (e) {
  ErrorHandler.handleError(e);
}
```

## Validation System

### Built-in Validators

The `Validators` class provides pre-built validators for common input types:

```dart
// Validate product price
final priceError = Validators.validatePrice(priceInput);

// Validate quantity
final qtyError = Validators.validateQuantity(qtyInput, maxQuantity: 1000);

// Validate customer name
final nameError = Validators.validateCustomerName(nameInput);

// Batch validation
final batch = BatchValidator();
batch.addError('price', Validators.validatePrice(priceValue));
batch.addError('name', Validators.validateProductName(nameValue));

if (batch.hasErrors) {
  batch.throwIfInvalid(); // Throws ValidationException
}
```

### Form Validation in Widgets

```dart
class ProductForm extends StatefulWidget {
  @override
  State<ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<ProductForm> with FormValidationMixin {
  final nameController = TextEditingController();
  final priceController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        buildValidatedTextField(
          fieldName: 'name',
          label: 'Product Name',
          controller: nameController,
          validator: Validators.validateProductName,
          required: true,
        ),
        buildValidatedTextField(
          fieldName: 'price',
          label: 'Price',
          controller: priceController,
          validator: (value) => Validators.validatePrice(value, allowZero: false),
          keyboardType: TextInputType.number,
          required: true,
        ),
        ElevatedButton(
          onPressed: isFormValid ? _submitForm : null,
          child: const Text('Save Product'),
        ),
      ],
    );
  }
}
```

## Result Type

The application uses a `Result<T>` type for safe error handling:

```dart
// Using Result type
Result<Product> result = await productService.getProduct(id);

// Pattern matching
result.when(
  success: (product) {
    print('Product: ${product.name}');
  },
  error: (error) {
    print('Error: ${error.message}');
    showErrorSnackbar(context, error.getUserMessage());
  },
);

// Chaining operations
final result = await getProductFuture()
  .asResult()
  .then((result) => result.map((product) => product.price));

// Getting value or null
final product = result.getOrNull();
final error = result.getErrorOrNull();
```

## Error Handler

Central error handling for the application:

```dart
// Basic error handling
try {
  await complexOperation();
} catch (e, st) {
  ErrorHandler.handleError(
    e,
    stackTrace: st,
    tag: 'complexOperation',
  );
}

// Safe async operations
final products = await ErrorHandler.safeAsync(
  () => inventoryService.loadProducts(),
  operationName: 'loadProducts',
  defaultValue: [],
);

// Set custom logging callback
ErrorHandler.setLogCallback((message) {
  // Send to logging service
  analyticsService.logError(message);
});
```

## UI Error Display Widgets

### ErrorBanner
```dart
ErrorBanner(
  message: 'Failed to load products',
  onRetry: _loadProducts,
  onDismiss: () => setState(() {}),
)
```

### ErrorDialog
```dart
showDialog(
  context: context,
  builder: (context) => ErrorDialog.fromException(
    exception,
    onRetry: _retryOperation,
  ),
);
```

### Error/Success Snackbars
```dart
showErrorSnackbar(context, 'Failed to save product', onRetry: _save);
showSuccessSnackbar(context, 'Product saved successfully');
showInfoSnackbar(context, 'Syncing data...');
```

## Service Architecture

### POSService

Manages point-of-sale operations including cart management and transactions.

```dart
final posService = context.read<POSService>();

// Cart operations
posService.addToCart(product, quantity: 2);
posService.removeFromCart(productId);
posService.updateCartQuantity(productId, 5);
posService.clearCart();

// Getters
final items = posService.cartItems;
final total = posService.cartTotal;
final tax = posService.cartTax;
final count = posService.cartItemCount;

// Payment
posService.setPaymentMethod(PaymentMethod.credit);
final customer = posService.selectedCustomer;

// Transactions
final transactions = posService.transactions;
```

### InventoryService

Handles product and inventory management.

```dart
final inventoryService = context.read<InventoryService>();

// Product operations
await inventoryService.addProduct(product);
await inventoryService.updateProduct(product);
await inventoryService.deleteProduct(productId);
final product = await inventoryService.getProduct(productId);

// Filtering and search
inventoryService.setSearchQuery('coca');
inventoryService.setSelectedCategory('Beverages');
final filtered = inventoryService.filteredProducts;

// Stock checks
final lowStock = inventoryService.lowStockProducts;
final outOfStock = inventoryService.outOfStockProducts;
```

### ReportService

Generates sales and financial reports.

```dart
final reportService = context.read<ReportService>();

// Get summaries
final dailySummary = await reportService.getDailySummary();
final weeklySummary = await reportService.getWeeklySummary(startDate);

// Product performance
final topSellers = await reportService.getTopSellingProducts(limit: 10);
final leastSellers = await reportService.getLeastSellingProducts(limit: 10);
```

## Best Practices

### 1. Always Validate User Input
```dart
// ✅ GOOD
final error = Validators.validatePrice(priceInput);
if (error != null) {
  showError(error);
  return;
}

// ❌ AVOID
double price = double.parse(priceInput);  // Can throw
```

### 2. Use Result Type for Operations
```dart
// ✅ GOOD
Result<Product> result = await getProduct(id);
result.when(
  success: (product) => updateUI(product),
  error: (error) => showError(error),
);

// ❌ AVOID
try {
  final product = await getProduct(id);
  updateUI(product);
} catch (e) {
  // Unhandled error
}
```

### 3. Handle Database Errors Gracefully
```dart
// ✅ GOOD
try {
  await databaseService.updateProduct(product);
  showSuccessSnackbar(context, 'Product updated');
} on DatabaseException catch (e) {
  showErrorSnackbar(context, e.getUserMessage());
} catch (e, st) {
  ErrorHandler.handleError(e, stackTrace: st);
}
```

### 4. Use Mixin for Form Validation
```dart
// ✅ GOOD
class MyForm extends StatefulWidget {
  @override
  State<MyForm> createState() => _MyFormState();
}

class _MyFormState extends State<MyForm> with FormValidationMixin {
  // Use buildValidatedTextField and isFormValid
}
```

### 5. Log Operations for Debugging
```dart
debugPrint('[ProductService] Loading products...');
debugPrint('[ProductService] Loaded ${products.length} products');
```

## Database Schema

### Products Table
```sql
CREATE TABLE products (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  price REAL NOT NULL,
  cost REAL NOT NULL,
  stock INTEGER NOT NULL,
  minStock INTEGER NOT NULL,
  barcode TEXT,
  imagePath TEXT,
  category TEXT NOT NULL,
  isActive INTEGER NOT NULL,
  createdAt TEXT NOT NULL,
  updatedAt TEXT NOT NULL
)
```

### Customers Table
```sql
CREATE TABLE customers (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  phone TEXT,
  email TEXT,
  address TEXT,
  creditLimit REAL NOT NULL,
  currentBalance REAL NOT NULL,
  createdAt TEXT NOT NULL,
  updatedAt TEXT NOT NULL
)
```

### Transactions Table
```sql
CREATE TABLE transactions (
  id TEXT PRIMARY KEY,
  timestamp TEXT NOT NULL,
  items TEXT NOT NULL,  -- JSON
  subtotal REAL NOT NULL,
  tax REAL NOT NULL,
  discount REAL NOT NULL,
  total REAL NOT NULL,
  paymentMethod TEXT NOT NULL,
  status TEXT NOT NULL,
  customerId TEXT,
  customerName TEXT,
  receiptNumber TEXT
)
```

## Future Enhancements

1. **Advanced Analytics**
   - Predictive inventory forecasting
   - Seasonal trend analysis
   - Customer purchase patterns

2. **Cloud Sync**
   - Real-time Firestore sync
   - Conflict resolution for offline-first
   - Backup and recovery

3. **Security Enhancements**
   - SQLite encryption
   - Transaction logging
   - Biometric authentication

4. **Performance**
   - Database query optimization
   - Lazy loading for large lists
   - Caching strategies

## Contributing

When adding new features:
1. Use custom exception types
2. Add validators for user inputs
3. Use Result<T> for operations
4. Add comprehensive documentation
5. Test error scenarios
6. Update this documentation
