import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:canele/core/database/database_migrator.dart';
import 'package:canele/core/database/hive_boxes.dart';
import 'package:canele/models/rule_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('canele_migration_test');
    Hive.init(tempDir.path);

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

    await HiveBoxes.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('DatabaseMigrator upgrades legacy v1 data to v2 properly', () async {
    // 1. Seed legacy v1 data directly into Hive boxes
    final seriesBox = HiveBoxes.seriesBox;
    final rulesBox = HiveBoxes.rulesBox;
    final volumesBox = HiveBoxes.volumesBox;
    final txBox = HiveBoxes.transactionsBox;
    final configBox = HiveBoxes.ruleConfigBox;

    // Reset schema version to 1
    await configBox.put('app_database_schema_version', {'version': 1});

    // Old series with legacy type and tags
    await seriesBox.put('s_old', {
      'id': 's_old',
      'title': 'Legacy Series',
      'type': 'lightNovel',
      'tags': ['isekai', 'fantasy'],
      'releaseStatus': 'ongoing (new volumes releasing)',
      'collectionStatus': 'active',
    });

    // Old rule with deprecated tagBased scope
    await rulesBox.put('r_old', {
      'id': 'r_old',
      'name': 'Old Tag Rule',
      'scopeType': 'tagBased',
      'targetTags': ['isekai'],
      'targetFormat': 'lightNovel',
      'isEnabled': true,
      'priorityOrder': 0,
    });

    // Old volume
    await volumesBox.put('v_old', {
      'id': 'v_old',
      'seriesId': 's_old',
      'volumeNumber': '5.0',
      'releaseDate': '',
      'isOwned': true,
      'availability': 'available',
    });

    // Old transaction with price
    await txBox.put('t_old', {
      'id': 't_old',
      'volumeId': 'v_old',
      'price': 14.99,
      'quotaBucket': 'REGULAR',
    });

    // 2. Run Migrations
    await DatabaseMigrator.runMigrations();

    // 3. Verify Migrated Series
    final migratedSeries = seriesBox.get('s_old')!;
    expect(migratedSeries['tags'], isEmpty);
    expect(migratedSeries['type'], 'lightNovel');
    expect(migratedSeries['releaseStatus'], 'ongoing');

    // 4. Verify Migrated Rule
    final migratedRule = rulesBox.get('r_old')!;
    expect(migratedRule['scopeType'], 'allSeries');
    expect(migratedRule['targetTags'], isEmpty);

    // 5. Verify Migrated Volume
    final migratedVol = volumesBox.get('v_old')!;
    expect(migratedVol['volumeNumber'], 5.0);
    expect(migratedVol['releaseDate'], isNull);

    // 6. Verify Migrated Transaction
    final migratedTx = txBox.get('t_old')!;
    expect(migratedTx['price'], 14.99);
    expect(migratedTx['quotaBucket'], 'regular');

    // 7. Verify Schema Version
    final ver = configBox.get('app_database_schema_version');
    expect((ver as Map)['version'], DatabaseMigrator.currentSchemaVersion);
  });
}
