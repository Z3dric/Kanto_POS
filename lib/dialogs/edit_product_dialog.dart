import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../services/inventory_service.dart';
import '../utils/constants.dart';

class EditProductDialog extends StatelessWidget {
  final Product product;
  
  const EditProductDialog({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final nameController = TextEditingController(text: product.name);
    final priceController = TextEditingController(text: product.price.toString());
    final costController = TextEditingController(text: product.cost.toString());
    final stockController = TextEditingController(text: product.stock.toString());
    final categoryController = TextEditingController(text: product.category);
    // barcode removed
    final minStockController = TextEditingController(text: product.minStock.toString());

    return AlertDialog(
      title: const Text('Edit Product'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Product Name *')),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(child: TextField(controller: priceController, decoration: const InputDecoration(labelText: 'Price *', prefixText: '₱ '), keyboardType: TextInputType.number)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: TextField(controller: costController, decoration: const InputDecoration(labelText: 'Cost *', prefixText: '₱ '), keyboardType: TextInputType.number)),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(child: TextField(controller: stockController, decoration: const InputDecoration(labelText: 'Stock *'), keyboardType: TextInputType.number)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: TextField(controller: minStockController, decoration: const InputDecoration(labelText: 'Min Stock'), keyboardType: TextInputType.number)),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(controller: categoryController, decoration: const InputDecoration(labelText: 'Category')),
            const SizedBox(height: AppSpacing.sm),
            // barcode field removed
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            final inventoryService = context.read<InventoryService>();
            final updatedProduct = product.copyWith(
              name: nameController.text,
              price: double.parse(priceController.text),
              cost: double.parse(costController.text),
              stock: int.parse(stockController.text),
              category: categoryController.text,
              barcode: null,
              minStock: int.parse(minStockController.text),
            );

            if (!context.mounted) return;
            await inventoryService.updateProduct(updatedProduct);
            if (!context.mounted) return;
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Product updated successfully'), backgroundColor: AppColors.success),
            );
          },
          child: const Text('Save Changes'),
        ),
      ],
    );
  }
}
