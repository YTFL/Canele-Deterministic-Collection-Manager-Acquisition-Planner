class Series {
  final String id;
  final String title;
  final String type; // lightNovel, manga, comic, book
  final String collectionStatus; // active, wishlist, completed, dropped
  final String releaseStatus; // ongoing, completed
  final int? totalVolumesReleased;
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
      'tags': tags,
      'customMetadata': customMetadata,
    };
  }

  factory Series.fromMap(Map<dynamic, dynamic> map) {
    final rawStatus = map['collectionStatus'] ?? map['status'] ?? 'active';
    return Series(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      type: map['type'] as String? ?? 'lightNovel',
      collectionStatus: rawStatus.toString(),
      releaseStatus: map['releaseStatus'] as String? ?? 'ongoing',
      totalVolumesReleased: map['totalVolumesReleased'] as int?,
      tags: (map['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      customMetadata: Map<String, dynamic>.from(map['customMetadata'] as Map? ?? {}),
    );
  }
}
