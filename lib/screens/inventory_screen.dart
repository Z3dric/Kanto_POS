import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/inventory_service.dart';
import '../widgets/search_bar.dart';
import '../widgets/inventory/inventory_widgets.dart';
import '../utils/constants.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';

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
    final inventoryService = context.read<InventoryService>();
    inventoryService.setSearchQuery(_searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    final inventoryService = context.watch<InventoryService>();
    final categories = inventoryService.categories;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Management'),
        actions: [
          IconButton(icon: const Icon(Icons.analytics_outlined), onPressed: _showInventoryAnalytics),
          IconButton(icon: const Icon(Icons.file_download_outlined), onPressed: _exportInventory),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddProductDialog,
        backgroundColor: AppColors.accent,
        child: const Icon(Icons.add, size: 32),
      ),
      body: Column(
        children: [
          _buildSummaryCards(),
          _buildSearchAndFilters(categories),
          const Expanded(child: ProductList()),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final inventoryService = context.watch<InventoryService>();

    return FutureBuilder<Map<String, dynamic>>(
      future: inventoryService.getInventoryAnalytics(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: LinearProgressIndicator(),
          );
        }

        final analytics = snapshot.data!;
        final totalProducts = analytics['totalProducts'] as int;
        final lowStockCount = analytics['lowStockCount'] as int;
        final outOfStockCount = analytics['outOfStockCount'] as int;

        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(child: _buildSummaryCard('Total Products', totalProducts.toString(), Icons.inventory, AppColors.primary)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _buildSummaryCard('Low Stock', lowStockCount.toString(), Icons.warning_amber, AppColors.warning)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _buildSummaryCard('Out of Stock', outOfStockCount.toString(), Icons.error, AppColors.error)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppBorderRadius.md), boxShadow: AppShadows.card),
      child: Column(children: [Icon(icon, size: 32, color: color), const SizedBox(height: AppSpacing.sm), Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)), const SizedBox(height: AppSpacing.xs), Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), textAlign: TextAlign.center)]),
    );
  }

  Widget _buildSearchAndFilters(List<String> categories) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          AppSearchBar(controller: _searchController, hintText: 'Search products...'),
          const SizedBox(height: AppSpacing.sm),
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
                      if (selected) {
                        setState(() => _selectedCategory = category);
                        context.read<InventoryService>().setSelectedCategory(category);
                      }
                    },
                    labelStyle: TextStyle(color: _selectedCategory == category ? Colors.white : AppColors.textPrimary),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddProductDialog() {
    showDialog(context: context, builder: (context) => const AddProductDialog());
  }

  void _showInventoryAnalytics() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Analytics coming soon')));
  }

  void _exportInventory() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export coming soon')));
  }
}
