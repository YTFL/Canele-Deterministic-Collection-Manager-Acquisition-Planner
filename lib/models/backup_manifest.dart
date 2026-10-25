import 'dart:convert';
import 'profile.dart';

/// Metadata entry representing a single space inside a Canelé multi-space backup directory.
class SpaceBackupEntry {
  final String profileId;
  final String name;
  final ProfileType type;
  final String folderName;
  final String backupFileName;
  final int itemCount;
  final int transactionCount;
  final DateTime? lastBackupTime;

  const SpaceBackupEntry({
    required this.profileId,
    required this.name,
    required this.type,
    required this.folderName,
    this.backupFileName = 'canele_backup.json',
    this.itemCount = 0,
    this.transactionCount = 0,
    this.lastBackupTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'profileId': profileId,
      'name': name,
      'type': type.name,
      'folderName': folderName,
      'backupFileName': backupFileName,
      'itemCount': itemCount,
      'transactionCount': transactionCount,
      if (lastBackupTime != null) 'lastBackupTime': lastBackupTime!.toUtc().toIso8601String(),
    };
  }

  factory SpaceBackupEntry.fromMap(Map<dynamic, dynamic> map) {
    ProfileType parsedType = ProfileType.books;
    final typeStr = map['type']?.toString();
    if (typeStr != null) {
      parsedType = ProfileType.values.firstWhere(
        (t) => t.name == typeStr,
        orElse: () => ProfileType.books,
      );
    }

    DateTime? parsedTime;
    final timeStr = map['lastBackupTime']?.toString();
    if (timeStr != null && timeStr.isNotEmpty) {
      parsedTime = DateTime.tryParse(timeStr)?.toLocal();
    }

    return SpaceBackupEntry(
      profileId: map['profileId']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Workspace',
      type: parsedType,
      folderName: map['folderName']?.toString() ?? '',
      backupFileName: map['backupFileName']?.toString() ?? 'canele_backup.json',
      itemCount: (map['itemCount'] as num?)?.toInt() ?? 0,
      transactionCount: (map['transactionCount'] as num?)?.toInt() ?? 0,
      lastBackupTime: parsedTime,
    );
  }
}

/// Root manifest for a Canelé backup directory indexing all user spaces.
class BackupManifest {
  final String version;
  final DateTime exportedAt;
  final String schemaVersion;
  final List<SpaceBackupEntry> spaces;

  const BackupManifest({
    this.version = '2.1.0',
    required this.exportedAt,
    this.schemaVersion = '2',
    required this.spaces,
  });

  Map<String, dynamic> toMap() {
    return {
      'version': version,
      'schemaVersion': schemaVersion,
      'exportedAt': exportedAt.toUtc().toIso8601String(),
      'spaces': spaces.map((s) => s.toMap()).toList(),
    };
  }

  factory BackupManifest.fromMap(Map<dynamic, dynamic> map) {
    final spacesList = <SpaceBackupEntry>[];
    if (map['spaces'] is List) {
      for (final item in map['spaces'] as List) {
        if (item is Map) {
          spacesList.add(SpaceBackupEntry.fromMap(item));
        }
      }
    }

    DateTime parsedDate = DateTime.now();
    final dateStr = map['exportedAt']?.toString();
    if (dateStr != null && dateStr.isNotEmpty) {
      parsedDate = DateTime.tryParse(dateStr)?.toLocal() ?? DateTime.now();
    }

    return BackupManifest(
      version: map['version']?.toString() ?? '2.1.0',
      schemaVersion: map['schemaVersion']?.toString() ?? '2',
      exportedAt: parsedDate,
      spaces: spacesList,
    );
  }

  String toJson({bool indent = true}) {
    final encoder = indent ? const JsonEncoder.withIndent('  ') : const JsonEncoder();
    return encoder.convert(toMap());
  }

  factory BackupManifest.fromJson(String jsonStr) {
    final decoded = jsonDecode(jsonStr);
    if (decoded is! Map) {
      throw FormatException('Invalid manifest JSON: Root is not an object');
    }
    return BackupManifest.fromMap(decoded);
  }
}
