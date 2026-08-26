import '../core/database/hive_boxes.dart';
import '../models/volume.dart';

class VolumeRepository {
  List<Volume> getAll() {
    final validSeriesIds = HiveBoxes.seriesBox.values
        .map((m) => m['id'] as String?)
        .where((id) => id != null && id.isNotEmpty)
        .toSet();

    return HiveBoxes.volumesBox.values
        .where((map) {
          final seriesId = map['seriesId'] as String?;
          return seriesId != null && validSeriesIds.contains(seriesId);
        })
        .map((map) => Volume.fromMap(map))
        .toList();
  }

  List<Volume> getBySeriesId(String seriesId) {
    return getAll()
        .where((v) => v.seriesId == seriesId)
        .toList()
      ..sort((a, b) => a.volumeNumber.compareTo(b.volumeNumber));
  }

  Volume? getById(String id) {
    final map = HiveBoxes.volumesBox.get(id);
    if (map == null) return null;
    return Volume.fromMap(map);
  }

  Future<void> save(Volume volume) async {
    await HiveBoxes.volumesBox.put(volume.id, volume.toMap());
  }

  Future<void> saveBatch(List<Volume> volumes) async {
    final entries = {for (final v in volumes) v.id: v.toMap()};
    await HiveBoxes.volumesBox.putAll(entries);
  }

  Future<void> delete(String id) async {
    await HiveBoxes.volumesBox.delete(id);
  }

  Future<void> deleteBySeriesId(String seriesId) async {
    final volumes = getBySeriesId(seriesId);
    final volumeIds = volumes.map((v) => v.id).toList();
    for (final v in volumes) {
      await HiveBoxes.volumesBox.delete(v.id);
    }
    // Also remove associated purchase transactions
    final txMaps = Map<dynamic, dynamic>.from(HiveBoxes.transactionsBox.toMap());
    final txToDelete = <dynamic>[];
    for (final entry in txMaps.entries) {
      final txMap = entry.value as Map?;
      final volId = txMap?['volumeId'] as String?;
      if (volId != null && volumeIds.contains(volId)) {
        txToDelete.add(entry.key);
      }
    }
    if (txToDelete.isNotEmpty) {
      await HiveBoxes.transactionsBox.deleteAll(txToDelete);
    }
  }

  /// Deletes all orphan volumes that have no parent series and cleans up their transactions.
  Future<int> cleanupOrphanVolumes() async {
    final validSeriesIds = HiveBoxes.seriesBox.values
        .map((m) => m['id'] as String?)
        .where((id) => id != null && id.isNotEmpty)
        .toSet();

    final allVolumeMaps = Map<dynamic, dynamic>.from(HiveBoxes.volumesBox.toMap());
    final orphanVolumeIds = <dynamic>[];

    for (final entry in allVolumeMaps.entries) {
      final map = entry.value as Map?;
      final seriesId = map?['seriesId'] as String?;
      if (seriesId == null || !validSeriesIds.contains(seriesId)) {
        orphanVolumeIds.add(entry.key);
      }
    }

    if (orphanVolumeIds.isNotEmpty) {
      await HiveBoxes.volumesBox.deleteAll(orphanVolumeIds);

      // Clean orphan transactions
      final txMaps = Map<dynamic, dynamic>.from(HiveBoxes.transactionsBox.toMap());
      final orphanTxKeys = <dynamic>[];
      for (final entry in txMaps.entries) {
        final txMap = entry.value as Map?;
        final volId = txMap?['volumeId'] as String?;
        if (volId == null || orphanVolumeIds.contains(volId)) {
          orphanTxKeys.add(entry.key);
        }
      }
      if (orphanTxKeys.isNotEmpty) {
        await HiveBoxes.transactionsBox.deleteAll(orphanTxKeys);
      }
    }

    return orphanVolumeIds.length;
  }
}
