import 'dart:convert';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import '../core/database/database_migrator.dart';
import '../core/database/hive_boxes.dart';
import '../models/import_item.dart';
import '../models/series.dart';
import '../models/volume.dart';
import '../models/purchase_transaction.dart';
import '../models/rule_config.dart';
import '../models/rule_model.dart';
import 'backup_service.dart';

enum RestoreMode {
  replaceAll,
  mergeAndKeepNewest,
}

class RestoreResult {
  final bool success;
  final int seriesCount;
  final int volumesCount;
  final int transactionsCount;
  final int rulesCount;
  final String? errorMessage;

  const RestoreResult({
    required this.success,
    this.seriesCount = 0,
    this.volumesCount = 0,
    this.transactionsCount = 0,
    this.rulesCount = 0,
    this.errorMessage,
  });
}

class ParsedTitleVolume {
  final String seriesTitle;
  final double volumeNumber;

  ParsedTitleVolume({required this.seriesTitle, required this.volumeNumber});
}

class UniversalImporter {
  /// Smart Regex to extract series title and decimal volume number
  /// e.g. "86 - Eighty-Six, Vol. 11.5" -> series: "86 - Eighty-Six", volume: 11.5
  /// e.g. "Frieren, Volume 10 (Light Novel)" -> series: "Frieren", volume: 10.0
  static ParsedTitleVolume parseTitleAndVolume(String rawTitle) {
    String clean = rawTitle.trim();

    // 1. Remove trailing format tags in parentheses e.g. (Light Novel), (Manga), (Paperback)
    clean = clean.replaceAll(
      RegExp(
        r'\s*\((?:Light Novel|Manga|Comic|Novel|Paperback|Hardcover|Kindle Edition|ebook)\)',
        caseSensitive: false,
      ),
      '',
    );

    // 2. Remove Goodreads series trailing info e.g. (Frieren, #10)
    clean = clean.replaceAll(
      RegExp(r'\s*\([^)]*#\d+(?:\.\d+)?[^)]*\)', caseSensitive: false),
      '',
    );

    // 3. Match Volume pattern: ", Vol. 11.5", " - Volume 10", " Vol 3", " #4", " v2.5", "Book 4"
    final volRegex = RegExp(
      r'^(.*?)(?:,\s*|\s+-\s*|\s+)(?:Vol(?:ume|\.)?|Book|v|Chapter|Ch\.)\s*(\d+(?:\.\d+)?)(.*)$',
      caseSensitive: false,
    );

    final match = volRegex.firstMatch(clean);
    if (match != null) {
      final sTitle = match.group(1)!.trim();
      final volStr = match.group(2)!;
      final volNum = double.tryParse(volStr) ?? 1.0;
      if (sTitle.isNotEmpty) {
        return ParsedTitleVolume(
          seriesTitle: sTitle,
          volumeNumber: volNum,
        );
      }
    }

    // 4. Match hash pattern e.g. "Series Name #12"
    final hashRegex = RegExp(r'^(.*?)\s+#(\d+(?:\.\d+)?)$');
    final hashMatch = hashRegex.firstMatch(clean);
    if (hashMatch != null) {
      final sTitle = hashMatch.group(1)!.trim();
      final volNum = double.tryParse(hashMatch.group(2)!) ?? 1.0;
      if (sTitle.isNotEmpty) {
        return ParsedTitleVolume(
          seriesTitle: sTitle,
          volumeNumber: volNum,
        );
      }
    }

    // 5. Default fallback (Single standalone book or unnumbered)
    return ParsedTitleVolume(
      seriesTitle: clean,
      volumeNumber: 1.0,
    );
  }

