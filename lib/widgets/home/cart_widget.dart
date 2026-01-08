import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart' as flutter_services;
import 'package:provider/provider.dart';
import 'package:simple_pos/models/sale.dart' show PaymentMethod;
import 'package:simple_pos/services/pos_service.dart';
import 'package:simple_pos/services/inventory_service.dart';
import 'package:simple_pos/utils/constants.dart';

class CartWidget extends StatelessWidget {
  const CartWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
          color: AppColors.background,
          border: Border(top: BorderSide(color: AppColors.border))),
      child: const CartContent(),
    );
  }
}

class CartContent extends StatefulWidget {
  const CartContent({super.key});

  @override
  State<CartContent> createState() => _CartContentState();
}

class _CartContentState extends State<CartContent> {
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
    return Column(
      children: [
        const CustomerSelectionSection(),
        const SizedBox(height: AppSpacing.md),
        const PaymentMethodSection(),
        const SizedBox(height: AppSpacing.md),
        DiscountSection(discountController: _discountController),
        const SizedBox(height: AppSpacing.md),
        const TotalsSection(),
        const SizedBox(height: AppSpacing.md),
        TextField(
            controller: _notesController,
            decoration: const InputDecoration(
                labelText: 'Notes (Optional)', border: OutlineInputBorder()),
            maxLines: 2),
        const SizedBox(height: AppSpacing.md),
        ProcessOrderButton(notesController: _notesController),
      ],
    );
  }
}

class CustomerSelectionSection extends StatelessWidget {
  const CustomerSelectionSection({super.key});

  @override
  Widget build(BuildContext context) {
    final posService = context.watch<POSService>();
    final selectedCustomer = posService.selectedCustomer;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          border: Border.all(color: AppColors.border)),
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
                          : AppColors.textMuted))),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: () {}),
        ],
      ),
    );
  }
}

class PaymentMethodSection extends StatelessWidget {
  const PaymentMethodSection({super.key});

  @override
  Widget build(BuildContext context) {
    final posService = context.watch<POSService>();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          border: Border.all(color: AppColors.border)),
      child: Row(
        children: [
          const Icon(Icons.payment, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          const Expanded(
              child: Text('Payment Method',
                  style: TextStyle(color: AppColors.textPrimary))),
          DropdownButton<PaymentMethod>(
            value: posService.paymentMethod,
            underline: const SizedBox(),
            items: PaymentMethod.values.map((method) {
              return DropdownMenuItem(
                  value: method,
                  child: Text(method.name.toUpperCase(),
                      style: const TextStyle(fontSize: 12)));
            }).toList(),
            onChanged: (value) {
              if (value != null) posService.setPaymentMethod(value);
            },
          ),
        ],
      ),
    );
  }
}

class DiscountSection extends StatelessWidget {
  final TextEditingController discountController;

  const DiscountSection({super.key, required this.discountController});

  @override
  Widget build(BuildContext context) {
    final posService = context.watch<POSService>();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          border: Border.all(color: AppColors.border)),
      child: Row(
        children: [
          const Icon(Icons.local_offer_outlined,
              color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          const Expanded(child: Text('Discount')),
          SizedBox(
              width: 100,
              child: TextField(
                  controller: discountController,
                  decoration: const InputDecoration(
                      prefixText: '₱ ',
                      isDense: true,
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                  keyboardType: TextInputType.number,
                  onChanged: (value) =>
                      posService.setDiscount(double.tryParse(value) ?? 0.0))),
        ],
      ),
    );
  }
}

class TotalsSection extends StatelessWidget {
  const TotalsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final posService = context.watch<POSService>();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          boxShadow: AppShadows.card),
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
          Text(label,
              style: TextStyle(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text('${amount >= 0 ? "" : "-"}₱${amount.abs().toStringAsFixed(2)}',
              style: TextStyle(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  color: amount < 0 ? AppColors.error : AppColors.textPrimary)),
        ],
      ),
    );
  }
}

class ProcessOrderButton extends StatelessWidget {
  final TextEditingController notesController;

  const ProcessOrderButton({super.key, required this.notesController});

  @override
  Widget build(BuildContext context) {
    final posService = context.watch<POSService>();

    return SizedBox(
      width: double.infinity,
      height: AppSizes.buttonHeight,
      child: ElevatedButton(
        onPressed: posService.cartItems.isEmpty
            ? null
            : () => _processTransaction(context),
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
        child: Text(
            'PROCESS ORDER • ₱${posService.cartTotal.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Future<void> _processTransaction(BuildContext context) async {
    flutter_services.HapticFeedback.mediumImpact();

    try {
      final posService = context.read<POSService>();
      
      // Validate payment method
      if (posService.paymentMethod == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a payment method')),
          );
        }
        return;
      }

      // Process the transaction
      final sale = await posService.processTransaction(
        notes: notesController.text.isEmpty ? null : notesController.text,
      );

      if (sale != null && context.mounted) {
        // Reload inventory data to update UI
        final inventoryService = context.read<InventoryService>();
        
        // Force a complete refresh of the inventory products from database
        // This awaits the database query and notifies listeners
        await inventoryService.refreshProducts();
        
        // Use scheduler binding to ensure the frame is rendered before closing modal
        await SchedulerBinding.instance.endOfFrame;
        
        // Clear notes
        notesController.clear();

        // Show success message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Transaction processed! Receipt: ${sale.receiptNumber ?? 'N/A'}'),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        
        // Close the modal - this allows the home screen to rebuild with updated inventory
        if (context.mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
