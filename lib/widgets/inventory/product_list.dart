import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../services/inventory_service.dart';
import '../../utils/constants.dart';
import '../../dialogs/edit_product_dialog.dart';
import '../../dialogs/stock_adjustment_dialog.dart';

class ProductList extends StatelessWidget {
  const ProductList({super.key});

  @override
  Widget build(BuildContext context) {
    final inventoryService = context.watch<InventoryService>();
    final products = inventoryService.filteredProducts;

    return products.isEmpty
        ? _buildEmptyState()
        : ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              // Use ObjectKey to force rebuild when product object changes
              return ProductListItem(
                key: ObjectKey(product),
                product: product,
              );
            },
          );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 120, color: AppColors.textMuted.withValues(alpha: 0.5)),
          const SizedBox(height: AppSpacing.lg),
          const Text('No products found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.sm),
          const Text('Add products to manage your inventory', style: TextStyle(color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class ProductListItem extends StatelessWidget {
  final Product product;
  
  const ProductListItem({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppBorderRadius.md), boxShadow: AppShadows.card),
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppSpacing.md),
        leading: _buildProductImage(),
        title: _buildProductInfo(),
        subtitle: _buildProductDetails(),
        trailing: _buildPopupMenu(context),
      ),
    );
  }

  Widget _buildProductImage() {
    return Container(
      width: 50, height: 50,
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(AppBorderRadius.sm)),
      child: product.imagePath != null
          ? Image.asset(product.imagePath!, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Icon(Icons.shopping_bag_outlined, size: 32, color: AppColors.textMuted))
          : const Icon(Icons.shopping_bag_outlined, size: 32, color: AppColors.textMuted),
    );
  }

  Widget _buildProductInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        Text(product.category, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildProductDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Text('₱${product.price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
        const SizedBox(height: 4),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: _getStockColor(product.stock, product.minStock), borderRadius: BorderRadius.circular(AppBorderRadius.sm)),
              child: Text('Stock: ${product.stock}', style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
            ),
            if (product.isLowStock) const SizedBox(width: AppSpacing.xs),
            if (product.isLowStock) const Icon(Icons.warning_amber, size: 16, color: AppColors.warning),
          ],
        ),
      ],
    );
  }

  Widget _buildPopupMenu(BuildContext context) {
    return PopupMenuButton(
      icon: const Icon(Icons.more_vert),
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit), title: Text('Edit'), contentPadding: EdgeInsets.zero)),
        const PopupMenuItem(value: 'stock', child: ListTile(leading: Icon(Icons.inventory), title: Text('Adjust Stock'), contentPadding: EdgeInsets.zero)),
        const PopupMenuItem(value: 'barcode', child: ListTile(leading: Icon(Icons.qr_code), title: Text('View Barcode'), contentPadding: EdgeInsets.zero)),
        PopupMenuItem(value: 'toggle', child: ListTile(leading: Icon(product.isActive ? Icons.visibility_off : Icons.visibility), title: Text(product.isActive ? 'Deactivate' : 'Activate'), contentPadding: EdgeInsets.zero)),
        const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete, color: AppColors.error), title: Text('Delete', style: TextStyle(color: AppColors.error)), contentPadding: EdgeInsets.zero)),
      ],
      onSelected: (value) => _handleProductAction(context, value, product),
    );
  }

  Color _getStockColor(int stock, int minStock) {
    if (stock <= 0) return AppColors.error;
    if (stock <= minStock && minStock > 0) return AppColors.warning;
    return AppColors.success;
  }

  void _handleProductAction(BuildContext context, String action, Product product) {
    switch (action) {
      case 'edit':
        showDialog(context: context, builder: (context) => EditProductDialog(product: product));
        break;
      case 'stock':
        showDialog(context: context, builder: (context) => StockAdjustmentDialog(product: product));
        break;
      case 'barcode':
        _showBarcodeDialog(context, product);
        break;
      case 'toggle':
        context.read<InventoryService>().toggleProductActive(product.id);
        break;
      case 'delete':
        _showDeleteConfirmation(context, product);
        break;
    }
  }

  void _showBarcodeDialog(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Product Barcode'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          if (product.barcode != null) ...[
            Container(padding: const EdgeInsets.all(AppSpacing.md), decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(AppBorderRadius.md)), child: Column(children: [
              Text(product.barcode!, style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: AppSpacing.md),
              Container(height: 100, color: Colors.white, child: Center(child: Text(product.barcode!, style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 24)))),
            ])),
          ] else ...[
            const Text('No barcode assigned'),
          ],
          const SizedBox(height: AppSpacing.md),
          Text('Product: ${product.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
        ]),
        actions: [
          if (product.barcode != null)
            TextButton(onPressed: () { Navigator.pop(context); }, child: const Text('Close')),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () async {
            if (!context.mounted) return;
            await context.read<InventoryService>().deleteProduct(product.id);
            if (!context.mounted) return;
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product deleted successfully'), backgroundColor: AppColors.error));
          }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.error), child: const Text('Delete')),
        ],
      ),
    );
  }
}
