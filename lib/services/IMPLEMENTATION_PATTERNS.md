# Service Implementation Patterns

## Error Handling Patterns

### Pattern 1: Basic Error Handling in Services

```dart
Future<Result<Item>> addItem({
  required String name,
  required String price,
}) async {
  try {
    // 1. Validate inputs
    final validator = BatchValidator();
    validator.addError('name', Validators.validateProductName(name));
    validator.addError('price', Validators.validatePrice(price));
    validator.throwIfInvalid();

    // 2. Parse and validate data
    final parsedPrice = double.parse(price);

    // 3. Check business logic
    if (_items.any((item) => item.name == name)) {
      throw BusinessLogicException(
        message: 'Item already exists',
        code: 'DUPLICATE_ITEM',
      );
    }

    // 4. Perform operation
    final newItem = Item(id: generateId(), name: name, price: parsedPrice);
    _items.add(newItem);
    notifyListeners();

    // 5. Return success
    return Result.success(newItem);
  } on ValidationException {
    rethrow; // Let validation errors propagate
  } catch (e, st) {
    final error = BusinessLogicException(
      message: 'Failed to add item',
      originalError: e,
      stackTrace: st,
    );
    ErrorHandler.handleError(error, tag: 'addItem');
    return Result.error(error);
  }
}
```

### Pattern 2: Async Operations in Widgets

```dart
Future<void> loadItems() async {
  final service = context.read<ExampleService>();
  
  // Option 1: Using Result<T>
  final result = await service.getItems();
  result.when(
    success: (items) => updateUI(items),
    error: (error) => showErrorSnackbar(context, error.getUserMessage()),
  );
}
```

### Pattern 3: Form Validation in Widgets

```dart
class ItemForm extends StatefulWidget {
  @override
  State<ItemForm> createState() => _ItemFormState();
}

class _ItemFormState extends State<ItemForm> with FormValidationMixin {
  final nameController = TextEditingController();
  final priceController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        buildValidatedTextField(
          fieldName: 'name',
          label: 'Item Name',
          controller: nameController,
          validator: Validators.validateProductName,
          required: true,
        ),
        buildValidatedTextField(
          fieldName: 'price',
          label: 'Price',
          controller: priceController,
          validator: (value) => Validators.validatePrice(value),
          keyboardType: TextInputType.number,
          required: true,
        ),
        ElevatedButton(
          onPressed: isFormValid ? _submitForm : null,
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _submitForm() async {
    final service = context.read<ExampleService>();
    final result = await service.addItem(
      name: nameController.text,
      price: priceController.text,
    );

    result.when(
      success: (item) {
        showSuccessSnackbar(context, 'Item added');
        Navigator.pop(context);
      },
      error: (error) {
        showErrorSnackbar(context, error.getUserMessage());
      },
    );
  }
}
```

### Pattern 4: Real-time Field Validation

```dart
void onPriceChanged(String value) {
  setState(() {
    final error = Validators.validatePrice(value);
    if (error == null) {
      _parsedPrice = double.parse(value);
      _priceError = null;
    } else {
      _priceError = error;
    }
  });
}
```

### Pattern 5: Batch Operations with Error Handling

```dart
Future<void> importItems(List<ItemData> itemsToImport) async {
  final service = context.read<ExampleService>();
  final errors = <String>[];

  for (final itemData in itemsToImport) {
    final result = await service.addItem(
      name: itemData.name,
      price: itemData.price.toString(),
    );

    result.when(
      success: (item) {
        // Count successful imports
      },
      error: (error) {
        errors.add('${itemData.name}: ${error.getUserMessage()}');
      },
    );
  }

  if (errors.isEmpty) {
    showSuccessSnackbar(context, 'All items imported');
  } else {
    showErrorSnackbar(
      context,
      'Some items failed: ${errors.join(", ")}',
    );
  }
}
```

### Pattern 6: Safe Async Wrapper

```dart
// Using ErrorHandler.safeAsync for automatic error handling
final items = await ErrorHandler.safeAsync(
  () => service.loadItems(),
  operationName: 'loadItems',
  defaultValue: [],
);

// Using Future.asResult() extension
final result = await service.getItem(id).asResult();
result.when(
  success: (item) => updateUI(item),
  error: (error) => showError(context, error),
);
```

## Best Practices

1. **Always validate before processing**
   - Use BatchValidator for multiple fields
   - Check inputs at service boundary
   - Provide clear error messages

2. **Use Result<T> for operations**
   - Safer than exceptions alone
   - Supports chaining
   - Clear success/failure handling

3. **Preserve stack traces**
   - Always pass `stackTrace` to exceptions
   - Use `ErrorHandler.handleError()` for logging
   - Track original error with `originalError`

4. **Use specific exception types**
   - InventoryException for stock issues
   - ValidationException for input errors
   - NotFoundException for missing resources
   - PaymentException for payment failures

5. **Provide user-friendly messages**
   - Use `getUserMessage()` for UI display
   - Log `getDetailedMessage()` for debugging
   - Include error code for support tickets

6. **Clean up resources**
   - Dispose TextEditingController
   - Cancel subscriptions
   - Clear temporary data

## Error Display Options

### Snackbar
```dart
showErrorSnackbar(context, error.getUserMessage(), onRetry: _retry);
```

### Dialog
```dart
showDialog(
  context: context,
  builder: (context) => ErrorDialog.fromException(exception),
);
```

### Banner
```dart
ErrorBanner(
  message: error.getUserMessage(),
  onRetry: _retry,
  onDismiss: () => setState(() {}),
)
```

## Testing Error Scenarios

```dart
// Test validation errors
test('validatePrice rejects negative values', () {
  final error = Validators.validatePrice('-10');
  expect(error, isNotNull);
});

// Test service errors
test('addItem throws on duplicate', () async {
  await service.addItem(name: 'Item', price: '10');
  
  expect(
    () => service.addItem(name: 'Item', price: '20'),
    throwsA(isA<BusinessLogicException>()),
  );
});

// Test Result<T>
test('Result.success returns value', () {
  final result = Result.success(42);
  expect(result.getOrNull(), 42);
});

test('Result.error throws on getOrThrow', () {
  final result = Result<int>.error(BusinessLogicException(message: 'Error'));
  expect(() => result.getOrThrow(), throwsA(isA<BusinessLogicException>()));
});
```
