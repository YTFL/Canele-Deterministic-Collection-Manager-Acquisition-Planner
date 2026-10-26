import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/hive_boxes.dart';
import '../../../providers/profile_provider.dart';
import '../models/game_item.dart';
import '../models/game_rule.dart';
import '../models/game_series.dart';
import '../services/game_rule_evaluator.dart';

// --- Game Series Provider ---

class GameSeriesNotifier extends StateNotifier<List<GameSeries>> {
  final String profileId;

  GameSeriesNotifier(this.profileId) : super([]) {
    _load();
  }

  void _load() {
    try {
      final box = HiveBoxes.getSeriesBox(profileId);
      final list = <GameSeries>[];
      for (final key in box.keys) {
        final val = box.get(key);
        if (val != null) {
          list.add(GameSeries.fromMap(val));
        }
      }
      list.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      state = list;
    } catch (_) {
      state = [];
    }
  }

  Future<void> saveSeries(GameSeries series) async {
    try {
      final box = HiveBoxes.getSeriesBox(profileId);
      await box.put(series.id, series.toMap());
      final updated = List<GameSeries>.from(state);
      final idx = updated.indexWhere((s) => s.id == series.id);
      if (idx >= 0) {
        updated[idx] = series;
      } else {
        updated.add(series);
      }
      updated.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      state = updated;
    } catch (_) {}
  }

  Future<void> deleteSeries(String id) async {
    try {
      final box = HiveBoxes.getSeriesBox(profileId);
      await box.delete(id);
      state = state.where((s) => s.id != id).toList();
    } catch (_) {}
  }

  Future<void> markCompleted(String id) async {
    final s = state.cast<GameSeries?>().firstWhere((el) => el?.id == id, orElse: () => null);
    if (s != null) {
      await saveSeries(s.copyWith(collectionStatus: 'completed'));
    }
  }
}

final gameSeriesNotifierProvider =
    StateNotifierProvider<GameSeriesNotifier, List<GameSeries>>((ref) {
  final activeProfile = ref.watch(profileNotifierProvider).activeProfile;
  return GameSeriesNotifier(activeProfile.id);
});

// --- Game Items Provider ---

class GameItemsNotifier extends StateNotifier<List<GameItem>> {
  final String profileId;

  GameItemsNotifier(this.profileId) : super([]) {
    _load();
  }

  void _load() {
    try {
      final box = HiveBoxes.getVolumesBox(profileId);
      final list = <GameItem>[];
      for (final key in box.keys) {
        final val = box.get(key);
        if (val != null) {
          list.add(GameItem.fromMap(val));
        }
      }
      list.sort((a, b) => a.gameNumber.compareTo(b.gameNumber));
      state = list;
    } catch (_) {
      state = [];
    }
  }

  Future<void> saveItem(GameItem item) async {
    try {
      final box = HiveBoxes.getVolumesBox(profileId);
      await box.put(item.id, item.toMap());
      final updated = List<GameItem>.from(state);
      final idx = updated.indexWhere((i) => i.id == item.id);
      if (idx >= 0) {
        updated[idx] = item;
      } else {
        updated.add(item);
      }
      updated.sort((a, b) => a.gameNumber.compareTo(b.gameNumber));
      state = updated;
    } catch (_) {}
  }

  Future<void> deleteItem(String id) async {
    try {
      final box = HiveBoxes.getVolumesBox(profileId);
      await box.delete(id);
      state = state.where((i) => i.id != id).toList();
    } catch (_) {}
  }

  Future<void> toggleOwned(String id, bool isOwned, {bool? isGift}) async {
    final item = state.cast<GameItem?>().firstWhere((el) => el?.id == id, orElse: () => null);
    if (item != null) {
      await saveItem(item.copyWith(
        isOwned: isOwned,
        isGift: isGift ?? (isOwned ? item.isGift : false),
      ));
    }
  }

  Future<void> togglePriorityTarget(String id, bool isPriority) async {
    final item = state.cast<GameItem?>().firstWhere((el) => el?.id == id, orElse: () => null);
    if (item != null) {
      await saveItem(item.copyWith(isPriorityTarget: isPriority));
    }
  }
}

final gameItemsNotifierProvider =
    StateNotifierProvider<GameItemsNotifier, List<GameItem>>((ref) {
  final activeProfile = ref.watch(profileNotifierProvider).activeProfile;
  return GameItemsNotifier(activeProfile.id);
});

// --- Game Rules Provider ---

class GameRulesNotifier extends StateNotifier<List<GameRule>> {
  final String profileId;

  GameRulesNotifier(this.profileId) : super([]) {
    _load();
  }

  void _load() {
    try {
      final box = HiveBoxes.getRulesBox(profileId);
      final list = <GameRule>[];
      for (final key in box.keys) {
        final val = box.get(key);
        if (val != null) {
          list.add(GameRule.fromMap(val));
        }
      }
      list.sort((a, b) => a.priorityOrder.compareTo(b.priorityOrder));
      state = list;
    } catch (_) {
      state = [];
    }
  }

  Future<void> saveRule(GameRule rule) async {
    try {
      final box = HiveBoxes.getRulesBox(profileId);
      await box.put(rule.id, rule.toMap());
      final updated = List<GameRule>.from(state);
      final idx = updated.indexWhere((r) => r.id == rule.id);
      if (idx >= 0) {
        updated[idx] = rule;
      } else {
        updated.add(rule);
      }
      updated.sort((a, b) => a.priorityOrder.compareTo(b.priorityOrder));
      state = updated;
    } catch (_) {}
  }

  Future<void> deleteRule(String id) async {
    try {
      final box = HiveBoxes.getRulesBox(profileId);
      await box.delete(id);
      state = state.where((r) => r.id != id).toList();
    } catch (_) {}
  }

  Future<void> toggleRule(String id, bool isEnabled) async {
    final rule = state.cast<GameRule?>().firstWhere((el) => el?.id == id, orElse: () => null);
    if (rule != null) {
      await saveRule(rule.copyWith(isEnabled: isEnabled));
    }
  }

  Future<void> reorderRules(int oldIndex, int newIndex) async {
    final list = List<GameRule>.from(state);
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);

    final box = HiveBoxes.getRulesBox(profileId);
    for (int i = 0; i < list.length; i++) {
      list[i] = list[i].copyWith(priorityOrder: i);
      await box.put(list[i].id, list[i].toMap());
    }
    state = list;
  }

  Future<void> loadDefaultRules() async {
    final box = HiveBoxes.getRulesBox(profileId);
    await box.clear();
    final defaults = GameRule.defaultRules();
    for (int i = 0; i < defaults.length; i++) {
      final r = defaults[i].copyWith(priorityOrder: i);
      await box.put(r.id, r.toMap());
    }
    state = defaults;
  }
}

final gameRulesNotifierProvider =
    StateNotifierProvider<GameRulesNotifier, List<GameRule>>((ref) {
  final activeProfile = ref.watch(profileNotifierProvider).activeProfile;
  return GameRulesNotifier(activeProfile.id);
});

// --- Game Recommendation Slots Provider ---

final gameRecommendationSlotsProvider = Provider<List<GameRecommendationSlot>>((ref) {
  final rules = ref.watch(gameRulesNotifierProvider);
  final series = ref.watch(gameSeriesNotifierProvider);
  final items = ref.watch(gameItemsNotifierProvider);

  return GameRuleEvaluator.evaluate(
    rules: rules,
    seriesList: series,
    itemsList: items,
    maxSlots: 4,
  );
});
