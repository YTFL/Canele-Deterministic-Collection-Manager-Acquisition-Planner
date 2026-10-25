import '../../../core/utils/uuid_generator.dart';

class GameSeries {
  final String id;
  final String title;
  final bool isStandalone;
  final String collectionStatus; // 'active', 'completed', 'wishlist', 'dropped'
  final String releaseStatus; // 'ongoing', 'completed'
  final double? defaultGamePrice;
  final String? defaultCurrency;
  final List<String> tags;
  final DateTime createdAt;
  final Map<String, dynamic> customMetadata;

  GameSeries({
    required this.id,
    required this.title,
    this.isStandalone = false,
    this.collectionStatus = 'active',
    this.releaseStatus = 'ongoing',
    this.defaultGamePrice,
    this.defaultCurrency,
    this.tags = const [],
    DateTime? createdAt,
    this.customMetadata = const {},
  }) : createdAt = createdAt ?? DateTime.now();

  GameSeries copyWith({
    String? id,
    String? title,
    bool? isStandalone,
    String? collectionStatus,
    String? releaseStatus,
    double? defaultGamePrice,
    bool clearDefaultPrice = false,
    String? defaultCurrency,
    bool clearDefaultCurrency = false,
    List<String>? tags,
    DateTime? createdAt,
    Map<String, dynamic>? customMetadata,
  }) {
    return GameSeries(
      id: id ?? this.id,
      title: title ?? this.title,
      isStandalone: isStandalone ?? this.isStandalone,
      collectionStatus: collectionStatus ?? this.collectionStatus,
      releaseStatus: releaseStatus ?? this.releaseStatus,
      defaultGamePrice: clearDefaultPrice ? null : (defaultGamePrice ?? this.defaultGamePrice),
      defaultCurrency: clearDefaultCurrency ? null : (defaultCurrency ?? this.defaultCurrency),
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      customMetadata: customMetadata ?? this.customMetadata,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'type': 'game',
      'isStandalone': isStandalone,
      'collectionStatus': collectionStatus,
      'status': collectionStatus, // for compatibility with legacy readers
      'releaseStatus': releaseStatus,
      'defaultVolumePrice': defaultGamePrice,
      'defaultVolumeCurrency': defaultCurrency,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'customMetadata': {
        ...customMetadata,
        'isGame': true,
        'isStandalone': isStandalone,
      },
    };
  }

  factory GameSeries.fromMap(Map<dynamic, dynamic> map) {
    final meta = map['customMetadata'] is Map
        ? Map<String, dynamic>.from(map['customMetadata'] as Map)
        : <String, dynamic>{};
    final isStandalone = map['isStandalone'] == true || meta['isStandalone'] == true;

    return GameSeries(
      id: map['id']?.toString() ?? UuidGenerator.generate(),
      title: map['title']?.toString() ?? 'Untitled Game',
      isStandalone: isStandalone,
      collectionStatus: map['collectionStatus']?.toString() ??
          map['status']?.toString() ??
          'active',
      releaseStatus: map['releaseStatus']?.toString() ?? 'ongoing',
      defaultGamePrice: (map['defaultVolumePrice'] as num?)?.toDouble() ??
          (map['defaultGamePrice'] as num?)?.toDouble() ??
          (map['seriesPrice'] as num?)?.toDouble(),
      defaultCurrency: map['defaultVolumeCurrency']?.toString() ??
          map['defaultCurrency']?.toString() ??
          map['currency']?.toString(),
      tags: (map['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      customMetadata: meta,
    );
  }
}