  /// Lossless JSON Restore Engine supporting Replace All and Merge & Keep Newest
  static Future<RestoreResult> restoreFromJson(
    String jsonString, {
    RestoreMode mode = RestoreMode.replaceAll,
  }) async {
    // Pause BackupService mutation listener during restore to avoid corrupted intermediate writes
    BackupService.instance.pauseListening();

    try {
      final dynamic decoded = jsonDecode(jsonString);
      if (decoded is! Map<String, dynamic> && decoded is! Map) {
        return const RestoreResult(
          success: false,
          errorMessage: 'Invalid JSON backup: Root is not an object.',
        );
      }

      final data = Map<String, dynamic>.from(decoded as Map);

      if (mode == RestoreMode.replaceAll) {
        return await _restoreReplaceAll(data);
      } else {
        return await _restoreMergeAndKeepNewest(data);
      }
    } catch (e) {
      return RestoreResult(
        success: false,
        errorMessage: 'JSON restore failed: $e',
      );
    } finally {
      // Resume BackupService listener after restore completes
      BackupService.instance.resumeListening();
    }
  }

  static Future<RestoreResult> _restoreReplaceAll(Map<String, dynamic> data) async {
    await HiveBoxes.clearAll();

    int seriesCount = 0;
    int volumesCount = 0;
    int txCount = 0;
    int rulesCount = 0;

    // Series
    if (data.containsKey('series') && data['series'] is List) {
      for (final item in data['series'] as List) {
        if (item is Map) {
          final s = Series.fromMap(item);
          await HiveBoxes.seriesBox.put(s.id, s.toMap());
          seriesCount++;
        }
      }
    }

    // Volumes
    if (data.containsKey('volumes') && data['volumes'] is List) {
      for (final item in data['volumes'] as List) {
        if (item is Map) {
          final v = Volume.fromMap(item);
          await HiveBoxes.volumesBox.put(v.id, v.toMap());
          volumesCount++;
        }
      }
    }

    // Transactions
    if (data.containsKey('transactions') && data['transactions'] is List) {
      for (final item in data['transactions'] as List) {
        if (item is Map) {
          final t = PurchaseTransaction.fromMap(item);
          await HiveBoxes.transactionsBox.put(t.id, t.toMap());
          txCount++;
        }
      }
    }

    // RuleConfig
    if (data.containsKey('ruleConfig') && data['ruleConfig'] is Map) {
      final r = RuleConfig.fromMap(data['ruleConfig'] as Map);
      await HiveBoxes.ruleConfigBox.put(r.id, r.toMap());
    } else {
      final defaultConfig = RuleConfig.createDefault();
      await HiveBoxes.ruleConfigBox.put(defaultConfig.id, defaultConfig.toMap());
    }

    // Rules & Passes
    final rulesList = (data['rules'] is List)
        ? (data['rules'] as List)
        : (data['passes'] is List ? data['passes'] as List : null);

    if (rulesList != null) {
      for (final item in rulesList) {
        if (item is Map) {
          final r = RuleModel.fromMap(item);
          await HiveBoxes.rulesBox.put(r.id, r.toMap());
          rulesCount++;
        }
      }
    }

    // Run database migrations to ensure full compatibility
    await DatabaseMigrator.runMigrations();

    return RestoreResult(
      success: true,
      seriesCount: seriesCount,
      volumesCount: volumesCount,
      transactionsCount: txCount,
      rulesCount: rulesCount,
    );
  }

