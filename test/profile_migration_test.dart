import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:canele/core/database/hive_boxes.dart';
import 'package:canele/models/profile.dart';
import 'package:canele/models/rule_model.dart';
import 'package:canele/services/profile_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('canele_legacy_migration_test');
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
  });

  tearDown(() async {
    await Hive.close();
    HiveBoxes.resetBoxCache();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('Migrates legacy un-scoped boxes to default books workspace with zero loss', () async {
    // 1. Seed legacy v1 un-scoped boxes directly before HiveBoxes.init is called
    final legacySeriesBox = await Hive.openBox<Map>(HiveBoxes.legacySeriesBoxName);
    final legacyVolumesBox = await Hive.openBox<Map>(HiveBoxes.legacyVolumesBoxName);
    final legacyTxBox = await Hive.openBox<Map>(HiveBoxes.legacyTransactionsBoxName);
    final legacyRulesBox = await Hive.openBox<Map>(HiveBoxes.legacyRulesBoxName);
    final legacyConfigBox = await Hive.openBox<Map>(HiveBoxes.legacyRuleConfigBoxName);

    await legacySeriesBox.put('s_legacy_1', {
      'id': 's_legacy_1',
      'title': 'Legacy Series Title',
      'type': 'manga',
      'releaseStatus': 'ongoing',
      'collectionStatus': 'active',
    });

    await legacyVolumesBox.put('v_legacy_1', {
      'id': 'v_legacy_1',
      'seriesId': 's_legacy_1',
      'volumeNumber': 1.0,
      'isOwned': true,
      'availability': 'available',
    });

    await legacyTxBox.put('tx_legacy_1', {
      'id': 'tx_legacy_1',
      'volumeId': 'v_legacy_1',
      'price': 12.99,
      'quotaBucket': 'regular',
      'purchaseDate': DateTime.now().toIso8601String(),
    });

    await legacyRulesBox.put('r_legacy_1', {
      'id': 'r_legacy_1',
      'name': 'Legacy Priority Rule',
      'scopeType': 'allSeries',
      'isEnabled': true,
      'priorityOrder': 0,
    });

    await legacyConfigBox.put('global_config', {
      'id': 'global_config',
      'monthlyBudget': 3,
      'currency': 'USD',
    });

    await legacySeriesBox.close();
    await legacyVolumesBox.close();
    await legacyTxBox.close();
    await legacyRulesBox.close();
    await legacyConfigBox.close();

    // 2. Run HiveBoxes.init() which triggers ProfileService.init and legacy migration
    await HiveBoxes.init(tempDir.path);

    // 3. Verify Default Profile was created
    final profileService = ProfileService.instance;
    expect(profileService.activeProfileId, ProfileService.defaultBooksProfileId);
    expect(profileService.activeProfile.type, ProfileType.books);

    // 4. Verify data was migrated to scoped boxes without loss
    final scopedSeriesBox = HiveBoxes.getSeriesBox(ProfileService.defaultBooksProfileId);
    final scopedVolumesBox = HiveBoxes.getVolumesBox(ProfileService.defaultBooksProfileId);
    final scopedTxBox = HiveBoxes.getTransactionsBox(ProfileService.defaultBooksProfileId);
    final scopedRulesBox = HiveBoxes.getRulesBox(ProfileService.defaultBooksProfileId);
    final scopedConfigBox = HiveBoxes.getRuleConfigBox(ProfileService.defaultBooksProfileId);

    expect(scopedSeriesBox.containsKey('s_legacy_1'), isTrue);
    expect(scopedSeriesBox.get('s_legacy_1')?['title'], 'Legacy Series Title');

    expect(scopedVolumesBox.containsKey('v_legacy_1'), isTrue);
    expect(scopedVolumesBox.get('v_legacy_1')?['volumeNumber'], 1.0);

    expect(scopedTxBox.containsKey('tx_legacy_1'), isTrue);
    expect(scopedTxBox.get('tx_legacy_1')?['price'], 12.99);

    expect(scopedRulesBox.containsKey('r_legacy_1'), isTrue);
    expect(scopedRulesBox.get('r_legacy_1')?['name'], 'Legacy Priority Rule');

    expect(scopedConfigBox.get('legacy_scoping_migrated_v2')?['migrated'], isTrue);
  });
}
