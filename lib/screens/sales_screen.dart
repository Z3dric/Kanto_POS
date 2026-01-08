import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:kanto_pos/models/sale.dart';
import '../services/pos_service.dart';
import '../widgets/search_bar.dart';
import '../utils/constants.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final TextEditingController _searchController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {});
  }

  List<Sale> _filteredTransactions(List<Sale> all) {
    final q = _searchController.text.trim().toLowerCase();
    var filtered = all;

    if (_selectedFilter != 'all') {
      if (_selectedFilter == 'cash') {
        filtered = filtered.where((t) => t.paymentMethod == PaymentMethod.cash).toList();
      } else if (_selectedFilter == 'credit') {
        filtered = filtered.where((t) => t.paymentMethod == PaymentMethod.credit).toList();
      } else if (_selectedFilter == 'refunded') {
        filtered = filtered.where((t) => t.status == TransactionStatus.refunded).toList();
      }
    }

    if (q.isNotEmpty) {
      filtered = filtered.where((t) {
        return (t.receiptNumber ?? '').toLowerCase().contains(q) ||
            (t.customerName ?? '').toLowerCase().contains(q) ||
            (t.notes ?? '').toLowerCase().contains(q) ||
            t.id.toLowerCase().contains(q);
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final posService = context.watch<POSService>();
    final transactions = posService.transactions;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selectDate,
          ),
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            onPressed: _exportSales,
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary cards
          _buildSummaryCards(),

          const SizedBox(height: AppSpacing.md),

          // Search and filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Column(
              children: [
                AppSearchBar(
                  controller: _searchController,
                  hintText: 'Search transactions...',
                ),
                const SizedBox(height: AppSpacing.sm),

                // Filter chips
                Row(
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: _selectedFilter == 'all',
                      onSelected: (selected) =>
                          setState(() => _selectedFilter = 'all'),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    FilterChip(
                      label: const Text('Cash'),
                      selected: _selectedFilter == 'cash',
                      onSelected: (selected) =>
                          setState(() => _selectedFilter = 'cash'),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    FilterChip(
                      label: const Text('Credit'),
                      selected: _selectedFilter == 'credit',
                      onSelected: (selected) =>
                          setState(() => _selectedFilter = 'credit'),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    FilterChip(
                      label: const Text('Refunded'),
                      selected: _selectedFilter == 'refunded',
                      onSelected: (selected) =>
                          setState(() => _selectedFilter = 'refunded'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Transaction list
          Expanded(
            child: Builder(builder: (context) {
              final filtered = _filteredTransactions(transactions);
              if (filtered.isEmpty) return _buildEmptyState();
              return ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final transaction = filtered[index];
                  return _buildTransactionItem(transaction);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final posService = context.watch<POSService>();

    return FutureBuilder<Map<String, dynamic>>(
      future: posService.getSalesSummary(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: LinearProgressIndicator(),
          );
        }

        final summary = snapshot.data!;
        final totalSales = summary['summary']['totalSales'] as double;
        final totalTransactions =
            summary['summary']['totalTransactions'] as int;
        final totalItems = summary['summary']['totalItems'] as int;

        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Total Sales',
                  '${AppConstants.currencySymbol}${totalSales.toStringAsFixed(2)}',
                  Icons.attach_money,
                  AppColors.success,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildSummaryCard(
                  'Transactions',
                  totalTransactions.toString(),
                  Icons.receipt_long,
                  AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildSummaryCard(
                  'Items Sold',
                  totalItems.toString(),
                  Icons.shopping_basket,
                  AppColors.info,
                ),
              ),
            ],
          ),
        );
      },
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
              fontSize: 20,
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
            'No transactions found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Process sales to see transaction history',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Sale transaction) {
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
            color: _getStatusColor(transaction.status).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppBorderRadius.sm),
          ),
          child: Icon(
            _getStatusIcon(transaction.status),
            color: _getStatusColor(transaction.status),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              transaction.receiptNumber ?? 'No Receipt',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            Text(
              DateFormat('MMM dd, yyyy • hh:mm a')
                  .format(transaction.timestamp),
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
            if (transaction.customerName != null) ...[
              Text(
                'Customer: ${transaction.customerName}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
            Text(
              '${transaction.totalItems} items • ${transaction.paymentMethod.name.toUpperCase()}',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(transaction.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                  ),
                  child: Text(
                    transaction.status.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      color: _getStatusColor(transaction.status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (transaction.isCredit) ...[
                  const SizedBox(width: AppSpacing.xs),
                  const Icon(Icons.credit_card,
                      size: 14, color: AppColors.info),
                ],
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${AppConstants.currencySymbol}${transaction.total.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.primary,
              ),
            ),
            if (transaction.discount > 0) ...[
              const SizedBox(height: 2),
              Text(
                'Discount: ${AppConstants.currencySymbol}${transaction.discount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
        onTap: () => _showTransactionDetails(transaction),
      ),
    );
  }

  Color _getStatusColor(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.completed:
        return AppColors.success;
      case TransactionStatus.refunded:
        return AppColors.warning;
      case TransactionStatus.cancelled:
        return AppColors.error;
      case TransactionStatus.pending:
        return AppColors.info;
    }
  }

  IconData _getStatusIcon(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.completed:
        return Icons.check_circle;
      case TransactionStatus.refunded:
        return Icons.undo;
      case TransactionStatus.cancelled:
        return Icons.cancel;
      case TransactionStatus.pending:
        return Icons.pending;
    }
  }

  void _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _exportSales() {
    // TODO: Implement sales export
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export coming soon')),
    );
  }

  void _showTransactionDetails(Sale transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Transaction Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Receipt #', transaction.receiptNumber ?? 'N/A'),
              _buildDetailRow(
                  'Date',
                  DateFormat('MMM dd, yyyy hh:mm a')
                      .format(transaction.timestamp)),
              _buildDetailRow('Customer', transaction.customerName ?? 'N/A'),
              _buildDetailRow(
                  'Payment', transaction.paymentMethod.name.toUpperCase()),
              _buildDetailRow('Status', transaction.status.name.toUpperCase()),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Items:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.sm),
              ...transaction.items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text('${item.productName} x${item.quantity}'),
                        ),
                        Text(
                            '${AppConstants.currencySymbol}${item.subtotal.toStringAsFixed(2)}'),
                      ],
                    ),
                  )),
              const Divider(),
              _buildDetailRow('Subtotal',
                  '${AppConstants.currencySymbol}${transaction.subtotal.toStringAsFixed(2)}'),
              _buildDetailRow('Tax',
                  '${AppConstants.currencySymbol}${transaction.tax.toStringAsFixed(2)}'),
              _buildDetailRow('Discount',
                  '${AppConstants.currencySymbol}${transaction.discount.toStringAsFixed(2)}'),
              _buildDetailRow('Total',
                  '${AppConstants.currencySymbol}${transaction.total.toStringAsFixed(2)}',
                  isBold: true),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (transaction.status == TransactionStatus.completed) ...[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _refundTransaction(transaction.id);
              },
              child: const Text('Refund',
                  style: TextStyle(color: AppColors.error)),
            ),
            ElevatedButton(
              onPressed: () {
                // TODO: Print receipt
                Navigator.pop(context);
              },
              child: const Text('Print Receipt'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  void _refundTransaction(String transactionId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Refund'),
        content:
            const Text('Are you sure you want to refund this transaction?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final posService = context.read<POSService>();
              if (!context.mounted) return;
              await posService.refundTransaction(transactionId);
              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Transaction refunded successfully'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Refund'),
          ),
        ],
      ),
    );
  }
}
