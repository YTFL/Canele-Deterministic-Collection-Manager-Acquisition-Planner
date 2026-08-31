import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:canele/core/database/hive_boxes.dart';
import 'package:canele/models/purchase_transaction.dart';
import 'package:canele/models/rule_config.dart';
import 'package:canele/models/rule_model.dart';
import 'package:canele/models/series.dart';
import 'package:canele/models/volume.dart';
import 'package:canele/services/backup_service.dart';
import 'package:canele/services/universal_exporter.dart';
import 'package:canele/services/universal_importer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempHiveDir;
  late Directory tempBackupDir;

  setUp(() async {
    tempHiveDir = await Directory.systemTemp.createTemp('canele_hive_test');
    tempBackupDir = await Directory.systemTemp.createTemp('canele_backup_test');
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

    BackupService.instance.configure(
      targetDirectoryPath: tempBackupDir.path,
      isAutoBackupEnabled: true,
      customDebounceDuration: const Duration(milliseconds: 100),
    );
  });

  tearDown(() async {
    BackupService.instance.stopListening();
    await Hive.close();
    if (tempHiveDir.existsSync()) {
      await tempHiveDir.delete(recursive: true);
    }
    if (tempBackupDir.existsSync()) {
      await tempBackupDir.delete(recursive: true);
    }
  });

  group('BackupService & Serialization Tests', () {
    test('JSON serialization preserves all complex data types', () async {
      // 1. Seed comprehensive test data
      final testSeries = Series(
        id: 's1',
        title: '86 - Eighty-Six',
        type: 'lightNovel',
        collectionStatus: 'active',
        releaseStatus: 'ongoing',
        totalVolumesReleased: 12,
        tags: const ['Sci-Fi', 'Military'],
        customMetadata: const {'author': 'Asato Asato', 'score': 9.5},
      );
      await HiveBoxes.seriesBox.put(testSeries.id, testSeries.toMap());

      final testVolume = Volume(
        id: 'v1',
        seriesId: 's1',
        volumeNumber: 11.5,
        releaseDate: DateTime(2025, 4, 15, 10, 30),
        isOwned: true,
        isGift: false,
        availability: 'available',
        isRestockedWatchlist: false,
        customMetadata: const {'edition': 'Collector'},
      );
      await HiveBoxes.volumesBox.put(testVolume.id, testVolume.toMap());

      final testTx = PurchaseTransaction(
        id: 'tx1',
        volumeId: 'v1',
        purchaseDate: DateTime(2025, 4, 20),
        quotaBucket: 'regular',
        price: 15.99,
        notes: 'Bought at Kinokuniya',
      );
      await HiveBoxes.transactionsBox.put(testTx.id, testTx.toMap());

      final testRule = RuleModel(
        id: 'r1',
        name: 'Restock First',
        isEnabled: true,
        priorityOrder: 0,
        scopeType: RuleScopeType.allSeries,
        progressTrigger: ProgressTriggerType.leastRemainingVolumes,
        volumeThresholdValue: 2,
        restockPriorityEnabled: true,
        sortBy: SortCriteria.lowestVolumeNumber,
      );
      await HiveBoxes.rulesBox.put(testRule.id, testRule.toMap());

      final testConfig = RuleConfig(
        id: 'global_config',
        timelineStartDate: DateTime(2024, 1, 1),
        defaultRegularPerMonth: 2,
        bonusMonths: const [5, 12],
        recurringNoBookMonths: const [8],
        noBookMonths: const ['2024-06', '2024-09'],
        manualBonusCount: 3,
        customBonusLedger: const {'2024-07': 1, '2025-01': 2},
        isOnboardingCompleted: true,
      );
      await HiveBoxes.ruleConfigBox.put(testConfig.id, testConfig.toMap());

      // 2. Export full state to JSON
      final jsonStr = UniversalExporter.exportFullAppStateToJson();
      expect(jsonStr, isNotEmpty);

      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      expect(decoded['version'], '2.0.0');
      expect((decoded['series'] as List).length, 1);
      expect((decoded['volumes'] as List).length, 1);
      expect((decoded['transactions'] as List).length, 1);
      expect((decoded['rules'] as List).length, 1);

      // Verify custom bonus ledger preserved in ruleConfig
      final configMap = decoded['ruleConfig'] as Map<String, dynamic>;
      expect(configMap['customBonusLedger']['2024-07'], 1);
      expect(configMap['customBonusLedger']['2025-01'], 2);
      expect(configMap['bonusMonths'], [5, 12]);
      expect(configMap['recurringNoBookMonths'], [8]);
      expect(configMap['noBookMonths'], ['2024-06', '2024-09']);

      // 3. Test Restore Replace All
      await HiveBoxes.clearAll();
      final restoreRes = await UniversalImporter.restoreFromJson(jsonStr, mode: RestoreMode.replaceAll);
      expect(restoreRes.success, true);
      expect(restoreRes.seriesCount, 1);
      expect(restoreRes.volumesCount, 1);
      expect(restoreRes.transactionsCount, 1);
      expect(restoreRes.rulesCount, 1);

      final restoredVol = Volume.fromMap(HiveBoxes.volumesBox.get('v1')!);
      expect(restoredVol.volumeNumber, 11.5);
      expect(restoredVol.isOwned, true);
      expect(restoredVol.releaseDate?.year, 2025);

      final restoredConfig = RuleConfig.fromMap(HiveBoxes.ruleConfigBox.get('global_config')!);
      expect(restoredConfig.customBonusLedger['2024-07'], 1);
      expect(restoredConfig.bonusMonths, [5, 12]);
      expect(restoredConfig.recurringNoBookMonths, [8]);
    });

    test('Atomic file write rotates to rolling previous backup (canele_autobackup_prev.json)', () async {
      final service = BackupService.instance;

      // Seed 1 item
      await HiveBoxes.seriesBox.put('s1', {
        'id': 's1',
        'title': 'Snapshot 1 Series',
        'type': 'lightNovel',
        'collectionStatus': 'active',
      });

      // Trigger 1st manual snapshot
      final file1 = await service.createBackupSnapshot();
      expect(file1, isNotNull);
      expect(file1!.existsSync(), true);
      expect(file1.path.endsWith('canele_autobackup.json'), true);

      final content1 = await file1.readAsString();
      expect(content1.contains('Snapshot 1 Series'), true);

      // Now add 2nd item and trigger snapshot
      await HiveBoxes.seriesBox.put('s2', {
        'id': 's2',
        'title': 'Snapshot 2 Series',
        'type': 'manga',
        'collectionStatus': 'active',
      });

      final file2 = await service.createBackupSnapshot();
      expect(file2, isNotNull);

      // Check rolling backup file
      final prevFile = File('${tempBackupDir.path}/canele_autobackup_prev.json');
      expect(prevFile.existsSync(), true);

      final prevContent = await prevFile.readAsString();
      expect(prevContent.contains('Snapshot 1 Series'), true);
      expect(prevContent.contains('Snapshot 2 Series'), false);

      final mainContent = await file2!.readAsString();
      expect(mainContent.contains('Snapshot 2 Series'), true);
    });

    test('Debounce timer collapses rapid mutations into a single disk write', () async {
      final service = BackupService.instance;
      service.startListening();

      int notificationCount = 0;
      service.configure(
        onMetadataChanged: (meta) {
          if (meta.lastBackupStatus == 'success') {
            notificationCount++;
          }
        },
      );

      // Rapidly write 10 items in sequence
      for (int i = 0; i < 10; i++) {
        await HiveBoxes.seriesBox.put('s_$i', {
          'id': 's_$i',
          'title': 'Rapid Series $i',
          'type': 'lightNovel',
          'collectionStatus': 'active',
        });
      }

      // Wait for debounce timer (100ms duration set in setup + buffer)
      await Future.delayed(const Duration(milliseconds: 250));

      final mainFile = File('${tempBackupDir.path}/canele_autobackup.json');
      expect(mainFile.existsSync(), true);

      final content = await mainFile.readAsString();
      expect(content.contains('Rapid Series 0'), true);
      expect(content.contains('Rapid Series 9'), true);
      // Collapsed into 1 backup run
      expect(notificationCount, 1);
    });

    test('Pause and resume prevents auto-backup writes during restore operations', () async {
      final service = BackupService.instance;
      service.startListening();

      int saveSuccessCount = 0;
      service.configure(
        onMetadataChanged: (meta) {
          if (meta.lastBackupStatus == 'success') saveSuccessCount++;
        },
      );

      // Pause listener
      service.pauseListening();
      expect(service.isPaused, true);

      // Rapid box writes while paused
      for (int i = 0; i < 5; i++) {
        await HiveBoxes.seriesBox.put('paused_$i', {
          'id': 'paused_$i',
          'title': 'Paused Series $i',
          'type': 'lightNovel',
        });
      }

      await Future.delayed(const Duration(milliseconds: 200));
      // No snapshot should have been written
      expect(saveSuccessCount, 0);

      // Resume
      service.resumeListening();
      expect(service.isPaused, false);
    });

    test('Merge & Keep Newest mode combines series and volumes without overwriting', () async {
      // 1. Existing state: Series A with Volume 1
      await HiveBoxes.seriesBox.put('s_a', {
        'id': 's_a',
        'title': 'Frieren',
        'type': 'manga',
        'collectionStatus': 'active',
        'tags': ['Fantasy'],
        'customMetadata': {'rating': 10},
      });

      await HiveBoxes.volumesBox.put('v_a1', {
        'id': 'v_a1',
        'seriesId': 's_a',
        'volumeNumber': 1.0,
        'isOwned': true,
        'availability': 'available',
      });

      // 2. Incoming JSON with Series A (Volume 2) and Series B (Volume 1)
      final incomingData = {
        'version': '2.0.0',
        'series': [
          {
            'id': 's_incoming_a',
            'title': 'Frieren',
            'type': 'manga',
            'collectionStatus': 'active',
            'tags': ['Adventure'],
            'customMetadata': {'author': 'Kanehito Yamada'},
          },
          {
            'id': 's_incoming_b',
            'title': 'Dungeon Meshi',
            'type': 'manga',
            'collectionStatus': 'active',
            'tags': ['Cooking'],
          },
        ],
        'volumes': [
          {
            'id': 'v_incoming_a2',
            'seriesId': 's_incoming_a',
            'volumeNumber': 2.0,
            'isOwned': false,
            'availability': 'available',
          },
          {
            'id': 'v_incoming_b1',
            'seriesId': 's_incoming_b',
            'volumeNumber': 1.0,
            'isOwned': true,
            'availability': 'available',
          },
        ],
        'transactions': [],
        'ruleConfig': {'id': 'global_config', 'bonusMonths': [12]},
        'rules': [],
      };

      final jsonStr = jsonEncode(incomingData);
      final res = await UniversalImporter.restoreFromJson(jsonStr, mode: RestoreMode.mergeAndKeepNewest);

      expect(res.success, true);
      expect(res.seriesCount, 1); // 1 new series added (Dungeon Meshi), Frieren merged
      expect(res.volumesCount, 2); // 2 new volumes added

      // Verify merged Frieren has both tags and merged custom metadata
      final frierenMap = HiveBoxes.seriesBox.get('s_a')!;
      expect(frierenMap['tags'], containsAll(['Fantasy', 'Adventure']));
      expect(frierenMap['customMetadata']['rating'], 10);
      expect(frierenMap['customMetadata']['author'], 'Kanehito Yamada');

      // Verify Dungeon Meshi exists
      expect(HiveBoxes.seriesBox.values.any((s) => s['title'] == 'Dungeon Meshi'), true);

      // Verify Frieren has both Vol 1 and Vol 2
      final frierenVolumes = HiveBoxes.volumesBox.values.where((v) => v['seriesId'] == 's_a').toList();
      expect(frierenVolumes.length, 2);
    });
  });
}
