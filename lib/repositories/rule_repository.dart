import '../core/database/hive_boxes.dart';
import '../models/rule_model.dart';

class RuleRepository {
  List<RuleModel> getRules() {
    try {
      final box = HiveBoxes.rulesBox;
      final list = <RuleModel>[];
      for (final key in box.keys) {
        final val = box.get(key);
        if (val != null) {
          list.add(RuleModel.fromMap(val));
        }
      }
      list.sort((a, b) => a.priorityOrder.compareTo(b.priorityOrder));
      return list;
    } catch (_) {
      return [];
    }
  }

  Future<void> saveRule(RuleModel rule) async {
    try {
      await HiveBoxes.rulesBox.put(rule.id, rule.toMap());
    } catch (_) {}
  }

  Future<void> deleteRule(String id) async {
    try {
      await HiveBoxes.rulesBox.delete(id);
    } catch (_) {}
  }

  Future<void> saveAll(List<RuleModel> rules) async {
    try {
      for (int i = 0; i < rules.length; i++) {
        final r = rules[i].copyWith(priorityOrder: i);
        await HiveBoxes.rulesBox.put(r.id, r.toMap());
      }
    } catch (_) {}
  }
}
