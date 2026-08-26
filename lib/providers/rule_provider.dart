import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/rule_model.dart';
import 'database_provider.dart';

class RulesNotifier extends StateNotifier<List<RuleModel>> {
  final Ref _ref;

  RulesNotifier(this._ref) : super([]) {
    load();
  }

  void load() {
    state = _ref.read(ruleRepositoryProvider).getRules();
  }

  Future<void> saveRule(RuleModel rule) async {
    // If new rule and priorityOrder not set, place at end
    RuleModel toSave = rule;
    final exists = state.any((r) => r.id == rule.id);
    if (!exists) {
      toSave = rule.copyWith(priorityOrder: state.length);
    }

    await _ref.read(ruleRepositoryProvider).saveRule(toSave);
    load();
  }

  Future<void> deleteRule(String id) async {
    await _ref.read(ruleRepositoryProvider).deleteRule(id);
    // Re-index remaining rules
    final remaining = state.where((r) => r.id != id).toList();
    await _ref.read(ruleRepositoryProvider).saveAll(remaining);
    load();
  }

  Future<void> toggleRule(String id, bool isEnabled) async {
    final index = state.indexWhere((r) => r.id == id);
    if (index != -1) {
      final updated = state[index].copyWith(isEnabled: isEnabled);
      await _ref.read(ruleRepositoryProvider).saveRule(updated);
      load();
    }
  }

  Future<void> reorderRules(int oldIndex, int newIndex) async {
    final list = List<RuleModel>.from(state);
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);

    // Update priorities
    final updatedList = <RuleModel>[];
    for (int i = 0; i < list.length; i++) {
      updatedList.add(list[i].copyWith(priorityOrder: i));
    }

    state = updatedList;
    await _ref.read(ruleRepositoryProvider).saveAll(updatedList);
  }
}

final rulesNotifierProvider = StateNotifierProvider<RulesNotifier, List<RuleModel>>((ref) {
  return RulesNotifier(ref);
});
