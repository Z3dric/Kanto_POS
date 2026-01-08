import 'package:flutter/material.dart';
import 'package:flutter/services.dart' as flutter_services;
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/product.dart';
import '../services/pos_service.dart';
import '../services/inventory_service.dart';
import '../widgets/product_card.dart';
import '../widgets/cart_panel.dart';
import '../widgets/search_bar.dart';
import '../utils/constants.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final inventoryService = context.read<InventoryService>();
    inventoryService.setSearchQuery(_searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    final posService = context.watch<POSService>();
    final inventoryService = context.watch<InventoryService>();
    final products = inventoryService.filteredProducts;
    final categories = inventoryService.categories;

    return Scaffold(
      appBar: AppBar(
        title: const Text('KantoPOS'),
        actions: [
          // Cart indicator
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () => _showCartPanel(),
              ),
              if (posService.cartItemCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                    ),
                    constraints:
                        const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      posService.cartItemCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),

          // Profile button
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ProfileScreen(),
                ),
              );
            },
          ),

          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddProductDialog(),
        backgroundColor: AppColors.accent,
        child: const Icon(Icons.add, size: 32),
      ),
      body: Column(
        children: [
          // Search and category filter
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                AppSearchBar(
                  controller: _searchController,
                  hintText: 'Search products...',
                  onChanged: (value) => inventoryService.setSearchQuery(value),
                ),
                const SizedBox(height: AppSpacing.sm),
                // Category chips
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.xs),
                        child: ChoiceChip(
                          label: Text(category),
                          selected: _selectedCategory == category,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = category;
                            });
                            inventoryService.setSelectedCategory(category);
                          },
                          labelStyle: TextStyle(
                            color: _selectedCategory == category
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Product grid
          Expanded(
            child: products.isEmpty
                ? _buildEmptyState()
                : GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: AppSpacing.md,
                      mainAxisSpacing: AppSpacing.md,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      // Use a key that changes when product data changes to force rebuild
                      return ProductCard(
                        key: ObjectKey(product),
                        product: product,
                        onTap: () => _addToCart(product),
                        onLongPress: () => _showProductOptions(product),
                      );
                    },
                  ),
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

  void _addToCart(Product product) {
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

  void _showCartPanel() {
    final inventoryService = context.read<InventoryService>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CartPanel(),
    ).then((_) async {
      // When modal closes, refresh inventory to ensure we have latest data
      // Use a small delay to allow the modal to fully close
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
      await inventoryService.refreshProducts();
    });
  }

  void _showAddProductDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final costController = TextEditingController();
    final stockController = TextEditingController();
    final categoryController = TextEditingController();
    final barcodeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Product'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Product Name'),
              ),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: costController,
                decoration: const InputDecoration(labelText: 'Cost'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: stockController,
                decoration: const InputDecoration(labelText: 'Stock'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              TextField(
                controller: barcodeController,
                decoration:
                    const InputDecoration(labelText: 'Barcode (Optional)'),
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
              if (nameController.text.isEmpty ||
                  priceController.text.isEmpty ||
                  costController.text.isEmpty ||
                  stockController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill in all required fields'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              final price = double.tryParse(priceController.text);
              final cost = double.tryParse(costController.text);
              final stock = int.tryParse(stockController.text);

              if (price == null || price < 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid numeric price'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              if (cost == null || cost < 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid numeric cost'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              if (stock == null || stock < 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid integer stock value'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              final inventoryService = context.read<InventoryService>();
              final newProduct = Product(
                id: const Uuid().v4(),
                name: nameController.text,
                price: price,
                cost: cost,
                stock: stock,
                category: categoryController.text.isEmpty
                    ? 'General'
                    : categoryController.text,
                barcode: barcodeController.text.isEmpty
                    ? null
                    : barcodeController.text,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );

              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              await inventoryService.addProduct(newProduct);
              if (!mounted) return;
              navigator.pop();
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Product added successfully'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('Add Product'),
          ),
        ],
      ),
    );
  }

  void _showProductOptions(Product product) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Product'),
              onTap: () {
                Navigator.pop(context);
                _editProduct(product);
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory),
              title: const Text('Adjust Stock'),
              onTap: () {
                Navigator.pop(context);
                _adjustStock(product);
              },
            ),
            ListTile(
              leading: Icon(
                  product.isActive ? Icons.visibility_off : Icons.visibility),
              title: Text(product.isActive ? 'Deactivate' : 'Activate'),
              onTap: () async {
                final inventoryService = context.read<InventoryService>();
                await inventoryService.toggleProductActive(product.id);
                if (!mounted) return;
                Navigator.of(this.context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _editProduct(Product product) {
    final nameController = TextEditingController(text: product.name);
    final priceController =
        TextEditingController(text: product.price.toString());
    final costController = TextEditingController(text: product.cost.toString());
    final stockController =
        TextEditingController(text: product.stock.toString());
    final categoryController = TextEditingController(text: product.category);
    final barcodeController =
        TextEditingController(text: product.barcode ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Product'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Product Name'),
              ),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: costController,
                decoration: const InputDecoration(labelText: 'Cost'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: stockController,
                decoration: const InputDecoration(labelText: 'Stock'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              TextField(
                controller: barcodeController,
                decoration: const InputDecoration(labelText: 'Barcode'),
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
              if (nameController.text.isEmpty ||
                  priceController.text.isEmpty ||
                  costController.text.isEmpty ||
                  stockController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill in all required fields'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              final price = double.tryParse(priceController.text);
              final cost = double.tryParse(costController.text);
              final stock = int.tryParse(stockController.text);

              if (price == null || price < 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid numeric price'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              if (cost == null || cost < 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid numeric cost'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              if (stock == null || stock < 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid integer stock value'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              final inventoryService = context.read<InventoryService>();
              final updatedProduct = product.copyWith(
                name: nameController.text,
                price: price,
                cost: cost,
                stock: stock,
                category: categoryController.text,
                barcode: barcodeController.text.isEmpty
                    ? null
                    : barcodeController.text,
              );

              await inventoryService.updateProduct(updatedProduct);
              if (!mounted) return;
              Navigator.of(this.context).pop();
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  void _adjustStock(Product product) {
    final stockController =
        TextEditingController(text: product.stock.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adjust Stock'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current stock: ${product.stock}'),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: stockController,
              decoration: const InputDecoration(labelText: 'New Stock'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newStock = int.tryParse(stockController.text);
              if (newStock == null || newStock < 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid integer stock value'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              final inventoryService = context.read<InventoryService>();
              await inventoryService.updateStock(product.id, newStock);
              if (!mounted) return;
              Navigator.of(this.context).pop();
            },
            child: const Text('Update Stock'),
          ),
        ],
      ),
    );
  }
}
