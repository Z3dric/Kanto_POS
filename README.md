<<<<<<< HEAD
# Kanto_POS
 Point-of-sale for small Filipino businesses — sales, inventory, credit/utang, reports.

# Kanto_POS — Simple POS

Point-of-sale for small Filipino businesses — sales, inventory, credit/utang, reports.

This repository contains Simple POS, a mobile Point of Sale app built with Flutter and Dart, designed for offline-first operation and small retailers.

## Features

- Point of Sale: touch-friendly product grid, shopping cart, multiple payment types, receipt generation, barcode support
- Inventory Management: product database, stock tracking, categories, bulk import/export, stock adjustments
- Credit Management (Utang): customer profiles, credit tracking, payment collection, credit limits, reminders
- Sales & Expense Tracking: transaction history, refunds, expense categories, receipt capture, financial reports
- Reports & Analytics: sales dashboard, product performance, payment analytics, export to PDF/CSV

## Technical

- Framework: Flutter
- Language: Dart
- Database: SQLite (sqflite)
- State management: Provider (or your preferred pattern)

## Getting Started

1. Clone the repo
```bash
git clone <repository-url>
cd kanto_pos1
```
2. Install dependencies
```bash
flutter pub get
```
3. Run
```bash
flutter run
```

## Project Structure

See `lib/` for app code: `main.dart`, `models/`, `screens/`, `services/`, `widgets/`, `utils/`.

---

This README was merged to preserve the more complete project documentation while keeping the repository name `Kanto_POS`.
````
- **Mobile Optimized**: Touch-friendly interface with large tap targets
