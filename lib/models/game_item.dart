import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'series.dart';

enum GameBacklogStatus {
  backlog,
  playing,
  beaten,
  completed,
  dropped,
  wishlist;

  String get label {
    switch (this) {
      case GameBacklogStatus.backlog:
        return 'Backlog';
      case GameBacklogStatus.playing:
        return 'Playing';
      case GameBacklogStatus.beaten:
        return 'Beaten';
      case GameBacklogStatus.completed:
        return 'Completed';
      case GameBacklogStatus.dropped:
        return 'Dropped';
      case GameBacklogStatus.wishlist:
        return 'Wishlist';
    }
  }

  Color get color {
    switch (this) {
      case GameBacklogStatus.backlog:
        return const Color(0xFFD49E58); // Warm honey amber
      case GameBacklogStatus.playing:
        return const Color(0xFF3B82F6); // Electric game blue
      case GameBacklogStatus.beaten:
        return const Color(0xFF10B981); // Emerald victory green
      case GameBacklogStatus.completed:
        return const Color(0xFFF59E0B); // Trophy Gold
      case GameBacklogStatus.dropped:
        return const Color(0xFF9CA3AF); // Slate grey
      case GameBacklogStatus.wishlist:
        return const Color(0xFFF43F5E); // Coral rose
    }
  }

  IconData get icon {
    switch (this) {
      case GameBacklogStatus.backlog:
        return Icons.inventory_2_outlined;
      case GameBacklogStatus.playing:
        return Icons.play_circle_fill_rounded;
      case GameBacklogStatus.beaten:
        return Icons.check_circle_rounded;
      case GameBacklogStatus.completed:
        return Icons.workspace_premium_rounded;
      case GameBacklogStatus.dropped:
        return Icons.pause_circle_outline_rounded;
      case GameBacklogStatus.wishlist:
        return Icons.bookmark_border_rounded;
    }
  }

  GameBacklogStatus cycleNext() {
    switch (this) {
      case GameBacklogStatus.backlog:
        return GameBacklogStatus.playing;
      case GameBacklogStatus.playing:
        return GameBacklogStatus.beaten;
      case GameBacklogStatus.beaten:
        return GameBacklogStatus.completed;
      case GameBacklogStatus.completed:
        return GameBacklogStatus.backlog;
      case GameBacklogStatus.dropped:
        return GameBacklogStatus.backlog;
      case GameBacklogStatus.wishlist:
        return GameBacklogStatus.backlog;
    }
  }

  static GameBacklogStatus fromString(String? val) {
    if (val == null) return GameBacklogStatus.backlog;
    return GameBacklogStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == val.trim().toLowerCase(),
      orElse: () => GameBacklogStatus.backlog,
    );
  }
}

enum GameFormat {
  physical,
  digital;

  String get label => this == GameFormat.physical ? 'Physical' : 'Digital';
  IconData get icon => this == GameFormat.physical ? Icons.album_rounded : Icons.cloud_download_rounded;

  static GameFormat fromString(String? val) {
    if (val?.toLowerCase() == 'digital') return GameFormat.digital;
    return GameFormat.physical;
  }
}

class GamePlatform {
  final String key;
  final String displayName;
  final IconData icon;
  final Color badgeColor;

  const GamePlatform({
    required this.key,
    required this.displayName,
    required this.icon,
    required this.badgeColor,
  });

  static const List<GamePlatform> presets = [
    GamePlatform(
      key: 'ps5',
      displayName: 'PlayStation 5',
      icon: Icons.sports_esports_rounded,
      badgeColor: Color(0xFF003791), // PlayStation Blue
    ),
    GamePlatform(
      key: 'switch',
      displayName: 'Nintendo Switch',
      icon: Icons.videogame_asset_rounded,
      badgeColor: Color(0xFFE60012), // Nintendo Red
    ),
    GamePlatform(
      key: 'pc',
      displayName: 'PC / Steam',
      icon: Icons.laptop_mac_rounded,
      badgeColor: Color(0xFF1B2838), // Steam Dark Blue
    ),
    GamePlatform(
      key: 'xbox',
      displayName: 'Xbox Series X/S',
      icon: Icons.gamepad_rounded,
      badgeColor: Color(0xFF107C10), // Xbox Green
    ),
    GamePlatform(
      key: 'deck',
      displayName: 'Steam Deck',
      icon: Icons.stay_current_landscape_rounded,
      badgeColor: Color(0xFF1A9FFF), // Deck Light Blue
    ),
    GamePlatform(
      key: 'ps4',
      displayName: 'PlayStation 4',
      icon: Icons.sports_esports_outlined,
      badgeColor: Color(0xFF00439C),
    ),
    GamePlatform(
      key: 'retro',
      displayName: 'Retro / Other',
      icon: Icons.videogame_asset_outlined,
      badgeColor: AppColors.caramelizedAmber,
    ),
  ];

  static GamePlatform fromString(String? val) {
    if (val == null || val.trim().isEmpty) return presets.first;
    final lower = val.trim().toLowerCase();
    return presets.firstWhere(
      (p) => p.key.toLowerCase() == lower || p.displayName.toLowerCase().contains(lower),
      orElse: () => GamePlatform(
        key: val.toLowerCase().replaceAll(' ', '_'),
        displayName: val,
        icon: Icons.sports_esports_rounded,
        badgeColor: AppColors.caramelizedAmber,
      ),
    );
  }
}

