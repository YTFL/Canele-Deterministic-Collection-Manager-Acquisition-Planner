import 'package:hive_flutter/hive_flutter.dart';
import '../../models/rule_config.dart';
import '../../models/rule_model.dart';
import 'database_migrator.dart';

class HiveBoxes {
  static const String seriesBoxName = 'series_box';
  static const String volumesBoxName = 'volumes_box';
  static const String transactionsBoxName = 'transactions_box';
  static const String ruleConfigBoxName = 'rule_config_box';
  static const String rulesBoxName = 'rules_box';
  static const String passesBoxName = 'passes_box'; // backward-compatible alias

  static Box<Map>? _seriesBox;
  static Box<Map>? _volumesBox;
  static Box<Map>? _transactionsBox;
  static Box<Map>? _ruleConfigBox;
  static Box<Map>? _rulesBox;

  static Box<Map> get seriesBox => _seriesBox!;
  static Box<Map> get volumesBox => _volumesBox!;
  static Box<Map> get transactionsBox => _transactionsBox!;
  static Box<Map> get ruleConfigBox => _ruleConfigBox!;
  static Box<Map> get rulesBox => _rulesBox!;
  static Box<Map> get passesBox => _rulesBox!; // Alias for rules box

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

    _seriesBox = await Hive.openBox<Map>(seriesBoxName);
    _volumesBox = await Hive.openBox<Map>(volumesBoxName);
    _transactionsBox = await Hive.openBox<Map>(transactionsBoxName);
    _ruleConfigBox = await Hive.openBox<Map>(ruleConfigBoxName);
    _rulesBox = await Hive.openBox<Map>(rulesBoxName);

    // Seed default RuleConfig if empty
    if (_ruleConfigBox!.isEmpty) {
      final defaultConfig = RuleConfig.createDefault();
      await _ruleConfigBox!.put(defaultConfig.id, defaultConfig.toMap());
    }

    // Run database migrations for existing data
    await DatabaseMigrator.runMigrations();
  }

  static Future<void> clearAll() async {
    await _seriesBox?.clear();
    await _volumesBox?.clear();
    await _transactionsBox?.clear();
    await _ruleConfigBox?.clear();
    await _rulesBox?.clear();
  }
}
