import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/sale.dart';
import '../models/customer.dart';
import '../services/pos_service.dart';
import '../services/print_service.dart';
import '../utils/constants.dart';

class CartPanel extends StatefulWidget {
  const CartPanel({super.key});

  @override
  State<CartPanel> createState() => _CartPanelState();
}

class _CartPanelState extends State<CartPanel> {
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _discountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final posService = context.watch<POSService>();
    final cartItems = posService.cartItems;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Text(
                  'Shopping Cart',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Cart items
          Expanded(
            child: cartItems.isEmpty
                ? _buildEmptyCart()
                : ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      return _buildCartItem(item);
                    },
                  ),
          ),

          // Payment and totals
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: const BoxDecoration(
              color: AppColors.background,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              children: [
                // Customer selection
                _buildCustomerSection(),

                const SizedBox(height: AppSpacing.md),

                // Payment method
                _buildPaymentMethodSection(),

                const SizedBox(height: AppSpacing.md),

                // Discount
                _buildDiscountSection(),

                const SizedBox(height: AppSpacing.md),

                // Totals
                _buildTotalsSection(),

                const SizedBox(height: AppSpacing.md),

                // Notes
                TextField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),

                const SizedBox(height: AppSpacing.md),

                // Process button
                SizedBox(
                  width: double.infinity,
                  height: AppSizes.buttonHeight,
                  child: ElevatedButton(
                    onPressed: cartItems.isEmpty ? null : _processTransaction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                    ),
                    child: Text(
                      'PROCESS ORDER • ${AppConstants.currencySymbol}${posService.cartTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: AppColors.textMuted.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Add products to get started',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(TransactionItem item) {
    final posService = context.read<POSService>();

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          // Product info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${AppConstants.currencySymbol}${item.price.toStringAsFixed(2)} each',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Quantity controls
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: () => posService.updateCartQuantity(
                  item.productId,
                  item.quantity - 1,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                ),
                child: Text(
                  item.quantity.toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => posService.updateCartQuantity(
                  item.productId,
                  item.quantity + 1,
                ),
              ),
            ],
          ),

          // Subtotal
          Container(
            width: 80,
            alignment: Alignment.centerRight,
            child: Text(
              '${AppConstants.currencySymbol}${item.subtotal.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),

          // Remove button
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: () => posService.removeFromCart(item.productId),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerSection() {
    final posService = context.watch<POSService>();
    final selectedCustomer = posService.selectedCustomer;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.person_outline, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              selectedCustomer?.name ?? 'Select Customer (for credit)',
              style: TextStyle(
                color: selectedCustomer != null
                    ? AppColors.textPrimary
                    : AppColors.textMuted,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _showCustomerSelection,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    final posService = context.watch<POSService>();
    final paymentMethod = posService.paymentMethod;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.payment, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          const Expanded(
            child: Text(
              'Payment Method',
              style: TextStyle(color: AppColors.textPrimary),
            ),
          ),
          DropdownButton<PaymentMethod>(
            value: paymentMethod,
            underline: const SizedBox(),
            items: PaymentMethod.values.map((method) {
              return DropdownMenuItem(
                value: method,
                child: Text(
                  method.name.toUpperCase(),
                  style: const TextStyle(fontSize: 12),
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                posService.setPaymentMethod(value);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountSection() {
    final posService = context.watch<POSService>();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_offer_outlined,
              color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          const Expanded(
            child: Text('Discount'),
          ),
          SizedBox(
            width: 100,
            child: TextField(
              controller: _discountController,
              decoration: const InputDecoration(
                prefixText: '${AppConstants.currencySymbol} ',
                isDense: true,
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final discount = double.tryParse(value) ?? 0.0;
                posService.setDiscount(discount);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalsSection() {
    final posService = context.watch<POSService>();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          _buildTotalRow('Subtotal', posService.cartSubtotal),
          if (posService.cartTax > 0) _buildTotalRow('Tax', posService.cartTax),
          if (posService.discountAmount > 0)
            _buildTotalRow('Discount', -posService.discountAmount),
          const Divider(),
          _buildTotalRow('Total', posService.cartTotal, isBold: true),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
            ),
          ),
          Text(
            '${AppConstants.currencySymbol}${amount.abs().toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
              color: amount < 0 ? AppColors.error : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _showCustomerSelection() {
    final posService = context.read<POSService>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Customer'),
        content: FutureBuilder<List<Customer>>(
          future: posService.getCustomers(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
            }
            final customers = snapshot.data ?? [];
            if (customers.isEmpty) return const Text('No customers');
            return SizedBox(
              width: 400,
              height: 300,
              child: ListView.builder(
                itemCount: customers.length,
                itemBuilder: (context, index) {
                  final c = customers[index];
                  return ListTile(
                    title: Text(c.name),
                    subtitle: Text(c.currentBalance.toStringAsFixed(2)),
                    onTap: () {
                      posService.selectCustomer(c);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  Future<void> _processTransaction() async {
    final posService = context.read<POSService>();

    // Haptic feedback
    HapticFeedback.mediumImpact();

    try {
      final transaction = await posService.processTransaction(
        notes: _notesController.text,
      );

      if (transaction != null) {
        if (!mounted) return;
          Navigator.of(context).pop();

        // Show success dialog
        if (!mounted) return;
          showDialog(
            context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Transaction Complete'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle,
                    size: 64, color: AppColors.success),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Receipt: ${transaction.receiptNumber}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Total: ${AppConstants.currencySymbol}${transaction.total.toStringAsFixed(2)}',
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  try {
                    await PrintService.printReceipt(transaction);
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(content: Text('Print error: $e'), backgroundColor: AppColors.error));
                  }
                },
                child: const Text('Print Receipt'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
