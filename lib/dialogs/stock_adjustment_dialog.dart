import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../services/inventory_service.dart';
import '../utils/constants.dart';

class StockAdjustmentDialog extends StatelessWidget {
  final Product product;
  
  const StockAdjustmentDialog({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final currentStockController = TextEditingController(text: product.stock.toString());
    final adjustmentController = TextEditingController();
    final reasonController = TextEditingController();

    return AlertDialog(
      title: const Text('Adjust Stock'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Product: ${product.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.md),
            TextField(controller: currentStockController, decoration: const InputDecoration(labelText: 'Current Stock', enabled: false), enabled: false),
            const SizedBox(height: AppSpacing.sm),
            TextField(controller: adjustmentController, decoration: const InputDecoration(labelText: 'Adjustment (+/-)', hintText: 'e.g., +10 or -5'), keyboardType: TextInputType.number),
            const SizedBox(height: AppSpacing.sm),
            TextField(controller: reasonController, decoration: const InputDecoration(labelText: 'Reason (Optional)')),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            final adjustmentText = adjustmentController.text.trim();
            if (adjustmentText.isEmpty) {
              Navigator.pop(context);
              return;
            }

            final adjustment = int.parse(adjustmentText);
            final newStock = product.stock + adjustment;
            
            final inventoryService = context.read<InventoryService>();
            inventoryService.updateStock(product.id, newStock);
            
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Stock adjusted by $adjustment'), backgroundColor: AppColors.success),
            );
          },
          child: const Text('Adjust Stock'),
        ),
      ],
    );
  }
}