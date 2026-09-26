import 'dart:convert';
import 'series.dart';

/// Represents an item within a dynamically configured Custom Workspace.
class CustomItem {
  final String id;
  final String title;
  final String? groupTitle; // e.g. Artist, Manufacturer, Publisher, Franchise
  final String status; // e.g. 'backlog', 'inProgress', 'completed', 'wishlist'
  final String? coverUrl;
  final double? price;
  final String? currency;
  final DateTime? releaseDate;
  final double? rating;
  final String? edition; // e.g. Limited Edition, 180g Vinyl, First Print
  final String? platform; // e.g. Vinyl, CD, 1/8 Scale, Blu-ray
  final String? notes;
  final List<String> tags;
  final Map<String, dynamic> customFields;

  const CustomItem({
    required this.id,
    required this.title,
    this.groupTitle,
    this.status = 'backlog',
    this.coverUrl,
    this.price,
    this.currency,
    this.releaseDate,
    this.rating,
    this.edition,
    this.platform,
    this.notes,
    this.tags = const [],
    this.customFields = const {},
  });

  CustomItem copyWith({
    String? id,
    String? title,
    String? groupTitle,
    String? status,
    String? coverUrl,
    double? price,
    String? currency,
    DateTime? releaseDate,
    double? rating,
    String? edition,
    String? platform,
    String? notes,
    List<String>? tags,
    Map<String, dynamic>? customFields,
  }) {
    return CustomItem(
      id: id ?? this.id,
      title: title ?? this.title,
      groupTitle: groupTitle ?? this.groupTitle,
      status: status ?? this.status,
      coverUrl: coverUrl ?? this.coverUrl,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      releaseDate: releaseDate ?? this.releaseDate,
      rating: rating ?? this.rating,
      edition: edition ?? this.edition,
      platform: platform ?? this.platform,
      notes: notes ?? this.notes,
      tags: tags ?? List<String>.from(this.tags),
      customFields: customFields ?? Map<String, dynamic>.from(this.customFields),
    );
  }

  /// Converts this CustomItem into a standard Series entity for zero-overhead storage in Hive.
  Series toSeries() {
    final isCompleted = status.toLowerCase() == 'completed' || status.toLowerCase() == 'finished';
    final isWishlist = status.toLowerCase() == 'wishlist';

    final metadata = <String, dynamic>{
      'isCustom': true,
      'status': status,
      if (groupTitle != null) 'groupTitle': groupTitle,
      if (coverUrl != null) 'coverUrl': coverUrl,
      if (price != null) 'price': price,
      if (currency != null) 'currency': currency,
      if (releaseDate != null) 'releaseDate': releaseDate!.toIso8601String(),
      if (rating != null) 'rating': rating,
      if (edition != null) 'edition': edition,
      if (platform != null) 'platform': platform,
      if (notes != null) 'notes': notes,
      if (customFields.isNotEmpty) 'customFields': customFields,
    };

    return Series(
      id: id,
      title: title,
      type: 'custom',
      collectionStatus: isCompleted ? 'completed' : (isWishlist ? 'wishlist' : 'active'),
      releaseStatus: 'completed',
      totalVolumesReleased: 1,
      seriesPrice: price,
      currency: currency,
      tags: tags,
      customMetadata: metadata,
    );
  }

  /// Reconstructs a CustomItem from a stored Series entity.
  factory CustomItem.fromSeries(Series series) {
    final meta = series.customMetadata;

    DateTime? parsedDate;
    final rawDate = meta['releaseDate'];
    if (rawDate is String && rawDate.isNotEmpty) {
      parsedDate = DateTime.tryParse(rawDate);
    }

    final rawPrice = meta['price'] ?? series.seriesPrice;
    final double? priceVal = rawPrice is num ? rawPrice.toDouble() : null;

    final rawRating = meta['rating'];
    final double? ratingVal = rawRating is num ? rawRating.toDouble() : null;

    final rawStatus = meta['status']?.toString();
    final effectiveStatus = rawStatus ??
        (series.collectionStatus == 'completed'
            ? 'completed'
            : (series.collectionStatus == 'wishlist' ? 'wishlist' : 'backlog'));

    Map<String, dynamic> fields = {};
    if (meta['customFields'] is Map) {
      fields = Map<String, dynamic>.from(meta['customFields'] as Map);
    }

    return CustomItem(
      id: series.id,
      title: series.title,
      groupTitle: meta['groupTitle']?.toString(),
      status: effectiveStatus,
      coverUrl: meta['coverUrl']?.toString(),
      price: priceVal,
      currency: meta['currency']?.toString() ?? series.currency,
      releaseDate: parsedDate,
      rating: ratingVal,
      edition: meta['edition']?.toString(),
      platform: meta['platform']?.toString(),
      notes: meta['notes']?.toString(),
      tags: List<String>.from(series.tags),
      customFields: fields,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'groupTitle': groupTitle,
      'status': status,
      'coverUrl': coverUrl,
      'price': price,
      'currency': currency,
      'releaseDate': releaseDate?.toIso8601String(),
      'rating': rating,
      'edition': edition,
      'platform': platform,
      'notes': notes,
      'tags': tags,
      'customFields': customFields,
    };
  }

  factory CustomItem.fromMap(Map<dynamic, dynamic> map) {
    DateTime? parsedDate;
    if (map['releaseDate'] != null) {
      parsedDate = DateTime.tryParse(map['releaseDate'].toString());
    }

    return CustomItem(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      groupTitle: map['groupTitle']?.toString(),
      status: map['status']?.toString() ?? 'backlog',
      coverUrl: map['coverUrl']?.toString(),
      price: (map['price'] is num) ? (map['price'] as num).toDouble() : null,
      currency: map['currency']?.toString(),
      releaseDate: parsedDate,
      rating: (map['rating'] is num) ? (map['rating'] as num).toDouble() : null,
      edition: map['edition']?.toString(),
      platform: map['platform']?.toString(),
      notes: map['notes']?.toString(),
      tags: map['tags'] != null ? List<String>.from(map['tags'] as List) : const [],
      customFields: map['customFields'] != null
          ? Map<String, dynamic>.from(map['customFields'] as Map)
          : const {},
    );
  }

  String toJson() => jsonEncode(toMap());
  factory CustomItem.fromJson(String source) => CustomItem.fromMap(jsonDecode(source));
}
