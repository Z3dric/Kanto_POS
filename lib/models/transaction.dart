class TransactionItem {
  final String productId;
  final String productName;
  final double price;
  final int quantity;
  final double subtotal;

  TransactionItem({
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.subtotal,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'price': price,
      'quantity': quantity,
      'subtotal': subtotal,
    };
  }

  factory TransactionItem.fromMap(Map<String, dynamic> map) {
    return TransactionItem(
      productId: map['productId'],
      productName: map['productName'],
      price: map['price'],
      quantity: map['quantity'],
      subtotal: map['subtotal'],
    );
  }
}

enum PaymentMethod { cash, credit }

enum TransactionStatus { completed, refunded, cancelled, pending }

class Transaction {
  final String id;
  final DateTime timestamp;
  final List<TransactionItem> items;
  final double subtotal;
  final double tax;
  final double discount;
  final double total;
  final PaymentMethod paymentMethod;
  final TransactionStatus status;
  final String? customerId;
  final String? customerName;
  final String? notes;
  final String? receiptNumber;
  final DateTime? refundedAt;
  final String? refundedBy;

  Transaction({
    required this.id,
    required this.timestamp,
    required this.items,
    this.subtotal = 0.0,
    this.tax = 0.0,
    this.discount = 0.0,
    required this.total,
    required this.paymentMethod,
    this.status = TransactionStatus.completed,
    this.customerId,
    this.customerName,
    this.notes,
    this.receiptNumber,
    this.refundedAt,
    this.refundedBy,
  });

  Transaction copyWith({
    String? id,
    DateTime? timestamp,
    List<TransactionItem>? items,
    double? subtotal,
    double? tax,
    double? discount,
    double? total,
    PaymentMethod? paymentMethod,
    TransactionStatus? status,
    String? customerId,
    String? customerName,
    String? notes,
    String? receiptNumber,
    DateTime? refundedAt,
    String? refundedBy,
  }) {
    return Transaction(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      notes: notes ?? this.notes,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      refundedAt: refundedAt ?? this.refundedAt,
      refundedBy: refundedBy ?? this.refundedBy,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'tax': tax,
      'discount': discount,
      'total': total,
      'paymentMethod': paymentMethod.name,
      'status': status.name,
      'customerId': customerId,
      'customerName': customerName,
      'notes': notes,
      'receiptNumber': receiptNumber,
      'refundedAt': refundedAt?.toIso8601String(),
      'refundedBy': refundedBy,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      timestamp: DateTime.parse(map['timestamp']),
      items: List<TransactionItem>.from(
        map['items'].map((item) => TransactionItem.fromMap(item)),
      ),
      subtotal: map['subtotal'],
      tax: map['tax'],
      discount: map['discount'],
      total: map['total'],
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.name == map['paymentMethod'],
        orElse: () => PaymentMethod.cash,
      ),
      status: TransactionStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => TransactionStatus.completed,
      ),
      customerId: map['customerId'],
      customerName: map['customerName'],
      notes: map['notes'],
      receiptNumber: map['receiptNumber'],
      refundedAt: map['refundedAt'] != null 
          ? DateTime.parse(map['refundedAt']) 
          : null,
      refundedBy: map['refundedBy'],
    );
  }

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);
  bool get isCredit => paymentMethod == PaymentMethod.credit;
  bool get isRefunded => status == TransactionStatus.refunded;
  bool get isCancelled => status == TransactionStatus.cancelled;

  @override
  String toString() {
    return 'Transaction(id: $id, timestamp: $timestamp, total: $total, status: $status)';
  }
}