  static Future<RestoreResult> _restoreMergeAndKeepNewest(Map<String, dynamic> data) async {
    int seriesCount = 0;
    int volumesCount = 0;
    int txCount = 0;
    int rulesCount = 0;

    // Load existing items
    final existingSeries = HiveBoxes.seriesBox.values
        .map((e) => Series.fromMap(e))
        .toList();
    final titleToSeriesMap = <String, Series>{};
    final idToSeriesMap = <String, Series>{};
    for (final s in existingSeries) {
      titleToSeriesMap[s.title.toLowerCase()] = s;
      idToSeriesMap[s.id] = s;
    }

    final seriesIdRemap = <String, String>{}; // incomingId -> targetId

    // 1. Merge Series
    if (data.containsKey('series') && data['series'] is List) {
      for (final item in data['series'] as List) {
        if (item is! Map) continue;
        final incoming = Series.fromMap(item);
        final lowerTitle = incoming.title.toLowerCase();

        final match = titleToSeriesMap[lowerTitle] ?? idToSeriesMap[incoming.id];
        if (match == null) {
          // New Series
          await HiveBoxes.seriesBox.put(incoming.id, incoming.toMap());
          titleToSeriesMap[lowerTitle] = incoming;
          idToSeriesMap[incoming.id] = incoming;
          seriesIdRemap[incoming.id] = incoming.id;
          seriesCount++;
        } else {
          // Existing Series: Keep target ID
          seriesIdRemap[incoming.id] = match.id;
          // Merge metadata
          final mergedMeta = Map<String, dynamic>.from(match.customMetadata)
            ..addAll(incoming.customMetadata);
          final mergedTags = {...match.tags, ...incoming.tags}.toList();
          final mergedSeries = match.copyWith(
            tags: mergedTags,
            customMetadata: mergedMeta,
            totalVolumesReleased: incoming.totalVolumesReleased ?? match.totalVolumesReleased,
          );
          await HiveBoxes.seriesBox.put(match.id, mergedSeries.toMap());
        }
      }
    }

    // 2. Merge Volumes
    final existingVolumes = HiveBoxes.volumesBox.values
        .map((e) => Volume.fromMap(e))
        .toList();
    final volumeKeyMap = <String, Volume>{}; // "$seriesId-$volumeNumber" -> Volume
    for (final v in existingVolumes) {
      volumeKeyMap['${v.seriesId}-${v.volumeNumber}'] = v;
    }

    final volumeIdRemap = <String, String>{}; // incomingVolumeId -> targetVolumeId

    if (data.containsKey('volumes') && data['volumes'] is List) {
      for (final item in data['volumes'] as List) {
        if (item is! Map) continue;
        final incomingVol = Volume.fromMap(item);
        final targetSeriesId = seriesIdRemap[incomingVol.seriesId] ?? incomingVol.seriesId;

        final key = '$targetSeriesId-${incomingVol.volumeNumber}';
        final existingVol = volumeKeyMap[key];

        if (existingVol == null) {
          final newVol = incomingVol.copyWith(seriesId: targetSeriesId);
          await HiveBoxes.volumesBox.put(newVol.id, newVol.toMap());
          volumeKeyMap[key] = newVol;
          volumeIdRemap[incomingVol.id] = newVol.id;
          volumesCount++;
        } else {
          volumeIdRemap[incomingVol.id] = existingVol.id;
          // If incoming is owned and existing is not, or incoming has newer release date
          final updated = existingVol.copyWith(
            isOwned: existingVol.isOwned || incomingVol.isOwned,
            isGift: existingVol.isGift || incomingVol.isGift,
            availability: (existingVol.availability == 'available')
                ? existingVol.availability
                : incomingVol.availability,
            releaseDate: existingVol.releaseDate ?? incomingVol.releaseDate,
          );
          await HiveBoxes.volumesBox.put(existingVol.id, updated.toMap());
        }
      }
    }

    // 3. Merge Transactions
    final existingTxIds = HiveBoxes.transactionsBox.keys.toSet();
    final existingTxVolumeIds = HiveBoxes.transactionsBox.values
        .map((e) => e['volumeId']?.toString())
        .where((id) => id != null)
        .toSet();

    if (data.containsKey('transactions') && data['transactions'] is List) {
      for (final item in data['transactions'] as List) {
        if (item is! Map) continue;
        final incomingTx = PurchaseTransaction.fromMap(item);
        final targetVolId = volumeIdRemap[incomingTx.volumeId] ?? incomingTx.volumeId;

        // If transaction ID is unique and volume doesn't already have a transaction
        if (!existingTxIds.contains(incomingTx.id) && !existingTxVolumeIds.contains(targetVolId)) {
          final newTx = incomingTx.copyWith(volumeId: targetVolId);
          await HiveBoxes.transactionsBox.put(newTx.id, newTx.toMap());
          existingTxIds.add(newTx.id);
          existingTxVolumeIds.add(targetVolId);
          txCount++;
        }
      }
    }

    // 4. Merge RuleConfig
    if (data.containsKey('ruleConfig') && data['ruleConfig'] is Map) {
      final incomingConfig = RuleConfig.fromMap(data['ruleConfig'] as Map);
      final currentMap = HiveBoxes.ruleConfigBox.get('global_config');
      final currentConfig = currentMap != null
          ? RuleConfig.fromMap(currentMap)
          : RuleConfig.createDefault();

      final mergedBonusMonths = {...currentConfig.bonusMonths, ...incomingConfig.bonusMonths}.toList();
      final mergedNoBookMonths = {...currentConfig.noBookMonths, ...incomingConfig.noBookMonths}.toList();
      final mergedLedger = Map<String, int>.from(currentConfig.customBonusLedger)
        ..addAll(incomingConfig.customBonusLedger);

      final mergedConfig = currentConfig.copyWith(
        bonusMonths: mergedBonusMonths,
        noBookMonths: mergedNoBookMonths,
        customBonusLedger: mergedLedger,
      );
      await HiveBoxes.ruleConfigBox.put(mergedConfig.id, mergedConfig.toMap());
    }

    // 5. Merge Rules
    final existingRuleNames = HiveBoxes.rulesBox.values
        .map((e) => e['name']?.toString().toLowerCase())
        .where((n) => n != null)
        .toSet();

    final rulesList = (data['rules'] is List)
        ? (data['rules'] as List)
        : (data['passes'] is List ? data['passes'] as List : null);

    if (rulesList != null) {
      int nextPriority = HiveBoxes.rulesBox.length;
      for (final item in rulesList) {
        if (item is! Map) continue;
        final r = RuleModel.fromMap(item);
        if (!existingRuleNames.contains(r.name.toLowerCase())) {
          final toSave = r.copyWith(priorityOrder: nextPriority++);
          await HiveBoxes.rulesBox.put(toSave.id, toSave.toMap());
          existingRuleNames.add(r.name.toLowerCase());
          rulesCount++;
        }
      }
    }

    await DatabaseMigrator.runMigrations();

    return RestoreResult(
      success: true,
      seriesCount: seriesCount,
      volumesCount: volumesCount,
      transactionsCount: txCount,
      rulesCount: rulesCount,
    );
  }

