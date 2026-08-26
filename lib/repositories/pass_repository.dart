import '../core/database/hive_boxes.dart';
import '../models/recommendation_pass.dart';

class PassRepository {
  List<RecommendationPass> getAll() {
    final passes = HiveBoxes.passesBox.values
        .map((map) => RecommendationPass.fromMap(map))
        .toList();
    passes.sort((a, b) => a.order.compareTo(b.order));
    return passes;
  }

  RecommendationPass? getById(String id) {
    final map = HiveBoxes.passesBox.get(id);
    if (map == null) return null;
    return RecommendationPass.fromMap(map);
  }

  Future<void> save(RecommendationPass pass) async {
    await HiveBoxes.passesBox.put(pass.id, pass.toMap());
  }

  Future<void> delete(String id) async {
    await HiveBoxes.passesBox.delete(id);
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    final passes = getAll();
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = passes.removeAt(oldIndex);
    passes.insert(newIndex, item);

    for (int i = 0; i < passes.length; i++) {
      final updated = passes[i].copyWith(order: i);
      await HiveBoxes.passesBox.put(updated.id, updated.toMap());
    }
  }

  Future<void> resetToDefault() async {
    await HiveBoxes.passesBox.clear();
    final defaults = RecommendationPass.defaultPasses();
    for (final pass in defaults) {
      await HiveBoxes.passesBox.put(pass.id, pass.toMap());
    }
  }
}
