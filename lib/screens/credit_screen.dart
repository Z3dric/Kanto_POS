import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/customer.dart';
import '../services/pos_service.dart';
import '../widgets/search_bar.dart';
import '../utils/constants.dart';

class CreditScreen extends StatefulWidget {
  const CreditScreen({super.key});

  @override
  State<CreditScreen> createState() => _CreditScreenState();
}

class _CreditScreenState extends State<CreditScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _paymentAmountController =
      TextEditingController();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerPhoneController =
      TextEditingController();
  final TextEditingController _customerAddressController =
      TextEditingController();
  final TextEditingController _creditLimitController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    _paymentAmountController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _customerAddressController.dispose();
    _creditLimitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final posService = context.watch<POSService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Credit Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: _showAddCustomerDialog,
          ),
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            onPressed: _showCreditAnalytics,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCustomerDialog,
        backgroundColor: AppColors.accent,
        child: const Icon(Icons.person_add, size: 32),
      ),
      body: Column(
        children: [
          _buildCreditSummary(),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: AppSearchBar(
              controller: _searchController,
              hintText: 'Search customers...',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: FutureBuilder<List<Customer>>(
              future: posService.getCustomers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final customers = snapshot.data ?? [];

                if (customers.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: customers.length,
                  itemBuilder: (context, index) {
                    final customer = customers[index];
                    return _buildCustomerItem(customer);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // customer list is loaded from DB via POSService.getCustomers()

  Widget _buildCreditSummary() {
    final posService = context.watch<POSService>();

    return FutureBuilder<Map<String, dynamic>>(
      future: posService.getCreditSummary(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: LinearProgressIndicator(),
          );
        }

        final summary = snapshot.data!;
        final totalOutstanding = summary['totalOutstanding'] as double;
        final totalCustomers = summary['totalCustomers'] as int;
        final overdueAccounts = summary['overdueAccounts'] as int;

        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Outstanding',
                  '${AppConstants.currencySymbol}${totalOutstanding.toStringAsFixed(2)}',
                  Icons.credit_card,
                  AppColors.warning,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildSummaryCard(
                  'Customers',
                  totalCustomers.toString(),
                  Icons.people,
                  AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildSummaryCard(
                  'Overdue',
                  overdueAccounts.toString(),
                  Icons.warning_amber,
                  AppColors.error,
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
            Icons.people_outline,
            size: 120,
            color: AppColors.textMuted.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'No customers with credit',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Add customers to manage credit accounts',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerItem(Customer customer) {
    final creditUtilization = customer.creditLimit > 0
        ? (customer.currentBalance / customer.creditLimit) * 100
        : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        boxShadow: AppShadows.card,
      ),
      child: ExpansionTile(
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  if (customer.phone != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      customer.phone!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${AppConstants.currencySymbol}${customer.currentBalance.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: customer.currentBalance > 0
                        ? AppColors.warning
                        : AppColors.success,
                  ),
                ),
                Text(
                  'Limit: ${AppConstants.currencySymbol}${customer.creditLimit.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            if (customer.creditLimit > 0) ...[
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: creditUtilization / 100,
                      backgroundColor: AppColors.background,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        creditUtilization > 80
                            ? AppColors.error
                            : creditUtilization > 60
                                ? AppColors.warning
                                : AppColors.success,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '${creditUtilization.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
            Text(
              'Available: ${AppConstants.currencySymbol}${customer.availableCredit.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: const BoxDecoration(
              color: AppColors.background,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: customer.currentBalance > 0
                            ? () => _showPaymentDialog(customer)
                            : null,
                        icon: const Icon(Icons.payment),
                        label: const Text('Payment'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showCustomerHistory(customer),
                        icon: const Icon(Icons.history),
                        label: const Text('History'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                if (customer.address != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          customer.address!,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Since: ${DateFormat('MMM dd, yyyy').format(customer.createdAt)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    const Icon(Icons.credit_card_outlined,
                        size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Credit Limit: ${AppConstants.currencySymbol}${customer.creditLimit.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddCustomerDialog() {
    _customerNameController.clear();
    _customerPhoneController.clear();
    _customerAddressController.clear();
    _creditLimitController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Customer'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _customerNameController,
                decoration: const InputDecoration(
                  labelText: 'Customer Name *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _customerPhoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _customerAddressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _creditLimitController,
                decoration: const InputDecoration(
                  labelText: 'Credit Limit',
                  border: OutlineInputBorder(),
                  prefixText: '${AppConstants.currencySymbol} ',
                ),
                keyboardType: TextInputType.number,
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
              if (_customerNameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter customer name'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              final posService = context.read<POSService>();
              final creditLimit = double.tryParse(_creditLimitController.text) ?? 0.0;
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);

              try {
                await posService.addCustomer(
                  name: _customerNameController.text,
                  phone: _customerPhoneController.text.isNotEmpty ? _customerPhoneController.text : null,
                  address: _customerAddressController.text.isNotEmpty ? _customerAddressController.text : null,
                  creditLimit: creditLimit,
                );

                if (!mounted) return;
                navigator.pop();

                // Refresh the UI by triggering a rebuild
                setState(() {});

                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Customer added successfully'),
                    backgroundColor: AppColors.success,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Error adding customer: $e'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Add Customer'),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog(Customer customer) {
    _paymentAmountController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Payment from ${customer.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Outstanding Balance: ${AppConstants.currencySymbol}${customer.currentBalance.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _paymentAmountController,
                decoration: const InputDecoration(
                  labelText: 'Payment Amount',
                  border: OutlineInputBorder(),
                  prefixText: '${AppConstants.currencySymbol} ',
                ),
                keyboardType: TextInputType.number,
                autofocus: true,
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () => _paymentAmountController.text =
                        customer.currentBalance.toString(),
                    child: const Text('Full Amount'),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  ElevatedButton(
                    onPressed: () => _paymentAmountController.text = '100',
                    child: const Text('₱100'),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  ElevatedButton(
                    onPressed: () => _paymentAmountController.text = '50',
                    child: const Text('₱50'),
                  ),
                ],
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
              final amount =
                  double.tryParse(_paymentAmountController.text) ?? 0;
              if (amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid amount'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              if (amount > customer.currentBalance) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Payment amount exceeds outstanding balance'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              Navigator.pop(context);

              final posService = context.read<POSService>();
              final messenger = ScaffoldMessenger.of(context);
              try {
                await posService.processCreditPayment(customer.id, amount);
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                        'Payment of ${AppConstants.currencySymbol}${amount.toStringAsFixed(2)} recorded'),
                    backgroundColor: AppColors.success,
                  ),
                );
                setState(() {});
              } catch (e) {
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Failed to record payment: $e'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Record Payment'),
          ),
        ],
      ),
    );
  }

  void _showCustomerHistory(Customer customer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchCustomerTransactionHistory(customer.id),
        builder: (context, snapshot) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${customer.name} - Transaction History',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (snapshot.hasError)
                  Expanded(
                    child: Center(
                      child: Text('Error: ${snapshot.error}'),
                    ),
                  )
                else
                  Expanded(
                    child: snapshot.data?.isEmpty ?? true
                        ? const Center(
                            child: Text('No transactions found'),
                          )
                        : ListView.builder(
                            itemCount: snapshot.data?.length ?? 0,
                            itemBuilder: (context, index) {
                              final transaction = snapshot.data![index];
                              final isPayment = transaction['type'] == 'payment';

                              return Container(
                                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                                padding: const EdgeInsets.all(AppSpacing.md),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius:
                                      BorderRadius.circular(AppBorderRadius.md),
                                  boxShadow: AppShadows.card,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: isPayment
                                            ? AppColors.success
                                                .withValues(alpha: 0.1)
                                            : AppColors.primary
                                                .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(
                                            AppBorderRadius.sm),
                                      ),
                                      child: Icon(
                                        isPayment
                                            ? Icons.payments
                                            : Icons.shopping_cart,
                                        color: isPayment
                                            ? AppColors.success
                                            : AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            transaction['description']
                                                as String,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600),
                                          ),
                                          Text(
                                            DateFormat('MMM dd, yyyy').format(
                                                transaction['date']
                                                    as DateTime),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '${isPayment ? "" : "-"}${AppConstants.currencySymbol}${(transaction['amount'] as double).abs().toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isPayment
                                            ? AppColors.success
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchCustomerTransactionHistory(
      String customerId) async {
    final posService = context.read<POSService>();
    final transactions = <Map<String, dynamic>>[];

    // Get all transactions for this customer
    final allTransactions = posService.transactions
        .where((t) => t.customerId == customerId)
        .toList();

    for (final sale in allTransactions) {
      transactions.add({
        'date': sale.timestamp,
        'amount': sale.total,
        'type': 'purchase',
        'description': 'Sales - ${sale.items.map((i) => i.productName).join(", ")}',
      });
    }

    // Sort by date descending
    transactions.sort((a, b) =>
        (b['date'] as DateTime).compareTo(a['date'] as DateTime));

    return transactions;
  }

  void _showCreditAnalytics() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Credit analytics coming soon')),
    );
  }
}
