import '../../../core/utils/uuid_generator.dart';

enum GameItemType {
  game,
  dlc,
}

enum GameAvailability {
  available,
  upcoming,
  delisted,
}

class GameItem {
  final String id;
  final String seriesId;
  final String title;
  final GameItemType itemType;
  final double gameNumber; // Chronological sequence number: 1.0, 2.0, 1.5 for DLC
  final bool isOwned;
  final bool isGift;
  final double? price;
  final String? currency;
  final DateTime? releaseDate;
  final GameAvailability availability;
  final bool isPriorityTarget; // High-priority purchase / watchlist target (NOT restock)
  final Map<String, dynamic> customMetadata;

  GameItem({
    required this.id,
    required this.seriesId,
    required this.title,
    this.itemType = GameItemType.game,
    this.gameNumber = 1.0,
    this.isOwned = false,
    this.isGift = false,
    this.price,
    this.currency,
    this.releaseDate,
    this.availability = GameAvailability.available,
    this.isPriorityTarget = false,
    this.customMetadata = const {},
  });

  bool isReleased([DateTime? asOf]) {
    final now = asOf ?? DateTime.now();
    if (availability == GameAvailability.upcoming) return false;
    if (releaseDate == null) return true;
    return releaseDate!.isBefore(now) || releaseDate!.isAtSameMomentAs(now);
  }

  GameItem copyWith({
    String? id,
    String? seriesId,
    String? title,
    GameItemType? itemType,
    double? gameNumber,
    bool? isOwned,
    bool? isGift,
    double? price,
    bool clearPrice = false,
    String? currency,
    bool clearCurrency = false,
    DateTime? releaseDate,
    bool clearReleaseDate = false,
    GameAvailability? availability,
    bool? isPriorityTarget,
    Map<String, dynamic>? customMetadata,
  }) {
    return GameItem(
      id: id ?? this.id,
      seriesId: seriesId ?? this.seriesId,
      title: title ?? this.title,
      itemType: itemType ?? this.itemType,
      gameNumber: gameNumber ?? this.gameNumber,
      isOwned: isOwned ?? this.isOwned,
      isGift: isGift ?? this.isGift,
      price: clearPrice ? null : (price ?? this.price),
      currency: clearCurrency ? null : (currency ?? this.currency),
      releaseDate: clearReleaseDate ? null : (releaseDate ?? this.releaseDate),
      availability: availability ?? this.availability,
      isPriorityTarget: isPriorityTarget ?? this.isPriorityTarget,
      customMetadata: customMetadata ?? this.customMetadata,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'seriesId': seriesId,
      'volumeNumber': gameNumber, // mapped for backward compatibility in volume box
      'gameNumber': gameNumber,
      'title': title,
      'isOwned': isOwned,
      'isGift': isGift,
      'price': price,
      'currency': currency,
      'releaseDate': releaseDate?.toIso8601String(),
      'availability': availability.name,
      'isRestockedWatchlist': isPriorityTarget, // mapped to priority target in legacy box
      'isPriorityTarget': isPriorityTarget,
      'customMetadata': {
        ...customMetadata,
        'title': title,
        'itemType': itemType.name,
        'isGame': true,
        'isPriorityTarget': isPriorityTarget,
      },
    };
  }

  factory GameItem.fromMap(Map<dynamic, dynamic> map) {
    final meta = map['customMetadata'] is Map
        ? Map<String, dynamic>.from(map['customMetadata'] as Map)
        : <String, dynamic>{};

    final rawType = meta['itemType']?.toString() ??
        (map['isDlc'] == true ? 'dlc' : 'game');
    final itemType = rawType == 'dlc' ? GameItemType.dlc : GameItemType.game;

    final rawAvail = map['availability']?.toString();
    GameAvailability avail = GameAvailability.available;
    if (rawAvail == 'upcoming' || rawAvail == 'announced') {
      avail = GameAvailability.upcoming;
    } else if (rawAvail == 'delisted' || rawAvail == 'outOfPrint') {
      avail = GameAvailability.delisted;
    }

    final numVal = (map['gameNumber'] as num?)?.toDouble() ??
        (map['volumeNumber'] as num?)?.toDouble() ??
        1.0;

    final isPriority = map['isPriorityTarget'] == true ||
        meta['isPriorityTarget'] == true ||
        map['isRestockedWatchlist'] == true;

    final resolvedTitle = map['title']?.toString() ??
        meta['title']?.toString() ??
        (itemType == GameItemType.dlc ? 'DLC expansion' : 'Game #$numVal');

    return GameItem(
      id: map['id']?.toString() ?? UuidGenerator.generate(),
      seriesId: map['seriesId']?.toString() ?? '',
      title: resolvedTitle,
      itemType: itemType,
      gameNumber: numVal,
      isOwned: map['isOwned'] == true,
      isGift: map['isGift'] == true || meta['isGift'] == true,
      price: (map['price'] as num?)?.toDouble(),
      currency: map['currency']?.toString(),
      releaseDate: map['releaseDate'] != null
          ? DateTime.tryParse(map['releaseDate'].toString())
          : null,
      availability: avail,
      isPriorityTarget: isPriority,
      customMetadata: meta,
    );
  }
}
