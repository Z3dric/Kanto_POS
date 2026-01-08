import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:simple_pos/main.dart';
import 'package:simple_pos/services/database_service.dart';
import 'package:simple_pos/services/pos_service.dart';
import 'package:simple_pos/services/inventory_service.dart';
import 'package:simple_pos/services/report_service.dart';
import 'package:simple_pos/services/auth_service.dart';

void main() {
  late DatabaseService databaseService;

  setUp(() async {
    databaseService = DatabaseService();
    await databaseService.initializeDatabase();
  });

  Widget buildTestApp() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService(initialize: false)),
        ChangeNotifierProvider(
          create: (_) => POSService(),
        ),
        ChangeNotifierProvider(
          create: (_) => InventoryService(),
        ),
        ChangeNotifierProvider(
          create: (_) => ReportService(),
        ),
      ],
      child: const KantoPOSApp(),
    );
  }

  testWidgets('App builds without errors', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    expect(find.byType(KantoPOSApp), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('Bottom navigation exists', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.text('POS'), findsOneWidget);
    expect(find.text('Inventory'), findsOneWidget);
    expect(find.text('Sales'), findsOneWidget);
    expect(find.text('Credit'), findsOneWidget);
    expect(find.text('Reports'), findsOneWidget);
  });

  testWidgets('POS screen shows search field', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.search), findsOneWidget);
    expect(find.byType(TextField), findsWidgets);
  });
}
