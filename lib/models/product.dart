class Product {
  final String id;
  final String name;
  final String? description;
  final double price;
  final double cost;
  final int stock;
  final int minStock;
  final String? barcode;
  final String? imagePath;
  final String category;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.cost,
    required this.stock,
    this.minStock = 0,
    this.barcode,
    this.imagePath,
    required this.category,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    double? cost,
    int? stock,
    int? minStock,
    String? barcode,
    String? imagePath,
    String? category,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      cost: cost ?? this.cost,
      stock: stock ?? this.stock,
      minStock: minStock ?? this.minStock,
      barcode: barcode ?? this.barcode,
      imagePath: imagePath ?? this.imagePath,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'cost': cost,
      'stock': stock,
      'minStock': minStock,
      'barcode': barcode,
      'imagePath': imagePath,
      'category': category,
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      price: map['price'],
      cost: map['cost'],
      stock: map['stock'],
      minStock: map['minStock'] ?? 0,
      barcode: map['barcode'],
      imagePath: map['imagePath'],
      category: map['category'],
      isActive: map['isActive'] == 1,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  double get profitMargin => price - cost;
  double get profitMarginPercentage => cost > 0 ? (profitMargin / cost) * 100 : 0;
  bool get isLowStock => stock <= minStock && minStock > 0;
  bool get isOutOfStock => stock <= 0;

  @override
  String toString() {
    return 'Product(id: $id, name: $name, price: $price, stock: $stock)';
  }
}