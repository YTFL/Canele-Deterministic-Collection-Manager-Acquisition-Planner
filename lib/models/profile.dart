import 'dart:convert';

enum ProfileType {
  books,
  games,
  custom,
}

extension ProfileTypeExtension on ProfileType {
  String get displayName {
    switch (this) {
      case ProfileType.books:
        return 'Books & Manga';
      case ProfileType.games:
        return 'Games';
      case ProfileType.custom:
        return 'Custom';
    }
  }
}

class CustomWorkspaceSchema {
  final String itemLabel; // e.g. "Game", "Vinyl", "Book"
  final String groupLabel; // e.g. "Franchise", "Artist", "Series"
  final Map<String, bool> enabledFields;
  final List<String> customStatuses;

  const CustomWorkspaceSchema({
    this.itemLabel = 'Item',
    this.groupLabel = 'Group',
    this.enabledFields = const {
      'coverUrl': true,
      'platform': false,
      'edition': false,
      'rating': false,
      'price': true,
      'releaseDate': true,
    },
    this.customStatuses = const ['backlog', 'inProgress', 'completed'],
  });

  CustomWorkspaceSchema copyWith({
    String? itemLabel,
    String? groupLabel,
    Map<String, bool>? enabledFields,
    List<String>? customStatuses,
  }) {
    return CustomWorkspaceSchema(
      itemLabel: itemLabel ?? this.itemLabel,
      groupLabel: groupLabel ?? this.groupLabel,
      enabledFields: enabledFields ?? Map<String, bool>.from(this.enabledFields),
      customStatuses: customStatuses ?? List<String>.from(this.customStatuses),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'itemLabel': itemLabel,
      'groupLabel': groupLabel,
      'enabledFields': enabledFields,
      'customStatuses': customStatuses,
    };
  }

  factory CustomWorkspaceSchema.fromMap(Map<dynamic, dynamic> map) {
    return CustomWorkspaceSchema(
      itemLabel: map['itemLabel']?.toString() ?? 'Item',
      groupLabel: map['groupLabel']?.toString() ?? 'Group',
      enabledFields: map['enabledFields'] != null
          ? Map<String, bool>.from(
              (map['enabledFields'] as Map).map(
                (k, v) => MapEntry(k.toString(), v == true),
              ),
            )
          : const {
              'coverUrl': true,
              'platform': false,
              'edition': false,
              'rating': false,
              'price': true,
              'releaseDate': true,
            },
      customStatuses: map['customStatuses'] != null
          ? (map['customStatuses'] as List).map((e) => e.toString()).toList()
          : const ['backlog', 'inProgress', 'completed'],
    );
  }
}

class Profile {
  final String id;
  final String name;
  final ProfileType type;
  final String icon;
  final DateTime createdAt;
  final CustomWorkspaceSchema? customSchema;

  const Profile({
    required this.id,
    required this.name,
    required this.type,
    this.icon = 'book',
    required this.createdAt,
    this.customSchema,
  });

  bool get isDefault => id == 'profile_default_books';

  Profile copyWith({
    String? id,
    String? name,
    ProfileType? type,
    String? icon,
    DateTime? createdAt,
    CustomWorkspaceSchema? customSchema,
    bool clearCustomSchema = false,
  }) {
    return Profile(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
      customSchema: clearCustomSchema ? null : (customSchema ?? this.customSchema),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'icon': icon,
      'createdAt': createdAt.toIso8601String(),
      if (customSchema != null) 'customSchema': customSchema!.toMap(),
    };
  }

  factory Profile.fromMap(Map<dynamic, dynamic> map) {
    ProfileType parsedType = ProfileType.books;
    final rawType = map['type']?.toString();
    if (rawType != null) {
      for (final t in ProfileType.values) {
        if (t.name.toLowerCase() == rawType.toLowerCase()) {
          parsedType = t;
          break;
        }
      }
    }

    DateTime parsedDate;
    if (map['createdAt'] != null) {
      parsedDate = DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    CustomWorkspaceSchema? parsedSchema;
    if (map['customSchema'] is Map) {
      parsedSchema = CustomWorkspaceSchema.fromMap(map['customSchema'] as Map);
    }

    return Profile(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Unnamed Workspace',
      type: parsedType,
      icon: map['icon']?.toString() ?? (parsedType == ProfileType.games ? 'gamepad' : 'book'),
      createdAt: parsedDate,
      customSchema: parsedSchema,
    );
  }

  String toJson() => jsonEncode(toMap());
  factory Profile.fromJson(String source) => Profile.fromMap(jsonDecode(source));

  @override
  String toString() => 'Profile(id: $id, name: $name, type: ${type.name}, icon: $icon)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Profile &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
