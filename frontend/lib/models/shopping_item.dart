/// ShoppingItem model
class ShoppingItem {
  String? id;
  String name;
  int quantity;
  String category; // groceries, household, personal, other
  bool isPurchased;
  double? estimatedPrice;
  double? actualPrice;
  DateTime createdDate;
  DateTime? purchasedDate;
  String? notes;
  String? addedBy;

  ShoppingItem({
    this.id,
    required this.name,
    this.quantity = 1,
    this.category = 'other',
    this.isPurchased = false,
    this.estimatedPrice,
    this.actualPrice,
    required this.createdDate,
    this.purchasedDate,
    this.notes,
    this.addedBy,
  });

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'name': name,
      'quantity': quantity,
      'category': category,
      'isPurchased': isPurchased,
      if (estimatedPrice != null) 'estimatedPrice': estimatedPrice,
      if (actualPrice != null) 'actualPrice': actualPrice,
      'createdDate': createdDate.toIso8601String(),
      if (purchasedDate != null)
        'purchasedDate': purchasedDate!.toIso8601String(),
      if (notes != null) 'notes': notes,
      if (addedBy != null) 'addedBy': addedBy,
    };
  }

  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    return ShoppingItem(
      id: json['_id'] ?? json['id'],
      name: json['name'] ?? '',
      quantity: json['quantity'] ?? 1,
      category: json['category'] ?? 'other',
      isPurchased: json['isPurchased'] ?? false,
      estimatedPrice: json['estimatedPrice']?.toDouble(),
      actualPrice: json['actualPrice']?.toDouble(),
      createdDate: json['createdDate'] != null
          ? DateTime.parse(json['createdDate'])
          : DateTime.now(),
      purchasedDate: json['purchasedDate'] != null
          ? DateTime.parse(json['purchasedDate'])
          : null,
      notes: json['notes'],
      addedBy: json['addedBy'],
    );
  }

  ShoppingItem copyWith({
    String? id,
    String? name,
    int? quantity,
    String? category,
    bool? isPurchased,
    double? estimatedPrice,
    double? actualPrice,
    DateTime? createdDate,
    DateTime? purchasedDate,
    String? notes,
    String? addedBy,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      category: category ?? this.category,
      isPurchased: isPurchased ?? this.isPurchased,
      estimatedPrice: estimatedPrice ?? this.estimatedPrice,
      actualPrice: actualPrice ?? this.actualPrice,
      createdDate: createdDate ?? this.createdDate,
      purchasedDate: purchasedDate ?? this.purchasedDate,
      notes: notes ?? this.notes,
      addedBy: addedBy ?? this.addedBy,
    );
  }
}
