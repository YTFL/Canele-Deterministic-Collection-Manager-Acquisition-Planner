import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:hive/hive.dart';

import '../core/database/database_migrator.dart';
import '../core/database/hive_boxes.dart';
import 'profile_service.dart';
import '../models/profile.dart';
import '../models/series.dart';
import '../models/volume.dart';
import '../models/game_item.dart';
import '../models/custom_item.dart';
import '../models/purchase_transaction.dart';
import '../models/rule_config.dart';
import '../core/utils/currency_helper.dart';
import '../core/utils/workspace_terminology.dart';
import 'exchange_rate_service.dart';

class UniversalExporter {
  /// Lossless Database Export as JSON string.
  /// If [specificProfileId] is provided, exports only that workspace.
  /// Otherwise, exports all profiles and all workspaces in a multi-profile v2 bundle.
  static String exportFullAppStateToJson({bool indent = true, String? specificProfileId}) {
    final currentProfile = ProfileService.instance.activeProfile;
    final allProfiles = ProfileService.instance.getAllProfiles();

    if (specificProfileId != null) {
      final targetProfile = ProfileService.instance.getProfileById(specificProfileId) ?? currentProfile;
      final series = HiveBoxes.getSeriesBox(targetProfile.id).values.toList();
      final volumes = HiveBoxes.getVolumesBox(targetProfile.id).values.toList();
      final transactions = HiveBoxes.getTransactionsBox(targetProfile.id).values.toList();
      final ruleConfig = HiveBoxes.getRuleConfigBox(targetProfile.id).get('global_config') ??
          RuleConfig.createDefault().toMap();
      final rules = HiveBoxes.getRulesBox(targetProfile.id).values.toList();

      final data = {
        'version': '2.0.0',
        'scope': 'single_workspace',
        'schemaVersion': DatabaseMigrator.currentSchemaVersion,
        'exportedAt': DateTime.now().toUtc().toIso8601String(),
        'profile': targetProfile.toMap(),
        'series': series,
        'volumes': volumes,
        'transactions': transactions,
        'ruleConfig': ruleConfig,
        'rules': rules,
        'passes': rules,
      };

      final encoder = indent ? const JsonEncoder.withIndent('  ') : const JsonEncoder();
      return encoder.convert(data);
    }

    // Full system export across all workspaces
    final workspacesMap = <String, Map<String, dynamic>>{};
    for (final p in allProfiles) {
      final pSeries = HiveBoxes.getSeriesBox(p.id).values.toList();
      final pVolumes = HiveBoxes.getVolumesBox(p.id).values.toList();
      final pTransactions = HiveBoxes.getTransactionsBox(p.id).values.toList();
      final pRuleConfig = HiveBoxes.getRuleConfigBox(p.id).get('global_config') ??
          RuleConfig.createDefault().toMap();
      final pRules = HiveBoxes.getRulesBox(p.id).values.toList();

      workspacesMap[p.id] = {
        'profile': p.toMap(),
        'series': pSeries,
        'volumes': pVolumes,
        'transactions': pTransactions,
        'ruleConfig': pRuleConfig,
        'rules': pRules,
        'passes': pRules,
      };
    }

    // Active profile's items for top-level backward compatibility
    final activeSeries = HiveBoxes.seriesBox.values.toList();
    final activeVolumes = HiveBoxes.volumesBox.values.toList();
    final activeTransactions = HiveBoxes.transactionsBox.values.toList();
    final activeRuleConfig = HiveBoxes.ruleConfigBox.get('global_config') ??
        RuleConfig.createDefault().toMap();
    final activeRules = HiveBoxes.rulesBox.values.toList();

    final data = {
      'version': '2.0.0',
      'schemaVersion': DatabaseMigrator.currentSchemaVersion,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'activeProfileId': ProfileService.instance.activeProfileId,
      'profiles': allProfiles.map((p) => p.toMap()).toList(),
      'workspaces': workspacesMap,
      // Backward-compatible top-level items representing active workspace
      'profile': currentProfile.toMap(),
      'series': activeSeries,
      'volumes': activeVolumes,
      'transactions': activeTransactions,
      'ruleConfig': activeRuleConfig,
      'rules': activeRules,
      'passes': activeRules,
    };

    final encoder = indent ? const JsonEncoder.withIndent('  ') : const JsonEncoder();
    return encoder.convert(data);
  }

