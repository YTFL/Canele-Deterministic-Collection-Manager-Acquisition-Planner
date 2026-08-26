import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/database/database_migrator.dart';
import '../core/database/hive_boxes.dart';
import '../models/series.dart';
import '../models/volume.dart';
import '../models/rule_config.dart';

class UniversalExporter {
  /// Lossless Full Database Export as JSON string
  static String exportFullAppStateToJson({bool indent = true}) {
    final series = HiveBoxes.seriesBox.values.toList();
    final volumes = HiveBoxes.volumesBox.values.toList();
    final transactions = HiveBoxes.transactionsBox.values.toList();
    final ruleConfig = HiveBoxes.ruleConfigBox.get('global_config') ??
        RuleConfig.createDefault().toMap();
    final rules = HiveBoxes.rulesBox.values.toList();

    final data = {
      'version': '2.0.0',
      'schemaVersion': DatabaseMigrator.currentSchemaVersion,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'series': series,
      'volumes': volumes,
      'transactions': transactions,
      'ruleConfig': ruleConfig,
      'rules': rules,
      'passes': rules, // backward compatibility
    };

    final encoder = indent ? const JsonEncoder.withIndent('  ') : const JsonEncoder();
    return encoder.convert(data);
  }

  /// Export Collection to CSV string
  static String exportCollectionToCsv({
    List<Series>? seriesList,
    List<Volume>? volumesList,
  }) {
    final allSeries = seriesList ??
        HiveBoxes.seriesBox.values
            .map((e) => Series.fromMap(e))
            .toList()
          ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

    final allVolumes = volumesList ??
        HiveBoxes.volumesBox.values
            .map((e) => Volume.fromMap(e))
            .toList();

    final rows = <List<dynamic>>[];
    // CSV Header
    rows.add([
      'Title',
      'Author',
      'Format',
      'Type',
      'Total Volumes',
      'Owned Volumes',
      'Status',
      'Tags',
    ]);

    for (final s in allSeries) {
      final sVolumes = allVolumes.where((v) => v.seriesId == s.id).toList();
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
        s.collectionStatus,
        tagsStr,
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }

  /// Export Collection to XLSX bytes
  static Uint8List exportCollectionToXlsx({
    List<Series>? seriesList,
    List<Volume>? volumesList,
  }) {
    final allSeries = seriesList ??
        HiveBoxes.seriesBox.values
            .map((e) => Series.fromMap(e))
            .toList()
          ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

    final allVolumes = volumesList ??
        HiveBoxes.volumesBox.values
            .map((e) => Volume.fromMap(e))
            .toList();

    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';
    excel.rename(defaultSheet, 'Collection');
    final sheet = excel['Collection'];

    // Headers
    sheet.appendRow([
      TextCellValue('Title'),
      TextCellValue('Author'),
      TextCellValue('Format'),
      TextCellValue('Type'),
      TextCellValue('Total Volumes'),
      TextCellValue('Owned Volumes'),
      TextCellValue('Status'),
      TextCellValue('Tags'),
    ]);

    for (final s in allSeries) {
      final sVolumes = allVolumes.where((v) => v.seriesId == s.id).toList();
      final ownedCount = sVolumes.where((v) => v.isOwned).length;
      final totalCount = s.totalVolumesReleased ?? sVolumes.length;
      final author = s.customMetadata['author']?.toString() ?? '';
      final isSingle = s.releaseStatus != 'ongoing' && (totalCount <= 1 && sVolumes.length <= 1);
      final typeLabel = isSingle ? 'Single' : 'Series';
      final tagsStr = s.tags.join('; ');

      sheet.appendRow([
        TextCellValue(s.title),
        TextCellValue(author),
        TextCellValue(_formatTypeName(s.type)),
        TextCellValue(typeLabel),
        IntCellValue(totalCount),
        IntCellValue(ownedCount),
        TextCellValue(s.collectionStatus),
        TextCellValue(tagsStr),
      ]);
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
      default:
        return type.isNotEmpty ? '${type[0].toUpperCase()}${type.substring(1)}' : type;
    }
  }
}
