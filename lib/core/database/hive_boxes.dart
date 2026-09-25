import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/rule_config.dart';
import '../../models/rule_model.dart';
import '../../services/profile_service.dart';
import 'database_migrator.dart';

class HiveBoxes {
  // Legacy un-scoped box names for migration
  static const String legacySeriesBoxName = 'series_box';
  static const String legacyVolumesBoxName = 'volumes_box';
  static const String legacyTransactionsBoxName = 'transactions_box';
  static const String legacyRuleConfigBoxName = 'rule_config_box';
  static const String legacyRulesBoxName = 'rules_box';

  // Global / un-scoped boxes
  static const String appUpdatesBoxName = 'app_updates_box';
  static Box<Map>? _appUpdatesBox;
  static Box<Map> get appUpdatesBox => _appUpdatesBox!;

  // Scoped box cache: boxName -> Box<Map>
  static final Map<String, Box<Map>> _scopedBoxes = {};

  static String _resolveProfileId(String? profileId) {
    if (profileId != null && profileId.isNotEmpty) {
      return profileId;
    }
    try {
      final active = ProfileService.instance.activeProfileId;
      if (active.isNotEmpty) return active;
    } catch (_) {}
    return ProfileService.defaultBooksProfileId;
  }

  static String getSeriesBoxName([String? profileId]) =>
      '${_resolveProfileId(profileId)}_series';

  static String getVolumesBoxName([String? profileId]) =>
      '${_resolveProfileId(profileId)}_volumes';

  static String getTransactionsBoxName([String? profileId]) =>
      '${_resolveProfileId(profileId)}_transactions';

  static String getRuleConfigBoxName([String? profileId]) =>
      '${_resolveProfileId(profileId)}_rule_config';

  static String get ruleConfigBoxName => getRuleConfigBoxName();

  static String getRulesBoxName([String? profileId]) =>
      '${_resolveProfileId(profileId)}_rules';

  /// Synchronously or cached retrieves a scoped box.
  /// If already opened in Hive, returns it; otherwise opens it.
  static Box<Map> _getOrOpenBoxSync(String boxName) {
    if (_scopedBoxes.containsKey(boxName) && _scopedBoxes[boxName]!.isOpen) {
      return _scopedBoxes[boxName]!;
    }
    if (Hive.isBoxOpen(boxName)) {
      final box = Hive.box<Map>(boxName);
      _scopedBoxes[boxName] = box;
      return box;
    }
    // Fallback if not yet cached but Hive is initialized
    debugPrint('[HiveBoxes] Warning: Box $boxName was accessed synchronously before pre-opening. Opening synchronously via Hive.');
    // In Hive 2, Hive.box throws if not open. Let caller ensure preOpenBoxesForProfile was run.
    return Hive.box<Map>(boxName);
  }

  /// Pre-opens all scoped boxes for a given profile ID.
  static Future<void> preOpenBoxesForProfile(String profileId) async {
    final sName = getSeriesBoxName(profileId);
    final vName = getVolumesBoxName(profileId);
    final tName = getTransactionsBoxName(profileId);
    final cName = getRuleConfigBoxName(profileId);
    final rName = getRulesBoxName(profileId);

    _scopedBoxes[sName] = await Hive.openBox<Map>(sName);
    _scopedBoxes[vName] = await Hive.openBox<Map>(vName);
    _scopedBoxes[tName] = await Hive.openBox<Map>(tName);
    _scopedBoxes[cName] = await Hive.openBox<Map>(cName);
    _scopedBoxes[rName] = await Hive.openBox<Map>(rName);

    // Seed default RuleConfig if empty
    final configBox = _scopedBoxes[cName]!;
    if (configBox.isEmpty) {
      final defaultConfig = RuleConfig.createDefault();
      await configBox.put(defaultConfig.id, defaultConfig.toMap());
    }
  }

  static Box<Map> getSeriesBox([String? profileId]) =>
      _getOrOpenBoxSync(getSeriesBoxName(profileId));

  static Box<Map> getVolumesBox([String? profileId]) =>
      _getOrOpenBoxSync(getVolumesBoxName(profileId));

  static Box<Map> getTransactionsBox([String? profileId]) =>
      _getOrOpenBoxSync(getTransactionsBoxName(profileId));

  static Box<Map> getRuleConfigBox([String? profileId]) =>
      _getOrOpenBoxSync(getRuleConfigBoxName(profileId));

  static Box<Map> getRulesBox([String? profileId]) =>
      _getOrOpenBoxSync(getRulesBoxName(profileId));

  // Dynamic getters resolving dynamically to active profile
  static Box<Map> get seriesBox => getSeriesBox();
  static Box<Map> get volumesBox => getVolumesBox();
  static Box<Map> get transactionsBox => getTransactionsBox();
  static Box<Map> get ruleConfigBox => getRuleConfigBox();
  static Box<Map> get rulesBox => getRulesBox();
  static Box<Map> get passesBox => getRulesBox(); // Alias

  static Future<void> init([String? path]) async {
    if (path != null) {
      Hive.init(path);
    } else {
      await Hive.initFlutter();
    }

    // Register TypeAdapters
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

    // Clear in-memory cache to ensure fresh handles when re-initializing
    _scopedBoxes.clear();

    // Open global updates box
    _appUpdatesBox = await Hive.openBox<Map>(appUpdatesBoxName);

    // Initialize ProfileService (creates default profile and resolves active profile ID)
    await ProfileService.instance.init();

    // Pre-open boxes for the active profile
    await preOpenBoxesForProfile(ProfileService.instance.activeProfileId);

    // Run database schema migrations for the active profile
    await DatabaseMigrator.runMigrations(ProfileService.instance.activeProfileId);
  }

  static void resetBoxCache() {
    _scopedBoxes.clear();
  }

  static Future<void> clearAll([String? profileId]) async {
    final pId = _resolveProfileId(profileId);
    await getSeriesBox(pId).clear();
    await getVolumesBox(pId).clear();
    await getTransactionsBox(pId).clear();
    await getRuleConfigBox(pId).clear();
    await getRulesBox(pId).clear();
  }

  static Future<void> clearAllUserData([String? profileId]) async {
    final pId = _resolveProfileId(profileId);
    await getSeriesBox(pId).clear();
    await getVolumesBox(pId).clear();
    await getTransactionsBox(pId).clear();
  }
}