  /// Parse from CSV string (Generic, Goodreads, StoryGraph)
  static List<ImportItem> parseCsvString(String csvString) {
    final converter = const CsvToListConverter(
      shouldParseNumbers: false,
      eol: '\n',
    );

    final normalized = csvString.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final rows = converter.convert(normalized);

    if (rows.isEmpty) return [];

    final headers = rows.first.map((e) => e.toString().trim().toLowerCase()).toList();
    final dataRows = rows.sublist(1);

    // Detect file type
    if (headers.contains('exclusive shelf') ||
        (headers.contains('title') && headers.contains('author(s) l-f'))) {
      return _parseGoodreadsCsv(headers, dataRows);
    } else if (headers.contains('read status') && headers.contains('star rating')) {
      return _parseStoryGraphCsv(headers, dataRows);
    } else {
      return _parseGenericCsv(headers, dataRows);
    }
  }

  /// Parse from Excel (.xlsx) bytes
  static List<ImportItem> parseExcelBytes(Uint8List bytes) {
    final excel = Excel.decodeBytes(bytes);
    final items = <ImportItem>[];

    for (final table in excel.tables.keys) {
      final sheet = excel.tables[table];
      if (sheet == null || sheet.rows.isEmpty) continue;

      final headerRow = sheet.rows.first
          .map((cell) => cell?.value?.toString().trim().toLowerCase() ?? '')
          .toList();
      final dataRows = sheet.rows.sublist(1).map((row) {
        return row.map((cell) => cell?.value?.toString() ?? '').toList();
      }).toList();

      items.addAll(_parseGenericCsv(headerRow, dataRows));
    }

    return items;
  }

