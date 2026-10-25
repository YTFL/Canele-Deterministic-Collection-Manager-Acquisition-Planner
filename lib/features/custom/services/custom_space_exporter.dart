import 'dart:convert';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';

import '../../../core/database/database_migrator.dart';
import '../../../core/database/hive_boxes.dart';
import '../../../models/custom_item.dart';
import '../../../models/profile.dart';
import '../../../models/purchase_transaction.dart';
import '../../../models/rule_config.dart';
import '../../../models/series.dart';
import '../../../services/profile_service.dart';
import '../models/custom_space_backup.dart';

class CustomSpaceExporter {
  /// Builds a strongly-typed CustomSpaceBackup model from Hive storage for a given profile ID.
  static CustomSpaceBackup buildBackup(String profileId) {
    final profile = ProfileService.instance.getProfileById(profileId) ??
        Profile(
          id: profileId,
          name: 'Custom Collection',
          type: ProfileType.custom,
          icon: 'layers',
          createdAt: DateTime.now(),
        );

    final sBox = HiveBoxes.getSeriesBox(profileId);
    final items = <CustomItem>[];
    for (final key in sBox.keys) {
      final val = sBox.get(key);
      if (val is Map) {
        try {
          // If stored as Series map, convert via fromSeries
          final s = Series.fromMap(val);
          items.add(CustomItem.fromSeries(s));
        } catch (_) {
          // Or direct CustomItem map
          items.add(CustomItem.fromMap(val));
        }
      }
    }
    items.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

    final cBox = HiveBoxes.getRuleConfigBox(profileId);
    final rawConfig = cBox.get('global_config');
    final ruleConfig = rawConfig is Map ? RuleConfig.fromMap(rawConfig) : RuleConfig.createDefault();

    final tBox = HiveBoxes.getTransactionsBox(profileId);
    final transactions = <PurchaseTransaction>[];
    for (final key in tBox.keys) {
      final val = tBox.get(key);
      if (val != null) {
        transactions.add(PurchaseTransaction.fromMap(val));
      }
    }
    transactions.sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));

    return CustomSpaceBackup(
      schemaVersion: DatabaseMigrator.currentSchemaVersion.toString(),
      exportedAt: DateTime.now(),
      profile: profile,
      items: items,
      ruleConfig: ruleConfig,
      transactions: transactions,
    );
  }

  /// Exports the custom workspace state to a JSON string.
  static String exportToJson(String profileId, {bool indent = true}) {
    final backup = buildBackup(profileId);
    return backup.toJson(indent: indent);
  }

  /// Generates structured table rows representing the custom collection for CSV/Excel export.
  static List<List<dynamic>> generateTableRows(String profileId) {
    final backup = buildBackup(profileId);
    final schema = backup.profile.customSchema;
    final itemLabel = schema?.itemLabel ?? 'Item';
    final groupLabel = schema?.groupLabel ?? 'Group';

    final dynamicAttrs = schema?.customAttributes ?? [];

    final rows = <List<dynamic>>[];
    // Header row
    final headers = <dynamic>[
      '$itemLabel Title',
      groupLabel,
      'Status',
      'Price',
      'Currency',
      'Platform / Medium',
      'Edition',
      'Tags',
      for (final attr in dynamicAttrs) attr.name,
    ];
    rows.add(headers);

    for (final item in backup.items) {
      final row = <dynamic>[
        item.title,
        item.groupTitle ?? '',
        item.status,
        item.price ?? 0.0,
        item.currency ?? backup.ruleConfig.currency,
        item.platform ?? '',
        item.edition ?? '',
        item.tags.join('; '),
      ];

      for (final attr in dynamicAttrs) {
        row.add(item.customFields[attr.id]?.toString() ?? '');
      }

      rows.add(row);
    }

    return rows;
  }

  /// Exports collection to a CSV string.
  static String exportToCsv(String profileId) {
    final rows = generateTableRows(profileId);
    return const ListToCsvConverter().convert(rows);
  }

  /// Exports collection to Excel (.xlsx) bytes.
  static Uint8List exportToExcel(String profileId) {
    final excel = Excel.createExcel();
    final sheetName = 'Custom Collection';
    excel.rename(excel.getDefaultSheet() ?? 'Sheet1', sheetName);
    final sheet = excel[sheetName];

    final rows = generateTableRows(profileId);
    for (int r = 0; r < rows.length; r++) {
      final row = rows[r];
      for (int c = 0; c < row.length; c++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r));
        cell.value = TextCellValue(row[c]?.toString() ?? '');
      }
    }

    final bytes = excel.encode();
    return Uint8List.fromList(bytes ?? []);
  }
}
