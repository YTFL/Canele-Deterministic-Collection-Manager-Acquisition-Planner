import 'package:flutter/foundation.dart';
import '../../core/utils/type_helper.dart';
import 'hive_boxes.dart';

class DatabaseMigrator {
  static const int currentSchemaVersion = 2;
  static const String _schemaVersionKey = 'app_database_schema_version';

  /// Runs all pending database migrations upon app launch / installation.
  static Future<void> runMigrations() async {
    try {
      final configBox = HiveBoxes.ruleConfigBox;
      final dynamic rawVersion = configBox.get(_schemaVersionKey);
      int installedVersion = 1;
      if (rawVersion is Map && rawVersion['version'] is num) {
        installedVersion = (rawVersion['version'] as num).toInt();
      }

      if (installedVersion >= currentSchemaVersion) {
        debugPrint('[DatabaseMigrator] Database is up to date (Version $installedVersion).');
        return;
      }

      debugPrint('[DatabaseMigrator] Migrating database from v$installedVersion to v$currentSchemaVersion...');

      // 1. Migrate Series Box
      await _migrateSeriesBox();

      // 2. Migrate Volumes Box
      await _migrateVolumesBox();

      // 3. Migrate Transactions Box
      await _migrateTransactionsBox();

      // 4. Migrate Rules Box
      await _migrateRulesBox();

      // 5. Migrate Rule Config Box
      await _migrateRuleConfigBox();

      // 6. Update Schema Version Key
      await configBox.put(_schemaVersionKey, {
        'version': currentSchemaVersion,
        'migratedAt': DateTime.now().toIso8601String(),
      });

      debugPrint('[DatabaseMigrator] Successfully completed database migration to v$currentSchemaVersion.');
    } catch (e, stack) {
      debugPrint('[DatabaseMigrator] Error during database migration: $e\n$stack');
    }
  }

  static Future<void> _migrateSeriesBox() async {
    final seriesBox = HiveBoxes.seriesBox;
    final keys = List.from(seriesBox.keys);

    for (final key in keys) {
      final raw = seriesBox.get(key);
      if (raw is Map) {
        final map = Map<String, dynamic>.from(raw);
        bool modified = false;

        // Clean obsolete tags
        if (map.containsKey('tags')) {
          map['tags'] = <String>[];
          modified = true;
        }

        // Normalize series type
        if (map['type'] is String) {
          final oldType = map['type'] as String;
          final normalized = TypeHelper.normalizeKey(oldType);
          if (oldType != normalized) {
            map['type'] = normalized;
            modified = true;
          }
        }

        // Normalize releaseStatus ('ongoing' or 'completed')
        if (map['releaseStatus'] is String) {
          final rel = (map['releaseStatus'] as String).toLowerCase();
          if (rel.contains('complete')) {
            map['releaseStatus'] = 'completed';
          } else {
            map['releaseStatus'] = 'ongoing';
          }
          modified = true;
        }

        if (modified) {
          await seriesBox.put(key, map);
        }
      }
    }
  }

  static Future<void> _migrateVolumesBox() async {
    final volumesBox = HiveBoxes.volumesBox;
    final keys = List.from(volumesBox.keys);

    for (final key in keys) {
      final raw = volumesBox.get(key);
      if (raw is Map) {
        final map = Map<String, dynamic>.from(raw);
        bool modified = false;

        // Clean volumeNumber
        final rawVolNum = map['volumeNumber'];
        if (rawVolNum is String) {
          map['volumeNumber'] = double.tryParse(rawVolNum) ?? 1.0;
          modified = true;
        }

        // If volume is already owned or available without explicit future date,
        // we keep releaseDate clean/nullable or preserved.
        final availability = map['availability']?.toString() ?? 'available';
        if (availability != 'announced') {
          // If releaseDate was set to generic current timestamp or empty, allow it
          if (map['releaseDate'] == null || map['releaseDate'] == '') {
            map['releaseDate'] = null;
            modified = true;
          }
        }

        if (modified) {
          await volumesBox.put(key, map);
        }
      }
    }
  }

  static Future<void> _migrateTransactionsBox() async {
    final txBox = HiveBoxes.transactionsBox;
    final keys = List.from(txBox.keys);

    for (final key in keys) {
      final raw = txBox.get(key);
      if (raw is Map) {
        final map = Map<String, dynamic>.from(raw);
        bool modified = false;

        // Ensure price is double or 0.0
        final rawPrice = map['price'];
        if (rawPrice != null && rawPrice is! double && rawPrice is num) {
          map['price'] = rawPrice.toDouble();
          modified = true;
        }

        // Ensure quotaBucket is valid and lowercased
        final bucket = map['quotaBucket']?.toString().toLowerCase();
        if (bucket != 'regular' && bucket != 'bonus' && bucket != 'gift') {
          map['quotaBucket'] = 'regular';
          modified = true;
        } else if (map['quotaBucket'] != bucket) {
          map['quotaBucket'] = bucket;
          modified = true;
        }

        if (modified) {
          await txBox.put(key, map);
        }
      }
    }
  }

  static Future<void> _migrateRulesBox() async {
    final rulesBox = HiveBoxes.rulesBox;
    final keys = List.from(rulesBox.keys);

    for (final key in keys) {
      final raw = rulesBox.get(key);
      if (raw is Map) {
        final map = Map<String, dynamic>.from(raw);
        bool modified = false;

        // Migrate deprecated tagBased scope to allSeries
        if (map['scopeType'] == 'tagBased' || map['scopeType'] == 2) {
          map['scopeType'] = 'allSeries';
          map['targetTags'] = <String>[];
          modified = true;
        }

        // Normalize format type if present
        if (map['targetFormat'] is String && (map['targetFormat'] as String).isNotEmpty) {
          final oldFmt = map['targetFormat'] as String;
          final normFmt = TypeHelper.normalizeKey(oldFmt);
          if (oldFmt != normFmt) {
            map['targetFormat'] = normFmt;
            modified = true;
          }
        }

        if (modified) {
          await rulesBox.put(key, map);
        }
      }
    }
  }

  static Future<void> _migrateRuleConfigBox() async {
    final configBox = HiveBoxes.ruleConfigBox;
    final raw = configBox.get('global_config');
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      if (!map.containsKey('currency') || map['currency'] == null) {
        map['currency'] = 'USD';
        await configBox.put('global_config', map);
      }
    }
  }
}