  /// Goodreads CSV parser
  static List<ImportItem> _parseGoodreadsCsv(List<String> headers, List<List<dynamic>> rows) {
    final titleIdx = headers.indexOf('title');
    final shelfIdx = headers.indexOf('exclusive shelf');
    final dateReadIdx = headers.indexOf('date read');
    final formatIdx = headers.indexOf('binding');

    final items = <ImportItem>[];

    for (final row in rows) {
      if (titleIdx == -1 || titleIdx >= row.length) continue;
      final rawTitle = row[titleIdx]?.toString().trim() ?? '';
      if (rawTitle.isEmpty) continue;

      final parsed = parseTitleAndVolume(rawTitle);
      final shelf = (shelfIdx != -1 && shelfIdx < row.length)
          ? row[shelfIdx]?.toString().toLowerCase().trim()
          : 'read';
      final binding = (formatIdx != -1 && formatIdx < row.length)
          ? row[formatIdx]?.toString().toLowerCase().trim()
          : '';

      final isOwned = shelf == 'read' || shelf == 'currently-reading';
      final status = shelf == 'to-read' ? 'wishlist' : 'active';

      String type = 'lightNovel';
      if (rawTitle.toLowerCase().contains('manga') || binding == 'comic') {
        type = 'manga';
      } else if (rawTitle.toLowerCase().contains('comic')) {
        type = 'comic';
      }

      DateTime? dateRead;
      if (dateReadIdx != -1 && dateReadIdx < row.length) {
        final dateStr = row[dateReadIdx]?.toString().trim();
        if (dateStr != null && dateStr.isNotEmpty) {
          dateRead = DateTime.tryParse(dateStr);
        }
      }

      items.add(ImportItem(
        rawTitle: rawTitle,
        seriesTitle: parsed.seriesTitle,
        volumeNumber: parsed.volumeNumber,
        type: type,
        status: status,
        isOwned: isOwned,
        availability: 'available',
        releaseOrPurchaseDate: dateRead,
        sourceFormat: 'goodreads',
      ));
    }

    return items;
  }

  /// StoryGraph CSV parser
  static List<ImportItem> _parseStoryGraphCsv(List<String> headers, List<List<dynamic>> rows) {
    final titleIdx = headers.indexOf('title');
    final statusIdx = headers.indexOf('read status');
    final dateIdx = headers.indexOf('date added');

    final items = <ImportItem>[];

    for (final row in rows) {
      if (titleIdx == -1 || titleIdx >= row.length) continue;
      final rawTitle = row[titleIdx]?.toString().trim() ?? '';
      if (rawTitle.isEmpty) continue;

      final parsed = parseTitleAndVolume(rawTitle);
      final statusStr = (statusIdx != -1 && statusIdx < row.length)
          ? row[statusIdx]?.toString().toLowerCase().trim()
          : 'read';

      final isOwned = statusStr == 'read' || statusStr == 'currently-reading';
      final status = statusStr == 'to-read' ? 'wishlist' : 'active';

      DateTime? dateAdded;
      if (dateIdx != -1 && dateIdx < row.length) {
        final dStr = row[dateIdx]?.toString().trim();
        if (dStr != null && dStr.isNotEmpty) {
          dateAdded = DateTime.tryParse(dStr);
        }
      }

      items.add(ImportItem(
        rawTitle: rawTitle,
        seriesTitle: parsed.seriesTitle,
        volumeNumber: parsed.volumeNumber,
        type: 'lightNovel',
        status: status,
        isOwned: isOwned,
        availability: 'available',
        releaseOrPurchaseDate: dateAdded,
        sourceFormat: 'storygraph',
      ));
    }

    return items;
  }