  /// Generates table rows for collection export based on workspace profile type
  static List<List<dynamic>> generateCollectionRows({
    Profile? profile,
    List<Series>? seriesList,
    List<Volume>? volumesList,
  }) {
    final activeProfile = profile ?? ProfileService.instance.activeProfile;
    final sBoxName = HiveBoxes.getSeriesBoxName(activeProfile.id);
    final allSeries = seriesList ??
        (Hive.isBoxOpen(sBoxName)
            ? HiveBoxes.getSeriesBox(activeProfile.id).values.whereType<Map>().map((e) => Series.fromMap(e)).toList()
            : <Series>[])
          ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

    final vBoxName = HiveBoxes.getVolumesBoxName(activeProfile.id);
    final allVolumes = volumesList ??
        (Hive.isBoxOpen(vBoxName)
            ? HiveBoxes.getVolumesBox(activeProfile.id).values.whereType<Map>().map((e) => Volume.fromMap(e)).toList()
            : <Volume>[]);

    final tBoxName = HiveBoxes.getTransactionsBoxName(activeProfile.id);
    final allTxs = Hive.isBoxOpen(tBoxName)
        ? HiveBoxes.getTransactionsBox(activeProfile.id).values.whereType<Map>().map((e) => PurchaseTransaction.fromMap(e)).toList()
        : <PurchaseTransaction>[];

    final cBoxName = HiveBoxes.getRuleConfigBoxName(activeProfile.id);
    final ruleConfigMap = Hive.isBoxOpen(cBoxName)
        ? HiveBoxes.getRuleConfigBox(activeProfile.id).get('global_config')
        : null;
    final baseCurrency = ruleConfigMap is Map ? (ruleConfigMap['currency']?.toString() ?? 'USD') : 'USD';
    final exchangeRates = ExchangeRateService.loadFromStorage();

    final rows = <List<dynamic>>[];

    switch (activeProfile.type) {
      case ProfileType.games:
        rows.add([
          'Title',
          'Platform',
          'Status',
          'Playtime (Hours)',
          'Price ($baseCurrency)',
          'Currency',
          'Release Date',
          'Notes',
          'Tags',
        ]);
        for (final s in allSeries) {
          final game = GameItem.fromSeries(s);
          rows.add([
            game.title,
            game.platformInfo.displayName,
            game.backlogStatus.label,
            game.playtimeHours?.toStringAsFixed(1) ?? '0.0',
            game.price != null ? game.price!.toStringAsFixed(2) : '',
            game.currency ?? baseCurrency,
            game.releaseDate != null ? game.releaseDate!.toIso8601String().split('T').first : '',
            game.notes ?? '',
            game.tags.join('; '),
          ]);
        }
        break;

      case ProfileType.custom:
        final terms = activeProfile.terms;
        final headers = <dynamic>['Title', terms.groupLabel];
        if (terms.isFieldEnabled('platform')) headers.add('Category');
        if (terms.isFieldEnabled('edition')) headers.add('Edition');
        headers.add('Status');
        if (terms.isFieldEnabled('price')) headers.add('Price ($baseCurrency)');
        if (terms.isFieldEnabled('price')) headers.add('Currency');
        if (terms.isFieldEnabled('rating')) headers.add('Rating');
        if (terms.isFieldEnabled('releaseDate')) headers.add('Release Date');
        if (terms.isFieldEnabled('notes')) headers.add('Notes');
        headers.add('Tags');
        rows.add(headers);

        for (final s in allSeries) {
          final item = CustomItem.fromSeries(s);
          final row = <dynamic>[item.title, item.groupTitle ?? ''];
          if (terms.isFieldEnabled('platform')) row.add(item.platform ?? '');
          if (terms.isFieldEnabled('edition')) row.add(item.edition ?? '');
          row.add(terms.resolveStatus(item.status).label);
          if (terms.isFieldEnabled('price')) row.add(item.price != null ? item.price!.toStringAsFixed(2) : '');
          if (terms.isFieldEnabled('price')) row.add(item.currency ?? baseCurrency);
          if (terms.isFieldEnabled('rating')) row.add(item.rating != null ? item.rating!.toStringAsFixed(1) : '');
          if (terms.isFieldEnabled('releaseDate')) {
            row.add(item.releaseDate != null ? item.releaseDate!.toIso8601String().split('T').first : '');
          }
          if (terms.isFieldEnabled('notes')) row.add(item.notes ?? '');
          row.add(item.tags.join('; '));
          rows.add(row);
        }
        break;

      case ProfileType.books:
        rows.add([
          'Title',
          'Author',
          'Format',
          'Type',
          'Total Volumes',
          'Owned Volumes',
          'Total Spent ($baseCurrency)',
          'Status',
          'Tags',
        ]);

        for (final s in allSeries) {
          final sVolumes = allVolumes.where((v) => v.seriesId == s.id).toList();
          double sSpent = 0.0;
          final purchasedVolumes = sVolumes.where((v) => v.isOwned && !v.isGift).toList();
          if (s.seriesPrice != null && s.seriesPrice! > 0) {
            if (purchasedVolumes.isNotEmpty) {
              sSpent = CurrencyHelper.convert(
                amount: s.seriesPrice!,
                fromCurrency: s.currency ?? baseCurrency,
                toCurrency: baseCurrency,
                rates: exchangeRates,
              );
            }
          } else {
            for (final v in sVolumes) {
              if (!v.isOwned || v.isGift) continue;
              final txs = allTxs.where((t) => t.volumeId == v.id && t.quotaBucket != 'gift').toList();
              if (txs.isNotEmpty && txs.first.price > 0) {
                final tx = txs.first;
                final txCurr = tx.currency ?? baseCurrency;
                sSpent += CurrencyHelper.convert(
                  amount: tx.price,
                  fromCurrency: txCurr,
                  toCurrency: baseCurrency,
                  rates: exchangeRates,
                );
              } else if (v.price != null && v.price! > 0) {
                final volCurr = v.currency ?? baseCurrency;
                sSpent += CurrencyHelper.convert(
                  amount: v.price!,
                  fromCurrency: volCurr,
                  toCurrency: baseCurrency,
                  rates: exchangeRates,
                );
              } else {
                final defPrice = s.defaultVolumePrice ?? CurrencyHelper.defaultVolumePrice;
                final defCurr = s.defaultVolumeCurrency ?? CurrencyHelper.defaultVolumeCurrency;
                sSpent += CurrencyHelper.convert(
                  amount: defPrice,
                  fromCurrency: defCurr,
                  toCurrency: baseCurrency,
                  rates: exchangeRates,
                );
              }
            }
          }
          final ownedCount = sVolumes.where((v) => v.isOwned).length;
          final totalCount = s.totalVolumesReleased ?? sVolumes.length;
          final author = s.customMetadata['author']?.toString() ?? '';
          final isSingle = s.releaseStatus != 'ongoing' && (totalCount <= 1 && sVolumes.length <= 1);
          final typeLabel = isSingle ? 'Single' : 'Series';
          final tagsStr = s.tags.join('; ');

          rows.add([
            s.title,
            author,
            _formatTypeName(s.type),
            typeLabel,
            totalCount,
            ownedCount,
            sSpent > 0 ? sSpent.toStringAsFixed(2) : '0.00',
            s.collectionStatus,
            tagsStr,
          ]);
        }
        break;
    }

    return rows;
  }

