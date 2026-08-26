class PurchaseTransaction {
  final String id;
  final String volumeId;
  final DateTime purchaseDate;
  final String quotaBucket; // regular, bonus, gift
  final double price;
  final String notes;

  const PurchaseTransaction({
    required this.id,
    required this.volumeId,
    required this.purchaseDate,
    required this.quotaBucket,
    this.price = 0.0,
    this.notes = '',
  });

  PurchaseTransaction copyWith({
    String? id,
    String? volumeId,
    DateTime? purchaseDate,
    String? quotaBucket,
    double? price,
    String? notes,
  }) {
    return PurchaseTransaction(
      id: id ?? this.id,
      volumeId: volumeId ?? this.volumeId,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      quotaBucket: quotaBucket ?? this.quotaBucket,
      price: price ?? this.price,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'volumeId': volumeId,
      'purchaseDate': purchaseDate.toIso8601String(),
      'quotaBucket': quotaBucket,
      'price': price,
      'notes': notes,
    };
  }

  factory PurchaseTransaction.fromMap(Map<dynamic, dynamic> map) {
    DateTime parsedDate;
    if (map['purchaseDate'] is String) {
      parsedDate = DateTime.tryParse(map['purchaseDate'] as String) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    final rawPrice = map['price'];
    final double priceVal = (rawPrice is num) ? rawPrice.toDouble() : 0.0;

    return PurchaseTransaction(
      id: map['id'] as String? ?? '',
      volumeId: map['volumeId'] as String? ?? '',
      purchaseDate: parsedDate,
      quotaBucket: map['quotaBucket'] as String? ?? 'regular',
      price: priceVal,
      notes: map['notes'] as String? ?? '',
    );
  }
}
