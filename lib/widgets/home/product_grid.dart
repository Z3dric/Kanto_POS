import 'package:flutter/material.dart';
import 'package:flutter/services.dart' as flutter_services;
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../services/pos_service.dart';
import '../../services/inventory_service.dart';
import '../../widgets/product_card.dart';
import '../../utils/constants.dart';
import '../../dialogs/edit_product_dialog.dart';
import '../../dialogs/stock_adjustment_dialog.dart';

class ProductGrid extends StatelessWidget {
  const ProductGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final inventoryService = context.watch<InventoryService>();
    final products = inventoryService.filteredProducts;

    return products.isEmpty
        ? _buildEmptyState()
        : GridView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ProductCard(
                product: product,
                onTap: () => _addToCart(context, product),
                onLongPress: () => _showProductOptions(context, product),
              );
            },
          );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/empty_state.png',
            width: 120,
            height: 120,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.shopping_basket_outlined,
              size: 120,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'No products found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Add products to start selling',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  void _addToCart(BuildContext context, Product product) {
    final posService = context.read<POSService>();

    if (product.stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product is out of stock'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    posService.addToCart(product);

    // Haptic feedback
    flutter_services.HapticFeedback.lightImpact();

    // Show success feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${product.name} to cart'),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showProductOptions(BuildContext context, Product product) {
    // Implementation moved to separate dialog
    showModalBottomSheet(
      context: context,
      builder: (context) => ProductOptionsDialog(product: product),
    );
  }
}

class ProductOptionsDialog extends StatelessWidget {
  final Product product;

  const ProductOptionsDialog({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Product'),
            onTap: () {
              Navigator.pop(context);
              _editProduct(context, product);
            },
          ),
          ListTile(
            leading: const Icon(Icons.inventory),
            title: const Text('Adjust Stock'),
            onTap: () {
              Navigator.pop(context);
              _adjustStock(context, product);
            },
          ),
          ListTile(
            leading: Icon(
                product.isActive ? Icons.visibility_off : Icons.visibility),
            title: Text(product.isActive ? 'Deactivate' : 'Activate'),
            onTap: () async {
              final inventoryService = context.read<InventoryService>();
              if (!context.mounted) return;
              await inventoryService.toggleProductActive(product.id);
              if (!context.mounted) return;
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _editProduct(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (context) => EditProductDialog(product: product),
    );
  }

  void _adjustStock(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (context) => StockAdjustmentDialog(product: product),
    );
  }
}
