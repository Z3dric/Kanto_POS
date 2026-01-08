import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:provider/provider.dart';
import 'package:simple_pos/widgets/search_bar.dart';
import '../models/expense.dart';
import '../services/pos_service.dart';
import '../utils/constants.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _vendorController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  ExpenseCategory _selectedCategory = ExpenseCategory.other;
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _vendorController.dispose();
    _notesController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final posService = context.watch<POSService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            onPressed: _showExpenseAnalytics,
          ),
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            onPressed: _exportExpenses,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddExpenseDialog,
        backgroundColor: AppColors.accent,
        child: const Icon(Icons.add, size: 32),
      ),
      body: Column(
        children: [
          // Expense summary
          _buildExpenseSummary(),

          const SizedBox(height: AppSpacing.md),

          // Search and filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: AppSearchBar(
              controller: _searchController,
              hintText: 'Search expenses...',
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Category filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: ExpenseCategory.values.length,
                itemBuilder: (context, index) {
                  final category = ExpenseCategory.values[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: FilterChip(
                      label: Text(category.categoryDisplayName),
                      selected: _selectedCategory == category,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Expense list
          Expanded(
            child: FutureBuilder<List<Expense>>(
              future: posService.getExpenses(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final expenses = snapshot.data ?? [];
                if (expenses.isEmpty) return _buildEmptyState();

                return ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: expenses.length,
                  itemBuilder: (context, index) {
                    final expense = expenses[index];
                    return _buildExpenseItem(expense);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseSummary() {
    // Mock summary data
    const totalExpenses = 5370.0;
    const thisMonth = 3500.0;
    const thisWeek = 1200.0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              'Total Expenses',
              '${AppConstants.currencySymbol}${totalExpenses.toStringAsFixed(2)}',
              Icons.money_off,
              AppColors.error,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _buildSummaryCard(
              'This Month',
              '${AppConstants.currencySymbol}${thisMonth.toStringAsFixed(2)}',
              Icons.calendar_today,
              AppColors.warning,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _buildSummaryCard(
              'This Week',
              '${AppConstants.currencySymbol}${thisWeek.toStringAsFixed(2)}',
              Icons.calendar_view_week,
              AppColors.info,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_outlined,
            size: 120,
            color: AppColors.textMuted.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'No expenses recorded',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Add expenses to track your business costs',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseItem(Expense expense) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        boxShadow: AppShadows.card,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppSpacing.md),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: _getCategoryColor(expense.category).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppBorderRadius.sm),
          ),
          child: Icon(
            _getCategoryIcon(expense.category),
            color: _getCategoryColor(expense.category),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              expense.description,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            Text(
              expense.category.categoryDisplayName,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (expense.vendor != null) ...[
              Text(
                'Vendor: ${expense.vendor}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
            Text(
              DateFormat('MMM dd, yyyy').format(expense.date),
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            if (expense.notes != null) ...[
              const SizedBox(height: 2),
              Text(
                expense.notes!,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${AppConstants.currencySymbol}${expense.amount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.error,
              ),
            ),
            if (expense.receiptPath != null) ...[
              const SizedBox(height: 2),
              const Icon(Icons.receipt, size: 16, color: AppColors.info),
            ],
          ],
        ),
        onTap: () => _showExpenseDetails(expense),
      ),
    );
  }

  Color _getCategoryColor(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.rent:
        return AppColors.primary;
      case ExpenseCategory.utilities:
        return AppColors.info;
      case ExpenseCategory.supplies:
        return AppColors.success;
      case ExpenseCategory.inventory:
        return AppColors.warning;
      case ExpenseCategory.marketing:
        return AppColors.secondary;
      case ExpenseCategory.salaries:
        return AppColors.error;
      case ExpenseCategory.maintenance:
        return Colors.purple;
      case ExpenseCategory.transportation:
        return Colors.orange;
      case ExpenseCategory.personal:
        return Colors.pink;
      case ExpenseCategory.other:
        return AppColors.textSecondary;
    }
  }

  IconData _getCategoryIcon(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.rent:
        return Icons.home;
      case ExpenseCategory.utilities:
        return Icons.bolt;
      case ExpenseCategory.supplies:
        return Icons.shopping_basket;
      case ExpenseCategory.inventory:
        return Icons.inventory;
      case ExpenseCategory.marketing:
        return Icons.campaign;
      case ExpenseCategory.salaries:
        return Icons.people;
      case ExpenseCategory.maintenance:
        return Icons.build;
      case ExpenseCategory.transportation:
        return Icons.directions_car;
      case ExpenseCategory.personal:
        return Icons.person;
      case ExpenseCategory.other:
        return Icons.more_horiz;
    }
  }

  void _showAddExpenseDialog() {
    _amountController.clear();
    _descriptionController.clear();
    _vendorController.clear();
    _notesController.clear();
    _selectedCategory = ExpenseCategory.other;
    _selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Expense'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Amount
                TextField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount *',
                    border: OutlineInputBorder(),
                    prefixText: '${AppConstants.currencySymbol} ',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: AppSpacing.sm),

                // Date picker
                InkWell(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => _selectedDate = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      border: OutlineInputBorder(),
                    ),
                    child:
                        Text(DateFormat('MMM dd, yyyy').format(_selectedDate)),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Category dropdown
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Category *',
                    border: OutlineInputBorder(),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<ExpenseCategory>(
                      value: _selectedCategory,
                      isDense: true,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedCategory = value);
                        }
                      },
                      items: ExpenseCategory.values.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Row(
                            children: [
                              Icon(
                                _getCategoryIcon(category),
                                size: 16,
                                color: _getCategoryColor(category),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(category.categoryDisplayName),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Description
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Vendor
                TextField(
                  controller: _vendorController,
                  decoration: const InputDecoration(
                    labelText: 'Vendor (Optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Notes
                TextField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_amountController.text.isEmpty ||
                    _descriptionController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill in all required fields'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                final amount = double.tryParse(_amountController.text) ?? 0;
                if (amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid amount'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                final now = DateTime.now();
                final expense = Expense(
                  id: const Uuid().v4(),
                  amount: amount,
                  category: _selectedCategory,
                  description: _descriptionController.text,
                  date: _selectedDate,
                  vendor: _vendorController.text.isNotEmpty ? _vendorController.text : null,
                  notes: _notesController.text.isNotEmpty ? _notesController.text : null,
                  receiptPath: null,
                  createdAt: now,
                  updatedAt: now,
                );

                // add to DB
                final posService = Provider.of<POSService>(context, listen: false);
                try {
                  await posService.addExpense(expense);
                  if (!mounted) return;
                  Navigator.of(this.context).pop();
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(
                      content: Text('Expense added successfully'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  setState(() {});
                } catch (e) {
                  if (!mounted) return;
                  Navigator.of(this.context).pop();
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to add expense: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
              child: const Text('Add Expense'),
            ),
          ],
        ),
      ),
    );
  }

  void _showExpenseDetails(Expense expense) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Expense Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Description', expense.description),
              _buildDetailRow('Category', expense.category.categoryDisplayName),
              _buildDetailRow('Amount',
                  '${AppConstants.currencySymbol}${expense.amount.toStringAsFixed(2)}'),
              _buildDetailRow(
                  'Date', DateFormat('MMM dd, yyyy').format(expense.date)),
              if (expense.vendor != null)
                _buildDetailRow('Vendor', expense.vendor!),
              if (expense.notes != null)
                _buildDetailRow('Notes', expense.notes!),
              _buildDetailRow('Created',
                  DateFormat('MMM dd, yyyy hh:mm a').format(expense.createdAt)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (expense.receiptPath != null) ...[
            TextButton(
              onPressed: () {
                // TODO: View receipt
                Navigator.pop(context);
              },
              child: const Text('View Receipt'),
            ),
          ],
          ElevatedButton(
            onPressed: () {
              // TODO: Edit expense
              Navigator.pop(context);
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(value),
        ],
      ),
    );
  }

  void _showExpenseAnalytics() {
    // TODO: Implement expense analytics
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Expense analytics coming soon')),
    );
  }

  void _exportExpenses() {
    // TODO: Implement expense export
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export coming soon')),
    );
  }
}