  /// Export Collection to CSV string
  static String exportCollectionToCsv({
    Profile? profile,
    List<Series>? seriesList,
    List<Volume>? volumesList,
  }) {
    final rows = generateCollectionRows(
      profile: profile,
      seriesList: seriesList,
      volumesList: volumesList,
    );
    return const ListToCsvConverter().convert(rows);
  }

  /// Export Collection to XLSX bytes
  static Uint8List exportCollectionToXlsx({
    Profile? profile,
    List<Series>? seriesList,
    List<Volume>? volumesList,
  }) {
    final rows = generateCollectionRows(
      profile: profile,
      seriesList: seriesList,
      volumesList: volumesList,
    );

    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';
    excel.rename(defaultSheet, 'Collection');
    final sheet = excel['Collection'];

    for (final row in rows) {
      final cellValues = row.map<CellValue>((val) {
        if (val == null) return TextCellValue('');
        if (val is int) return IntCellValue(val);
        if (val is double) return DoubleCellValue(val);
        return TextCellValue(val.toString());
      }).toList();
      sheet.appendRow(cellValues);
    }

    final encoded = excel.encode();
    return Uint8List.fromList(encoded ?? []);
  }

  /// Helper to write bytes or text to temporary directory and share via SharePlus
  static Future<void> shareExportedFile({
    required List<int> bytes,
    required String fileName,
    String? subject,
    String? text,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);

    await Share.shareXFiles(
      [XFile(filePath)],
      subject: subject ?? fileName,
      text: text,
    );
  }

  static String _formatTypeName(String type) {
    switch (type.toLowerCase()) {
      case 'lightnovel':
        return 'Light Novel';
      case 'manga':
        return 'Manga';
      case 'comic':
        return 'Comic';
      case 'book':
        return 'Book';
      case 'game':
        return 'Game';
      case 'custom':
        return 'Custom';
      default:
        return type.isNotEmpty ? '${type[0].toUpperCase()}${type.substring(1)}' : type;
    }
  }
}
