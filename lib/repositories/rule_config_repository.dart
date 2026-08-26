import '../core/database/hive_boxes.dart';
import '../models/rule_config.dart';

class RuleConfigRepository {
  RuleConfig getConfig() {
    try {
      final map = HiveBoxes.ruleConfigBox.get('global_config');
      if (map == null) {
        return RuleConfig.createDefault();
      }
      return RuleConfig.fromMap(map);
    } catch (_) {
      return RuleConfig.createDefault();
    }
  }

  Future<void> saveConfig(RuleConfig config) async {
    try {
      await HiveBoxes.ruleConfigBox.put(config.id, config.toMap());
    } catch (_) {}
  }
}
