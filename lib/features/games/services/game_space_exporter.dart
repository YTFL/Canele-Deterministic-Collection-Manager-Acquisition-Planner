import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';

import '../../../core/database/database_migrator.dart';
import '../../../core/database/hive_boxes.dart';
import '../../../models/profile.dart';
import '../../../models/purchase_transaction.dart';
import '../../../models/rule_config.dart';
import '../../../services/profile_service.dart';
import '../models/game_item.dart';
import '../models/game_rule.dart';
import '../models/game_series.dart';
import '../models/game_space_backup.dart';

class GameSpaceExporter {
  /// Builds a strongly-typed GameSpaceBackup model from Hive storage for a given profile ID.
  static GameSpaceBackup buildBackup(String profileId) {
    final profile = ProfileService.instance.getProfileById(profileId) ??
        Profile(
          id: profileId,
          name: 'Games',
          type: ProfileType.games,
          icon: 'gamepad',
          createdAt: DateTime.now(),
        );

    final sBox = HiveBoxes.getSeriesBox(profileId);
    final franchises = <GameSeries>[];
    for (final key in sBox.keys) {
      final val = sBox.get(key);
      if (val != null) {
        franchises.add(GameSeries.fromMap(val));
      }
    }
    franchises.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

    final vBox = HiveBoxes.getVolumesBox(profileId);
    final games = <GameItem>[];
    for (final key in vBox.keys) {
      final val = vBox.get(key);
      if (val != null) {
        games.add(GameItem.fromMap(val));
      }
    }
    games.sort((a, b) => a.gameNumber.compareTo(b.gameNumber));

    final rBox = HiveBoxes.getRulesBox(profileId);
    final rules = <GameRule>[];
    for (final key in rBox.keys) {
      final val = rBox.get(key);
      if (val != null) {
        rules.add(GameRule.fromMap(val));
      }
    }
    rules.sort((a, b) => a.priorityOrder.compareTo(b.priorityOrder));

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

    return GameSpaceBackup(
      schemaVersion: DatabaseMigrator.currentSchemaVersion.toString(),
      exportedAt: DateTime.now(),
      profile: profile,
      franchises: franchises,
      games: games,
      rules: rules,
      ruleConfig: ruleConfig,
      transactions: transactions,
    );
  }

  /// Exports the games workspace state to a JSON string.
  static String exportToJson(String profileId, {bool indent = true}) {
    final backup = buildBackup(profileId);
    return backup.toJson(indent: indent);
  }

  /// Generates structured table rows representing the games collection for CSV/Excel export.
  static List<List<dynamic>> generateTableRows(String profileId) {
    final backup = buildBackup(profileId);
    final franchiseMap = {for (final f in backup.franchises) f.id: f};

    final rows = <List<dynamic>>[];
    // Header row
    rows.add([
      'Franchise / Collection',
      'Game / DLC Title',
      'Item Type',
      'Game Number',
      'Acquisition Status',
      'Gift / Free Claim',
      'Price',
      'Currency',
      'Availability',
      'Priority Watchlist Target',
    ]);

    for (final item in backup.games) {
      final franchise = franchiseMap[item.seriesId];
      final franchiseTitle = franchise?.title ?? 'Unknown Franchise';

      rows.add([
        franchiseTitle,
        item.title,
        item.itemType == GameItemType.dlc ? 'DLC' : 'Game',
        item.gameNumber,
        item.isOwned ? 'Acquired' : 'Unacquired',
        item.isGift ? 'Yes' : 'No',
        item.price ?? franchise?.defaultGamePrice ?? 0.0,
        item.currency ?? franchise?.defaultCurrency ?? backup.ruleConfig.currency,
        item.availability.name,
        item.isPriorityTarget ? 'Yes' : 'No',
      ]);
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
    final sheetName = 'Games Collection';
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
