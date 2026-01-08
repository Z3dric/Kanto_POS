# KantoPOS Technical Documentation

## 1. Project Overview
**KantoPOS** is a cross-platform Point of Sale (POS) application built with Flutter. It is designed for small businesses (sari-sari stores, retailers) and features an **offline-first** architecture. While it uses Firebase for user authentication, all business data is stored locally on the device using SQLite.

### Supported Platforms
- **Mobile**: Android
- **Desktop**: Windows, Linux

---

## 2. Technical Architecture

### Tech Stack
- **Framework**: Flutter (Dart)
- **State Management**: Provider (`ChangeNotifier`, `Consumer`, `ProxyProvider`)
- **Authentication**: Firebase Authentication
- **Database**: SQLite (`sqflite` for mobile, `sqflite_common_ffi` for desktop)
- **Visualization**: `fl_chart` for reports

### Data Isolation Strategy
The application supports multiple users on a single device through database isolation:
- **Per-User Database**: Each authenticated user is assigned a unique SQLite database file named `pos_user_{uid}.db`.
- **Privacy**: This ensures that one user's inventory and sales records are completely separate from another's.

---

## 3. Core Modules

### Authentication
- **Service**: `AuthService`
- **Backend**: Firebase Auth (Email/Password)
- **Configuration**: See `FIREBASE_SETUP.md` for detailed setup instructions.

### Inventory Management
- **Service**: `InventoryService`
- **Features**:
  - CRUD operations for Products.
  - Stock tracking with low-stock alerts.
  - Audit trails for stock adjustments.

### Point of Sale (POS)
- **Service**: `POSService`
- **Features**:
  - Cart management.
  - Barcode scanning support.
  - Transaction processing (Cash, Credit/Utang).
  - Receipt generation.

### Form Validation
- **Location**: `lib/widgets/form_validation_mixin.dart`
- **Pattern**: Uses a mixin (`FormValidationMixin`) to inject validation logic into UI states.
- **Validators**: Common validation rules (Price, Email, Quantity) are centralized in `lib/utils/validators.dart`.

---

## 4. Development Patterns

### Service Implementation
The project follows strict patterns for service methods to ensure robust error handling. Refer to `lib/services/IMPLEMENTATION_PATTERNS.md` for code examples.

**Key Pattern: Result<T>**
Services return a `Result` type rather than throwing exceptions directly, allowing the UI to handle success/failure states gracefully.

```dart
// Example Service Call
final result = await service.addItem(...);
result.when(
  success: (item) => showSuccess(),
  error: (exception) => showError(exception.getUserMessage()),
);
```

### Error Handling
- **AppException**: A base class for all custom exceptions (`ValidationException`, `BusinessLogicException`, etc.).
- **ErrorHandler**: A utility to log errors and map them to user-friendly messages.

---

## 5. Setup & Build

### Prerequisites
1. Flutter SDK (3.0+)
2. Firebase Project (configured via `flutterfire`)

### Installation
1. Clone the repository.
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Ensure `google-services.json` (Android) or `firebase_options.dart` is configured.

### Running
- **Debug**: `flutter run`
- **Release**: `flutter run --release`