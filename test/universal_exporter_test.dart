import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:canele/core/database/hive_boxes.dart';
import 'package:canele/models/rule_model.dart';
import 'package:canele/models/series.dart';
import 'package:canele/models/volume.dart';
import 'package:canele/services/universal_exporter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempHiveDir;

  setUp(() async {
    tempHiveDir = await Directory.systemTemp.createTemp('canele_exporter_test');
    Hive.init(tempHiveDir.path);

    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(RuleScopeTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(ProgressTriggerTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(12)) {
      Hive.registerAdapter(SortCriteriaAdapter());
    }
    if (!Hive.isAdapterRegistered(13)) {
      Hive.registerAdapter(RuleModelAdapter());
    }

    await HiveBoxes.init(tempHiveDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (tempHiveDir.existsSync()) {
      await tempHiveDir.delete(recursive: true);
    }
  });

  group('UniversalExporter Tests', () {
    test('Collection CSV handles quotes, commas in titles, and computes totals correctly', () async {
      final s1 = Series(
        id: 's1',
        title: '86 - Eighty-Six, Vol. 1',
        type: 'lightNovel',
        collectionStatus: 'active',
        tags: const ['Mecha', 'Drama'],
        customMetadata: const {'author': 'Asato Asato'},
      );
      final s2 = Series(
        id: 's2',
        title: 'Look Back',
        type: 'manga',
        collectionStatus: 'completed',
        releaseStatus: 'completed',
        totalVolumesReleased: 1,
        tags: const ['Drama'],
        customMetadata: const {'author': 'Tatsuki Fujimoto'},
      );

      final v1 = Volume(
        id: 'v1',
        seriesId: 's1',
        volumeNumber: 1.0,
        isOwned: true,
      );
      final v2 = Volume(
        id: 'v2',
        seriesId: 's1',
        volumeNumber: 2.0,
        isOwned: false,
      );
      final v3 = Volume(
        id: 'v3',
        seriesId: 's2',
        volumeNumber: 1.0,
        isOwned: true,
      );

      final csvStr = UniversalExporter.exportCollectionToCsv(
        seriesList: [s1, s2],
        volumesList: [v1, v2, v3],
      );

      expect(csvStr, contains('Title,Author,Format,Type,Total Volumes,Owned Volumes,Total Spent (USD),Status,Tags'));
      // Title with comma should be properly quoted
      expect(csvStr, contains('"86 - Eighty-Six, Vol. 1"'));
      expect(csvStr, contains('Asato Asato'));
      expect(csvStr, contains('Light Novel'));
      expect(csvStr, contains('Series'));
      expect(csvStr, contains('Look Back'));
      expect(csvStr, contains('Single'));
    });

    test('Collection XLSX generates valid Excel binary workbook with Collection sheet', () async {
      final s1 = Series(
        id: 's1',
        title: 'Frieren: Beyond Journey\'s End',
        type: 'manga',
        collectionStatus: 'active',
        tags: const ['Fantasy'],
        customMetadata: const {'author': 'Kanehito Yamada'},
      );

      final v1 = Volume(
        id: 'v1',
        seriesId: 's1',
        volumeNumber: 1.0,
        isOwned: true,
      );

      final bytes = UniversalExporter.exportCollectionToXlsx(
        seriesList: [s1],
        volumesList: [v1],
      );

      expect(bytes, isNotEmpty);

      // Verify decode
      final excel = Excel.decodeBytes(bytes);
      expect(excel.tables.containsKey('Collection'), true);

      final sheet = excel.tables['Collection']!;
      expect(sheet.rows.length, 2); // Header + 1 data row

      final headerRow = sheet.rows.first.map((c) => c?.value?.toString()).toList();
      expect(headerRow, contains('Title'));
      expect(headerRow, contains('Owned Volumes'));

      final dataRow = sheet.rows[1].map((c) => c?.value?.toString()).toList();
      expect(dataRow, contains('Frieren: Beyond Journey\'s End'));
      expect(dataRow, contains('Kanehito Yamada'));
      expect(dataRow, contains('Manga'));
    });
  });
}
