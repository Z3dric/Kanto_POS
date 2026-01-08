import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../services/inventory_service.dart';
import '../utils/constants.dart';

class AddProductDialog extends StatelessWidget {
  const AddProductDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final costController = TextEditingController();
    final stockController = TextEditingController();
    final categoryController = TextEditingController();
    final barcodeController = TextEditingController();
    final minStockController = TextEditingController();

    return AlertDialog(
      title: const Text('Add New Product'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Product Name *', border: OutlineInputBorder())),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(child: TextField(controller: priceController, decoration: const InputDecoration(labelText: 'Price *', border: OutlineInputBorder(), prefixText: '₱ '), keyboardType: TextInputType.number)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: TextField(controller: costController, decoration: const InputDecoration(labelText: 'Cost *', border: OutlineInputBorder(), prefixText: '₱ '), keyboardType: TextInputType.number)),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(child: TextField(controller: stockController, decoration: const InputDecoration(labelText: 'Stock *', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: TextField(controller: minStockController, decoration: const InputDecoration(labelText: 'Min Stock', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(controller: categoryController, decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder())),
            const SizedBox(height: AppSpacing.sm),
            TextField(controller: barcodeController, decoration: const InputDecoration(labelText: 'Barcode (Optional)', border: OutlineInputBorder())),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            if (nameController.text.isEmpty || priceController.text.isEmpty || costController.text.isEmpty || stockController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in all required fields'), backgroundColor: AppColors.error));
              return;
            }

            final inventoryService = context.read<InventoryService>();
            final newProduct = Product(
              id: '',
              name: nameController.text,
              price: double.parse(priceController.text),
              cost: double.parse(costController.text),
              stock: int.parse(stockController.text),
              category: categoryController.text.isEmpty ? 'General' : categoryController.text,
              barcode: barcodeController.text.isEmpty ? null : barcodeController.text,
              minStock: minStockController.text.isEmpty ? 0 : int.parse(minStockController.text),
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );

            if (!context.mounted) return;
            await inventoryService.addProduct(newProduct);
            if (!context.mounted) return;
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product added successfully'), backgroundColor: AppColors.success));
          },
          child: const Text('Add Product'),
        ),
      ],
    );
  }
}