import '../core/utils/currency_helper.dart';

class Series {
  final String id;
  final String title;
  final String type; // lightNovel, manga, comic, book
  final String collectionStatus; // active, wishlist, completed, dropped
  final String releaseStatus; // ongoing, completed
  final int? totalVolumesReleased;
  final double? seriesPrice; // Optional combined price for the entire series/bundle
  final String? currency; // Currency code for seriesPrice (CAD, USD, INR, JPY)
  final double? defaultVolumePrice; // Optional default price per volume in this series
  final String? defaultVolumeCurrency; // Currency code for defaultVolumePrice
  final List<String> tags;
  final Map<String, dynamic> customMetadata;

  const Series({
    required this.id,
    required this.title,
    required this.type,
    String? collectionStatus,
    String? status,
    this.releaseStatus = 'ongoing',
    this.totalVolumesReleased,
    this.seriesPrice,
    this.currency,
    this.defaultVolumePrice = CurrencyHelper.defaultVolumePrice,
    this.defaultVolumeCurrency = CurrencyHelper.defaultVolumeCurrency,
    this.tags = const [],
    this.customMetadata = const {},
  }) : collectionStatus = collectionStatus ?? status ?? 'active';

  // Backward compatibility alias for status
  String get status => collectionStatus;

  Series copyWith({
    String? id,
    String? title,
    String? type,
    String? collectionStatus,
    String? status,
    String? releaseStatus,
    int? totalVolumesReleased,
    double? seriesPrice,
    bool clearSeriesPrice = false,
    String? currency,
    bool clearCurrency = false,
    double? defaultVolumePrice,
    bool clearDefaultVolumePrice = false,
    String? defaultVolumeCurrency,
    bool clearDefaultVolumeCurrency = false,
    List<String>? tags,
    Map<String, dynamic>? customMetadata,
  }) {
    return Series(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      collectionStatus: collectionStatus ?? status ?? this.collectionStatus,
      releaseStatus: releaseStatus ?? this.releaseStatus,
      totalVolumesReleased: totalVolumesReleased ?? this.totalVolumesReleased,
      seriesPrice: clearSeriesPrice ? null : (seriesPrice ?? this.seriesPrice),
      currency: clearCurrency ? null : (currency ?? this.currency),
      defaultVolumePrice: clearDefaultVolumePrice ? null : (defaultVolumePrice ?? this.defaultVolumePrice),
      defaultVolumeCurrency: clearDefaultVolumeCurrency ? null : (defaultVolumeCurrency ?? this.defaultVolumeCurrency),
      tags: tags ?? this.tags,
      customMetadata: customMetadata ?? this.customMetadata,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'status': collectionStatus,
      'collectionStatus': collectionStatus,
      'releaseStatus': releaseStatus,
      'totalVolumesReleased': totalVolumesReleased,
      'seriesPrice': seriesPrice,
      'currency': currency,
      'defaultVolumePrice': defaultVolumePrice,
      'defaultVolumeCurrency': defaultVolumeCurrency,
      'tags': tags,
      'customMetadata': customMetadata,
    };
  }

  factory Series.fromMap(Map<dynamic, dynamic> map) {
    final rawStatus = map['collectionStatus'] ?? map['status'] ?? 'active';
    return Series(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      type: map['type']?.toString() ?? '',
      collectionStatus: rawStatus.toString(),
      releaseStatus: map['releaseStatus'] as String? ?? 'ongoing',
      totalVolumesReleased: map['totalVolumesReleased'] as int?,
      seriesPrice: (map['seriesPrice'] as num?)?.toDouble(),
      currency: map['currency']?.toString(),
      defaultVolumePrice: (map['defaultVolumePrice'] as num?)?.toDouble() ?? CurrencyHelper.defaultVolumePrice,
      defaultVolumeCurrency: map['defaultVolumeCurrency']?.toString() ?? CurrencyHelper.defaultVolumeCurrency,
      tags: (map['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      customMetadata: Map<String, dynamic>.from(map['customMetadata'] as Map? ?? {}),
    );
  }
}
