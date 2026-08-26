import '../core/database/hive_boxes.dart';
import '../models/purchase_transaction.dart';

class TransactionRepository {
  List<PurchaseTransaction> getAll() {
    return HiveBoxes.transactionsBox.values
        .map((map) => PurchaseTransaction.fromMap(map))
        .toList()
      ..sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));
  }

  PurchaseTransaction? getById(String id) {
    final map = HiveBoxes.transactionsBox.get(id);
    if (map == null) return null;
    return PurchaseTransaction.fromMap(map);
  }

  PurchaseTransaction? getByVolumeId(String volumeId) {
    for (final map in HiveBoxes.transactionsBox.values) {
      final t = PurchaseTransaction.fromMap(map);
      if (t.volumeId == volumeId) return t;
    }
    return null;
  }

  Future<void> save(PurchaseTransaction transaction) async {
    await HiveBoxes.transactionsBox.put(transaction.id, transaction.toMap());
  }

  Future<void> delete(String id) async {
    await HiveBoxes.transactionsBox.delete(id);
  }

  Future<void> deleteByVolumeId(String volumeId) async {
    final toDelete = <String>[];
    for (final map in HiveBoxes.transactionsBox.values) {
      final t = PurchaseTransaction.fromMap(map);
      if (t.volumeId == volumeId) {
        toDelete.add(t.id);
      }
    }
    for (final id in toDelete) {
      await HiveBoxes.transactionsBox.delete(id);
    }
  }
}
