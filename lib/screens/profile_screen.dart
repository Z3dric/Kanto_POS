// ignore_for_file: use_build_context_synchronously

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoggingOut = false;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.md),
            Center(
              child: CircleAvatar(
                radius: 40,
                child: Text(
                  (user?.displayName ?? '').isNotEmpty
                      ? user!.displayName!.substring(0, 1).toUpperCase()
                      : (user?.email ?? '').isNotEmpty
                          ? user!.email!.substring(0, 1).toUpperCase()
                          : '?',
                  style: const TextStyle(fontSize: 32),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: Text(
                user?.displayName ?? 'No name',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Center(
              child: Text(
                user?.email ?? '',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            ElevatedButton.icon(
              onPressed: _isLoggingOut
                  ? null
                  : () async {
                      setState(() => _isLoggingOut = true);
                      final navigator = Navigator.of(context);
                      await context.read<AuthService>().logout();
                      // After logout the MainNavigation will show the login screen.
                      if (!mounted) return;
                      navigator.popUntil((route) => route.isFirst);
                    },
              icon: const Icon(Icons.logout),
              label: _isLoggingOut
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Dev-only: clear local database
            if (kDebugMode)
              ElevatedButton.icon(
                onPressed: _isLoggingOut
                    ? null
                    : () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Clear local data'),
                            content: const Text(
                                'This will delete the local database and reset all local data. Continue?'),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancel')),
                              TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Delete', style: TextStyle(color: AppColors.error))),
                            ],
                          ),
                        );

                        if (confirm != true) return;

                        setState(() => _isLoggingOut = true);
                        try {
                          await DatabaseService().deleteDatabase();
                          await DatabaseService().initializeDatabase();
                          if (!mounted) return;
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Local database cleared')),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          messenger.showSnackBar(
                            SnackBar(content: Text('Error clearing DB: $e')),
                          );
                        } finally {
                          if (mounted) setState(() => _isLoggingOut = false);
                        }
                      },
                icon: const Icon(Icons.delete_forever),
                label: const Text('Clear Local Data (Dev)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                ),
              ),
            if (kDebugMode)
              const SizedBox(height: 8),
            if (kDebugMode)
              ElevatedButton(
                onPressed: () async {
                  final db = DatabaseService();
                  try {
                    final products = await db.rawQuery('SELECT * FROM products ORDER BY createdAt DESC LIMIT 50');
                    final transactions = await db.rawQuery('SELECT * FROM transactions ORDER BY createdAt DESC LIMIT 50');

                    if (!mounted) return;
                    final safeContext = context;
                    showDialog(
                      context: safeContext,
                      builder: (dialogCtx) => AlertDialog(
                        title: const Text('DB Dump (latest)'),
                        content: SizedBox(
                          width: double.maxFinite,
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Products:'),
                                const SizedBox(height: 8),
                                ...products.take(50).map((r) => Text('- ${r['name'] ?? r['id']} (stock: ${r['stock'] ?? 'n/a'})')),
                                const SizedBox(height: 12),
                                const Text('Transactions:'),
                                const SizedBox(height: 8),
                                ...transactions.take(50).map((r) => Text('- ${r['id'] ?? '?'} (${r['createdAt'] ?? ''})')),
                              ],
                            ),
                          ),
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.of(dialogCtx).pop(), child: const Text('Close')),
                        ],
                      ),
                    );
                  } catch (e, st) {
                    debugPrint('DB Dump error: $e\n$st');
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('DB dump failed: $e')));
                  }
                },
                child: const Text('Show DB Dump (DEV)'),
              ),
          ],
        ),
      ),
    );
  }
}
