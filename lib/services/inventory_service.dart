import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/product.dart';
import 'database_service.dart';

class InventoryService extends ChangeNotifier {
  final Uuid _uuid = const Uuid();
  
  List<Product> _products = [];
  List<String> _categories = [];
  String _selectedCategory = 'All';
  String _searchQuery = '';
  String? _currentUserId;

  InventoryService() {
    _loadProducts();
  }
  
  // Get current database service instance
  DatabaseService get _databaseService => DatabaseService.instance;

  // Getters
  List<Product> get products => _products;
  List<String> get categories => _categories;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  
  List<Product> get filteredProducts {
    var filtered = _products;
    
    // Filter by category
    if (_selectedCategory != 'All') {
      filtered = filtered.where((p) => p.category == _selectedCategory).toList();
    }
    
    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((p) => 
        p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        (p.barcode?.contains(_searchQuery) ?? false) ||
        p.category.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    return filtered;
  }
  
  List<Product> get lowStockProducts => _products.where((p) => p.isLowStock).toList();
  List<Product> get outOfStockProducts => _products.where((p) => p.isOutOfStock).toList();

  // Handle user change
  void updateUser(String? userId) {
    if (_currentUserId != userId) {
      _currentUserId = userId;
      _products.clear();
      _categories.clear();
      _selectedCategory = 'All';
      _loadProducts();
    }
  }

  // Product operations
  Future<void> addProduct(Product product) async {
    final newProduct = product.copyWith(
      id: _uuid.v4(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _databaseService.insert('products', newProduct.toMap());
    await _loadProducts();
  }

  Future<void> updateProduct(Product product) async {
    final updatedProduct = product.copyWith(
      updatedAt: DateTime.now(),
    );

    await _databaseService.update(
      'products',
      updatedProduct.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
    await _loadProducts();
  }

  Future<void> deleteProduct(String productId) async {
    await _databaseService.delete(
      'products',
      where: 'id = ?',
      whereArgs: [productId],
    );
    await _loadProducts();
  }

  Future<void> toggleProductActive(String productId) async {
    final product = _products.firstWhere((p) => p.id == productId);
    await _databaseService.update(
      'products',
      {'isActive': product.isActive ? 0 : 1},
      where: 'id = ?',
      whereArgs: [productId],
    );
    await _loadProducts();
  }

  // Stock management
  Future<void> updateStock(String productId, int newStock) async {
    await _databaseService.update(
      'products',
      {'stock': newStock},
      where: 'id = ?',
      whereArgs: [productId],
    );
    await _loadProducts();
  }

  Future<void> adjustStock(String productId, int adjustment, {String? reason}) async {
    await _databaseService.rawUpdate('''
      UPDATE products 
      SET stock = stock + ?,
          updatedAt = ?
      WHERE id = ?
    ''', [adjustment, DateTime.now().toIso8601String(), productId]);
    // Log stock adjustment for audit trail (best-effort if table exists)
    try {
      await _databaseService.insert('inventory_audit', {
        'id': _uuid.v4(),
        'productId': productId,
        'adjustment': adjustment,
        'reason': reason,
        'timestamp': DateTime.now().toIso8601String(),
        'user': null,
      });
    } catch (_) {
      // ignore if audit table not present
    }
    await _loadProducts();
  }

  Future<void> receiveStock(String productId, int quantity, double cost) async {
    await _databaseService.transaction((txn) async {
      // Update stock
      await txn.rawUpdate('''
        UPDATE products 
        SET stock = stock + ?,
            cost = ?,
            updatedAt = ?
        WHERE id = ?
      ''', [quantity, cost, DateTime.now().toIso8601String(), productId]);
    });
    
    await _loadProducts();
  }

  // Category management
  Future<void> addCategory(String category) async {
    if (!_categories.contains(category)) {
      _categories.add(category);
      notifyListeners();
    }
  }

  Future<void> updateCategory(String oldName, String newName) async {
    await _databaseService.transaction((txn) async {
      // Update all products with the old category name
      await txn.rawUpdate('''
        UPDATE products 
        SET category = ?,
            updatedAt = ?
        WHERE category = ?
      ''', [newName, DateTime.now().toIso8601String(), oldName]);
    });
    
    await _loadProducts();
  }

  // Search and filtering
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = 'All';
    notifyListeners();
  }

  // Product queries
  Future<Product?> getProductByBarcode(String barcode) async {
    final result = await _databaseService.query(
      'products',
      where: 'barcode = ? AND isActive = 1',
      whereArgs: [barcode],
    );

    if (result.isNotEmpty) {
      return Product.fromMap(result.first);
    }
    return null;
  }

  Future<Product?> getProductById(String id) async {
    final result = await _databaseService.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isNotEmpty) {
      return Product.fromMap(result.first);
    }
    return null;
  }

  Future<List<Product>> getLowStockProducts() async {
    final result = await _databaseService.query(
      'products',
      where: 'stock <= minStock AND minStock > 0 AND isActive = 1',
    );

    return result.map((map) => Product.fromMap(map)).toList();
  }

  Future<List<Product>> getOutOfStockProducts() async {
    final result = await _databaseService.query(
      'products',
      where: 'stock <= 0 AND isActive = 1',
    );

    return result.map((map) => Product.fromMap(map)).toList();
  }

  // Analytics
  Future<Map<String, dynamic>> getInventoryAnalytics() async {
    final result = await _databaseService.rawQuery('''
      SELECT 
        COUNT(*) as totalProducts,
        SUM(stock) as totalStock,
        SUM(stock * cost) as totalValue,
        SUM(CASE WHEN stock <= minStock AND minStock > 0 THEN 1 ELSE 0 END) as lowStockCount,
        SUM(CASE WHEN stock <= 0 THEN 1 ELSE 0 END) as outOfStockCount
      FROM products 
      WHERE isActive = 1
    ''');

    final data = result.first;
    return {
      'totalProducts': data['totalProducts'] ?? 0,
      'totalStock': data['totalStock'] ?? 0,
      'totalValue': data['totalValue'] ?? 0.0,
      'lowStockCount': data['lowStockCount'] ?? 0,
      'outOfStockCount': data['outOfStockCount'] ?? 0,
    };
  }

  Future<List<Map<String, dynamic>>> getCategoryAnalytics() async {
    final result = await _databaseService.rawQuery('''
      SELECT 
        category,
        COUNT(*) as productCount,
        SUM(stock) as totalStock,
        SUM(stock * cost) as totalValue,
        AVG(price) as avgPrice,
        SUM(CASE WHEN stock <= minStock AND minStock > 0 THEN 1 ELSE 0 END) as lowStockCount
      FROM products 
      WHERE isActive = 1
      GROUP BY category
      ORDER BY totalValue DESC
    ''');

    return result;
  }

  // Data loading
  Future<void> _loadProducts() async {
    final result = await _databaseService.query(
      'products',
      orderBy: 'name ASC',
    );

    _products = result.map((map) => Product.fromMap(map)).toList();
    _updateCategories();
    notifyListeners();
  }

  // Public method to refresh products (called after sales/inventory updates)
  Future<void> refreshProducts() async {
    // Clear current products to ensure fresh load
    _products.clear();
    await _loadProducts();
  }

  void _updateCategories() {
    final categorySet = _products.map((p) => p.category).toSet();
    _categories = ['All', ...categorySet];
  }

  // Import/Export
  Future<void> importProducts(List<Product> products) async {
    await _databaseService.transaction((txn) async {
      for (final product in products) {
        await txn.insert('products', product.toMap());
      }
    });
    await _loadProducts();
  }

  Future<List<Product>> exportProducts() async {
    final result = await _databaseService.query('products');
    return result.map((map) => Product.fromMap(map)).toList();
  }

  // Search suggestions
  Future<List<String>> getProductNameSuggestions(String query) async {
    final result = await _databaseService.rawQuery('''
      SELECT DISTINCT name 
      FROM products 
      WHERE name LIKE ? AND isActive = 1
      ORDER BY name
      LIMIT 10
    ''', ['%$query%']);

    return result.map((row) => row['name'] as String).toList();
  }

  Future<List<String>> getBarcodeSuggestions(String query) async {
    final result = await _databaseService.rawQuery('''
      SELECT DISTINCT barcode 
      FROM products 
      WHERE barcode LIKE ? AND isActive = 1
      ORDER BY barcode
      LIMIT 10
    ''', ['%$query%']);

    return result
        .where((row) => row['barcode'] != null)
        .map((row) => row['barcode'] as String)
        .toList();
  }

}