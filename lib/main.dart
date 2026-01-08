import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kanto_pos/screens/home_screen.dart';
import 'package:kanto_pos/screens/inventory_screen.dart';
import 'package:kanto_pos/screens/sales_screen.dart';
import 'package:kanto_pos/screens/credit_screen.dart';
import 'package:kanto_pos/screens/reports_screen.dart';
import 'package:kanto_pos/services/database_service.dart';
import 'package:kanto_pos/services/pos_service.dart';
import 'package:kanto_pos/services/inventory_service.dart';
import 'package:kanto_pos/services/report_service.dart';
import 'package:kanto_pos/utils/constants.dart';
import 'package:kanto_pos/utils/error_handler.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:kanto_pos/screens/login_screen.dart';
import 'package:kanto_pos/screens/signup_screen.dart';
import 'package:kanto_pos/screens/title_screen.dart';
import 'package:kanto_pos/services/auth_service.dart';
import 'firebase_options.dart';

/// Main entry point for Kanto POS application
/// 
/// Initializes:
/// - Firebase for authentication and cloud services
/// - SQLite database for local data storage
/// - Provider-based state management
/// - Error handling and logging
/// 
/// The app uses multi-user support with user-specific databases
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set up error logging
  ErrorHandler.setLogCallback((message) {
    debugPrint(message);
    // TODO: Integrate with remote logging service
  });

  try {
    // Initialize Firebase
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    // Initialize database (will use default/anonymous database initially)
    final databaseService = DatabaseService();
    await databaseService.initializeDatabase();

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthService()),
          ChangeNotifierProxyProvider<AuthService, POSService>(
            create: (_) => POSService(),
            update: (_, auth, pos) => pos!..updateUser(auth.currentUser?.uid),
          ),
          ChangeNotifierProxyProvider<AuthService, InventoryService>(
            create: (_) => InventoryService(),
            update: (_, auth, inventory) => inventory!..updateUser(auth.currentUser?.uid),
          ),
          ChangeNotifierProvider(create: (_) => ReportService()),
        ],
        child: const KantoPOSApp(),
      ),
    );
  } catch (e, st) {
    ErrorHandler.handleError(
      e,
      stackTrace: st,
      tag: 'main',
    );

    // Fallback UI if initialization fails
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text('Failed to initialize app'),
                const SizedBox(height: 8),
                Text(
                  e.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class KantoPOSApp extends StatelessWidget {
  const KantoPOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KantoPOS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: AppColors.primarySwatch,
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Inter',

        // AppBar theme
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          titleTextStyle: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),

        // Card theme
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),

        // Button themes
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),

        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),

        // Input decoration
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),

        // Text themes
        textTheme: const TextTheme(
          headlineSmall: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          titleLarge: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
          labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),

        // Bottom navigation theme
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
      ),
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  bool _showLogin = true;
  bool _showTitleScreen = true;

  final List<Widget> _screens = const [
    HomeScreen(),
    InventoryScreen(),
    SalesScreen(),
    CreditScreen(),
    ReportsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        // Show title screen on first launch
        if (_showTitleScreen) {
          return TitleScreen(
            onGetStarted: () => setState(() => _showTitleScreen = false),
          );
        }

        // Show login/signup if not authenticated
        if (!authService.isAuthenticated) {
          return _showLogin
              ? LoginScreen(
                  onSignupTap: () => setState(() => _showLogin = false),
                )
              : SignupScreen(
                  onLoginTap: () => setState(() => _showLogin = true),
                );
        }

        // Show main app if authenticated
        return Scaffold(
          body: _screens[_currentIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.point_of_sale),
                label: 'POS',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.inventory),
                label: 'Inventory',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long),
                label: 'Sales',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.credit_card),
                label: 'Credit',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.analytics),
                label: 'Reports',
              ),
            ],
          ),
        );
      },
    );
  }
}
