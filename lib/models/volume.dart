class Volume {
  final String id;
  final String seriesId;
  final double volumeNumber;
  final DateTime? releaseDate;
  final bool isOwned;
  final bool isGift;
  final String availability; // available, outOfStock, outOfPrint, announced
  final bool isRestockedWatchlist;
  final double? price;
  final String? currency;
  final Map<String, dynamic> customMetadata;

  const Volume({
    required this.id,
    required this.seriesId,
    required this.volumeNumber,
    this.releaseDate,
    this.isOwned = false,
    this.isGift = false,
    this.availability = 'available',
    this.isRestockedWatchlist = false,
    this.price,
    this.currency,
    this.customMetadata = const {},
  });

  bool isReleased([DateTime? asOfDate]) {
    if (availability == 'announced') return false;
    if (releaseDate == null) return true;
    final now = asOfDate ?? DateTime.now();
    return releaseDate!.isBefore(now) || releaseDate!.isAtSameMomentAs(now);
  }

  bool isUpcoming([DateTime? asOfDate]) {
    if (availability == 'announced') return true;
    if (releaseDate == null) return false;
    final now = asOfDate ?? DateTime.now();
    return releaseDate!.isAfter(now);
  }

  Volume copyWith({
    String? id,
    String? seriesId,
    double? volumeNumber,
    DateTime? releaseDate,
    bool clearReleaseDate = false,
    bool? isOwned,
    bool? isGift,
    String? availability,
    bool? isRestockedWatchlist,
    double? price,
    bool clearPrice = false,
    String? currency,
    bool clearCurrency = false,
    Map<String, dynamic>? customMetadata,
  }) {
    return Volume(
      id: id ?? this.id,
      seriesId: seriesId ?? this.seriesId,
      volumeNumber: volumeNumber ?? this.volumeNumber,
      releaseDate: clearReleaseDate ? null : (releaseDate ?? this.releaseDate),
      isOwned: isOwned ?? this.isOwned,
      isGift: isGift ?? this.isGift,
      availability: availability ?? this.availability,
      isRestockedWatchlist: isRestockedWatchlist ?? this.isRestockedWatchlist,
      price: clearPrice ? null : (price ?? this.price),
      currency: clearCurrency ? null : (currency ?? this.currency),
      customMetadata: customMetadata ?? this.customMetadata,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'seriesId': seriesId,
      'volumeNumber': volumeNumber,
      'releaseDate': releaseDate?.toIso8601String(),
      'isOwned': isOwned,
      'isGift': isGift,
      'availability': availability,
      'isRestockedWatchlist': isRestockedWatchlist,
      'price': price,
      'currency': currency,
      'customMetadata': customMetadata,
    };
  }

  factory Volume.fromMap(Map<dynamic, dynamic> map) {
    DateTime? parsedDate;
    if (map['releaseDate'] is String && (map['releaseDate'] as String).isNotEmpty) {
      parsedDate = DateTime.tryParse(map['releaseDate'] as String);
    }

    final rawVolNum = map['volumeNumber'];
    final double volNum = (rawVolNum is num) ? rawVolNum.toDouble() : 1.0;

    final rawPrice = map['price'];
    final double? parsedPrice = (rawPrice is num) ? rawPrice.toDouble() : null;

    final rawCurrency = map['currency'];
    final String? parsedCurrency = (rawCurrency is String && rawCurrency.isNotEmpty)
        ? rawCurrency.toUpperCase().trim()
        : null;

    return Volume(
      id: map['id'] as String? ?? '',
      seriesId: map['seriesId'] as String? ?? '',
      volumeNumber: volNum,
      releaseDate: parsedDate,
      isOwned: map['isOwned'] as bool? ?? false,
      isGift: map['isGift'] as bool? ?? false,
      availability: map['availability'] as String? ?? 'available',
      isRestockedWatchlist: map['isRestockedWatchlist'] as bool? ?? false,
      price: parsedPrice,
      currency: parsedCurrency,
      customMetadata: Map<String, dynamic>.from(map['customMetadata'] as Map? ?? {}),
    );
  }
}
