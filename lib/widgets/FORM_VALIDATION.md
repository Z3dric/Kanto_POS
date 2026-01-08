# Form Validation Utilities

This module (`lib/widgets/form_validation_mixin.dart`) provides reusable utilities for handling form input validation and error display in the KantoPOS application.

It consists of two main components:
1. **`FormValidationMixin`**: A mixin for `StatefulWidget` states that manages validation logic and error state for multiple fields.
2. **`ValidatingTextInput`**: A standalone widget that handles its own validation state.

---

## FormValidationMixin

The `FormValidationMixin` is designed to be used on the `State` class of a `StatefulWidget`. It maintains a map of field errors and provides helper methods to validate inputs and build text fields with consistent styling.

### Key Features
- Centralized error state management.
- Helper method to build standardized text fields (`buildValidatedTextField`).
- Methods to check overall form validity.

### API Reference

| Method | Description |
|--------|-------------|
| `validateField(name, value, validator)` | Validates a specific field using the provided validator function and updates the error state. |
| `getFieldError(name)` | Returns the current error message for a field, or `null` if valid. |
| `hasFieldError(name)` | Returns `true` if the field has an error. |
| `clearAllErrors()` | Clears all validation errors. |
| `isFormValid` | Returns `true` if there are no errors in the map. |
| `buildValidatedTextField(...)` | Creates a `TextField` wrapped in a `Column` that automatically handles validation on change and displays errors. |

### Usage Example

```dart
import 'package:flutter/material.dart';
import '../widgets/form_validation_mixin.dart';
import '../utils/validators.dart';

class LoginForm extends StatefulWidget {
  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> with FormValidationMixin<LoginForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void _submit() {
    // Manual validation check before submission
    final emailError = validateField('email', _emailController.text, Validators.validateEmail);
    final passError = validateField('password', _passwordController.text, Validators.validatePassword);

    if (emailError == null && passError == null) {
      // Proceed with login
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Uses the mixin's builder method
        buildValidatedTextField(
          fieldName: 'email',
          label: 'Email Address',
          controller: _emailController,
          validator: Validators.validateEmail,
          required: true,
        ),
        const SizedBox(height: 16),
        buildValidatedTextField(
          fieldName: 'password',
          label: 'Password',
          controller: _passwordController,
          validator: Validators.validatePassword,
          required: true,
          // You can pass standard TextField properties
          maxLines: 1,
        ),
        ElevatedButton(onPressed: _submit, child: Text('Login')),
      ],
    );
  }
}
```

---

## ValidatingTextInput

`ValidatingTextInput` is a self-contained widget useful when you need a single input with validation logic that doesn't necessarily need to be tracked by the parent form's state, or when you want to handle the validation callback manually.

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `label` | `String` | The label text for the input. |
| `controller` | `TextEditingController` | Controller for the text field. |
| `validator` | `String? Function(String?)` | Function that returns an error string or null. |
| `onValidationChanged` | `void Function(String)` | Callback triggered when validation state changes. |
| `required` | `bool` | If true, adds an asterisk to the label. |

### Usage Example

```dart
ValidatingTextInput(
  label: 'Product Name',
  controller: _nameController,
  required: true,
  validator: (value) => value!.isEmpty ? 'Name is required' : null,
  onValidationChanged: (error) {
    // React to validation changes immediately
    print('Current error: $error');
  },
)
```