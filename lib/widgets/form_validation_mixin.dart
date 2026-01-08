/* Enhanced validation and error handling utilities for form inputs
 
 This mixin provides easy integration of validation and error handling
 for form widgets throughout the application */

import 'package:flutter/material.dart';

/// Mixin for form widgets that need validation
mixin FormValidationMixin<T extends StatefulWidget> on State<T> {
  final Map<String, String?> _fieldErrors = {};

  /// Validate a field and update error state
  String? validateField(String fieldName, String? value, String? Function(String?) validator) {
    final error = validator(value);
    _fieldErrors[fieldName] = error;
    return error;
  }

  /// Get error message for a field
  String? getFieldError(String fieldName) => _fieldErrors[fieldName];

  /// Check if a field has an error
  bool hasFieldError(String fieldName) => _fieldErrors[fieldName] != null;

  /// Clear all errors
  void clearAllErrors() => _fieldErrors.clear();

  /// Clear specific field error
  void clearFieldError(String fieldName) => _fieldErrors.remove(fieldName);

  /// Check if form is valid (no errors)
  bool get isFormValid => _fieldErrors.values.every((error) => error == null);

  /// Build a text field with validation and error display
  Widget buildValidatedTextField({
    required String fieldName,
    required String label,
    required TextEditingController controller,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool required = false,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          textCapitalization: textCapitalization,
          onChanged: (value) {
            setState(() {
              validateField(fieldName, value, validator);
            });
          },
          decoration: InputDecoration(
            labelText: required ? '$label *' : label,
            errorText: getFieldError(fieldName),
            border: OutlineInputBorder(
              borderSide: BorderSide(
                color: hasFieldError(fieldName) ? Colors.red : Colors.grey,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: hasFieldError(fieldName) ? Colors.red : Colors.blue,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Widget that rebuilds when validation state changes
class ValidatingTextInput extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final String? Function(String?) validator;
  final void Function(String) onValidationChanged;
  final TextInputType keyboardType;
  final int maxLines;
  final bool required;

  const ValidatingTextInput({
    super.key,
    required this.label,
    required this.controller,
    required this.validator,
    required this.onValidationChanged,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.required = false,
  });

  @override
  State<ValidatingTextInput> createState() => _ValidatingTextInputState();
}

class _ValidatingTextInputState extends State<ValidatingTextInput> {
  late String? _error;

  @override
  void initState() {
    super.initState();
    _error = widget.validator(widget.controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          maxLines: widget.maxLines,
          onChanged: (value) {
            setState(() {
              _error = widget.validator(value);
              widget.onValidationChanged(_error ?? '');
            });
          },
          decoration: InputDecoration(
            labelText: widget.required ? '${widget.label} *' : widget.label,
            errorText: _error,
            border: OutlineInputBorder(
              borderSide: BorderSide(
                color: _error != null ? Colors.red : Colors.grey,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: _error != null ? Colors.red : Colors.blue,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
