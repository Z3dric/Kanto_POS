class Customer {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final double creditLimit;
  final double currentBalance;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? notes;
  final bool isActive;

  Customer({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.creditLimit = 0.0,
    this.currentBalance = 0.0,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
    this.isActive = true,
  });

  Customer copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? address,
    double? creditLimit,
    double? currentBalance,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? notes,
    bool? isActive,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      creditLimit: creditLimit ?? this.creditLimit,
      currentBalance: currentBalance ?? this.currentBalance,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'creditLimit': creditLimit,
      'currentBalance': currentBalance,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'notes': notes,
      'isActive': isActive ? 1 : 0,
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      email: map['email'],
      address: map['address'],
      creditLimit: map['creditLimit'] ?? 0.0,
      currentBalance: map['currentBalance'] ?? 0.0,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      notes: map['notes'],
      isActive: map['isActive'] == 1,
    );
  }

  double get availableCredit => creditLimit - currentBalance;
  bool get hasCredit => creditLimit > 0;
  bool get isOverCreditLimit => currentBalance > creditLimit;
  bool get hasOutstandingBalance => currentBalance > 0;
  double get creditUtilization => creditLimit > 0 ? (currentBalance / creditLimit) * 100 : 0;

  @override
  String toString() {
    return 'Customer(id: $id, name: $name, currentBalance: $currentBalance)';
  }
}

class CreditPayment {
  final String id;
  final String customerId;
  final double amount;
  final DateTime timestamp;
  final String? notes;
  final String? transactionId;

  CreditPayment({
    required this.id,
    required this.customerId,
    required this.amount,
    required this.timestamp,
    this.notes,
    this.transactionId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'amount': amount,
      'timestamp': timestamp.toIso8601String(),
      'notes': notes,
      'transactionId': transactionId,
    };
  }

  factory CreditPayment.fromMap(Map<String, dynamic> map) {
    return CreditPayment(
      id: map['id'],
      customerId: map['customerId'],
      amount: map['amount'],
      timestamp: DateTime.parse(map['timestamp']),
      notes: map['notes'],
      transactionId: map['transactionId'],
    );
  }
}