class GameItem {
  final String id;
  final String title;
  final String platform; // e.g. 'ps5', 'switch', 'pc'
  final String edition; // e.g. 'Standard', 'Deluxe', 'Collector's'
  final GameFormat format;
  final GameBacklogStatus backlogStatus;
  final double? price;
  final String? currency;
  final String? coverUrl;
  final double? rating;
  final double? playtimeHours;
  final String? notes;
  final List<String> tags;
  final DateTime? releaseDate;
  final Map<String, dynamic> customMetadata;

  const GameItem({
    required this.id,
    required this.title,
    this.platform = 'ps5',
    this.edition = 'Standard Edition',
    this.format = GameFormat.physical,
    this.backlogStatus = GameBacklogStatus.backlog,
    this.price,
    this.currency,
    this.coverUrl,
    this.rating,
    this.playtimeHours,
    this.notes,
    this.tags = const [],
    this.releaseDate,
    this.customMetadata = const {},
  });

  GamePlatform get platformInfo => GamePlatform.fromString(platform);

  GameItem copyWith({
    String? id,
    String? title,
    String? platform,
    String? edition,
    GameFormat? format,
    GameBacklogStatus? backlogStatus,
    double? price,
    bool clearPrice = false,
    String? currency,
    bool clearCurrency = false,
    String? coverUrl,
    bool clearCoverUrl = false,
    double? rating,
    bool clearRating = false,
    double? playtimeHours,
    bool clearPlaytimeHours = false,
    String? notes,
    bool clearNotes = false,
    List<String>? tags,
    DateTime? releaseDate,
    bool clearReleaseDate = false,
    Map<String, dynamic>? customMetadata,
  }) {
    return GameItem(
      id: id ?? this.id,
      title: title ?? this.title,
      platform: platform ?? this.platform,
      edition: edition ?? this.edition,
      format: format ?? this.format,
      backlogStatus: backlogStatus ?? this.backlogStatus,
      price: clearPrice ? null : (price ?? this.price),
      currency: clearCurrency ? null : (currency ?? this.currency),
      coverUrl: clearCoverUrl ? null : (coverUrl ?? this.coverUrl),
      rating: clearRating ? null : (rating ?? this.rating),
      playtimeHours: clearPlaytimeHours ? null : (playtimeHours ?? this.playtimeHours),
      notes: clearNotes ? null : (notes ?? this.notes),
      tags: tags ?? this.tags,
      releaseDate: clearReleaseDate ? null : (releaseDate ?? this.releaseDate),
      customMetadata: customMetadata ?? this.customMetadata,
    );
  }

  /// Converts high-level GameItem into Series entity for storage in scoped Hive box
  Series toSeries() {
    final meta = Map<String, dynamic>.from(customMetadata);
    meta['isGame'] = true;
    meta['platform'] = platform;
    meta['edition'] = edition;
    meta['format'] = format.name;
    meta['backlogStatus'] = backlogStatus.name;
    if (coverUrl != null) meta['coverUrl'] = coverUrl;
    if (rating != null) meta['rating'] = rating;
    if (playtimeHours != null) meta['playtimeHours'] = playtimeHours;
    if (notes != null) meta['notes'] = notes;
    if (releaseDate != null) meta['releaseDate'] = releaseDate!.toIso8601String();

    final effectiveCollectionStatus = backlogStatus == GameBacklogStatus.wishlist
        ? 'wishlist'
        : (backlogStatus == GameBacklogStatus.completed || backlogStatus == GameBacklogStatus.beaten
            ? 'completed'
            : (backlogStatus == GameBacklogStatus.dropped ? 'dropped' : 'active'));

    final effectiveTags = Set<String>.from(tags)
      ..add(platform)
      ..add(format.label);

    return Series(
      id: id,
      title: title,
      type: 'game',
      collectionStatus: effectiveCollectionStatus,
      releaseStatus: releaseDate != null && releaseDate!.isAfter(DateTime.now()) ? 'ongoing' : 'completed',
      seriesPrice: price,
      currency: currency,
      tags: effectiveTags.toList(),
      customMetadata: meta,
    );
  }

  /// Constructs GameItem from a Series entity stored in the database
  factory GameItem.fromSeries(Series series) {
    final meta = series.customMetadata;

    final platformStr = meta['platform'] as String? ??
        (series.tags.isNotEmpty ? series.tags.first : 'ps5');
    final editionStr = meta['edition'] as String? ?? 'Standard Edition';
    final formatVal = GameFormat.fromString(meta['format'] as String?);

    GameBacklogStatus status;
    if (meta['backlogStatus'] != null) {
      status = GameBacklogStatus.fromString(meta['backlogStatus'] as String);
    } else if (series.collectionStatus == 'wishlist') {
      status = GameBacklogStatus.wishlist;
    } else if (series.collectionStatus == 'completed') {
      status = GameBacklogStatus.completed;
    } else if (series.collectionStatus == 'dropped') {
      status = GameBacklogStatus.dropped;
    } else {
      status = GameBacklogStatus.backlog;
    }

    DateTime? relDate;
    if (meta['releaseDate'] != null) {
      relDate = DateTime.tryParse(meta['releaseDate'] as String);
    }

    return GameItem(
      id: series.id,
      title: series.title,
      platform: platformStr,
      edition: editionStr,
      format: formatVal,
      backlogStatus: status,
      price: series.seriesPrice,
      currency: series.currency,
      coverUrl: meta['coverUrl'] as String?,
      rating: (meta['rating'] as num?)?.toDouble(),
      playtimeHours: (meta['playtimeHours'] as num?)?.toDouble(),
      notes: meta['notes'] as String?,
      tags: List<String>.from(series.tags),
      releaseDate: relDate,
      customMetadata: meta,
    );
  }
}
