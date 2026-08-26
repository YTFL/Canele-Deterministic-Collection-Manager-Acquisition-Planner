import '../core/database/hive_boxes.dart';
import '../models/series.dart';

class SeriesRepository {
  List<Series> getAll() {
    return HiveBoxes.seriesBox.values
        .map((map) => Series.fromMap(map))
        .toList();
  }

  Series? getById(String id) {
    final map = HiveBoxes.seriesBox.get(id);
    if (map == null) return null;
    return Series.fromMap(map);
  }

  Future<void> save(Series series) async {
    await HiveBoxes.seriesBox.put(series.id, series.toMap());
  }

  Future<void> delete(String id) async {
    await HiveBoxes.seriesBox.delete(id);
  }
}