  /// Generic CSV & Excel parser
  static List<ImportItem> _parseGenericCsv(List<String> headers, List<List<dynamic>> rows) {
    int titleIdx = _findHeaderIndex(headers, ['title', 'series', 'book', 'name']);
    int volIdx = _findHeaderIndex(headers, ['volume', 'vol', 'volnum', 'number', 'vol_no']);
    int typeIdx = _findHeaderIndex(headers, ['type', 'format', 'category']);
    int statusIdx = _findHeaderIndex(headers, ['status', 'shelf', 'state']);
    int ownedIdx = _findHeaderIndex(headers, ['owned', 'isowned', 'have', 'purchased']);
    int priceIdx = _findHeaderIndex(headers, ['price', 'cost', 'amount']);

    final items = <ImportItem>[];

    for (final row in rows) {
      if (titleIdx == -1 || titleIdx >= row.length) {
        if (row.isEmpty) continue;
        titleIdx = 0;
      }

      final rawTitle = row[titleIdx]?.toString().trim() ?? '';
      if (rawTitle.isEmpty) continue;

      double volNum = 1.0;
      String seriesTitle = rawTitle;

      if (volIdx != -1 && volIdx < row.length) {
        final vVal = row[volIdx]?.toString().trim() ?? '';
        final parsedNum = double.tryParse(vVal);
        if (parsedNum != null) {
          volNum = parsedNum;
        } else {
          final p = parseTitleAndVolume(rawTitle);
          seriesTitle = p.seriesTitle;
          volNum = p.volumeNumber;
        }
      } else {
        final p = parseTitleAndVolume(rawTitle);
        seriesTitle = p.seriesTitle;
        volNum = p.volumeNumber;
      }

      String type = 'lightNovel';
      if (typeIdx != -1 && typeIdx < row.length) {
        final tStr = row[typeIdx]?.toString().toLowerCase().trim() ?? '';
        if (tStr.contains('manga')) {
          type = 'manga';
        } else if (tStr.contains('comic')) {
          type = 'comic';
        } else if (tStr.contains('book') || tStr.contains('novel')) {
          type = 'book';
        }
      }

      String status = 'active';
      if (statusIdx != -1 && statusIdx < row.length) {
        final sStr = row[statusIdx]?.toString().toLowerCase().trim() ?? '';
        if (sStr.contains('wish')) {
          status = 'wishlist';
        } else if (sStr.contains('comp')) {
          status = 'completed';
        } else if (sStr.contains('drop')) {
          status = 'dropped';
        }
      }

      bool isOwned = true;
      if (ownedIdx != -1 && ownedIdx < row.length) {
        final oStr = row[ownedIdx]?.toString().toLowerCase().trim() ?? '';
        isOwned = oStr == 'true' ||
            oStr == '1' ||
            oStr == 'yes' ||
            oStr == 'owned' ||
            oStr == 'read';
      }

      double price = 0.0;
      if (priceIdx != -1 && priceIdx < row.length) {
        final pStr = row[priceIdx]?.toString().replaceAll('\$', '').trim() ?? '';
        price = double.tryParse(pStr) ?? 0.0;
      }

      items.add(ImportItem(
        rawTitle: rawTitle,
        seriesTitle: seriesTitle,
        volumeNumber: volNum,
        type: type,
        status: status,
        isOwned: isOwned,
        price: price,
        sourceFormat: 'csv',
      ));
    }

    return items;
  }

  static int _findHeaderIndex(List<String> headers, List<String> matchers) {
    for (int i = 0; i < headers.length; i++) {
      final h = headers[i];
      for (final m in matchers) {
        if (h == m || h.contains(m)) {
          return i;
        }
      }
    }
    return -1;
  }
}
