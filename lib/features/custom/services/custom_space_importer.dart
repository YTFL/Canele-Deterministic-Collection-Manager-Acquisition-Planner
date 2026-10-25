import '../../../core/database/hive_boxes.dart';
import '../../../models/custom_item.dart';
import '../../../models/purchase_transaction.dart';
import '../../../services/profile_service.dart';
import '../../../services/universal_importer.dart';
import '../models/custom_space_backup.dart';

class CustomRestoreResult {
  final bool success;
  final int itemsCount;
  final int transactionsCount;
  final String? errorMessage;

  const CustomRestoreResult({
    required this.success,
    this.itemsCount = 0,
    this.transactionsCount = 0,
    this.errorMessage,
  });
}

class CustomSpaceImporter {
  /// Restores a Custom workspace from a decoded JSON map or CustomSpaceBackup object.
  static Future<CustomRestoreResult> restoreFromJson({
    required String profileId,
    required Map<String, dynamic> data,
    required RestoreMode mode,
  }) async {
    try {
      final backup = CustomSpaceBackup.fromMap(data);

      await HiveBoxes.preOpenBoxesForProfile(profileId);
      final sBox = HiveBoxes.getSeriesBox(profileId);
      final tBox = HiveBoxes.getTransactionsBox(profileId);
      final cBox = HiveBoxes.getRuleConfigBox(profileId);

      if (mode == RestoreMode.replaceAll) {
        await sBox.clear();
        await tBox.clear();
        await cBox.clear();

        // 1. Items (store as Series entities via toSeries for compatibility with Hive storage)
        for (final item in backup.items) {
          final seriesEntity = item.toSeries();
          await sBox.put(seriesEntity.id, seriesEntity.toMap());
        }

        // 2. RuleConfig
        await cBox.put(backup.ruleConfig.id, backup.ruleConfig.toMap());

        // 3. Transactions
        for (final t in backup.transactions) {
          await tBox.put(t.id, t.toMap());
        }

        // 4. Update Profile & Schema
        if (backup.profile.id.isNotEmpty) {
          final currentProfile = ProfileService.instance.getProfileById(profileId);
          if (currentProfile != null) {
            final updated = currentProfile.copyWith(
              name: backup.profile.name.isNotEmpty ? backup.profile.name : currentProfile.name,
              icon: backup.profile.icon.isNotEmpty ? backup.profile.icon : currentProfile.icon,
              customSchema: backup.profile.customSchema ?? currentProfile.customSchema,
            );
            await ProfileService.instance.updateProfile(updated);
          }
        }

        return CustomRestoreResult(
          success: true,
          itemsCount: backup.items.length,
          transactionsCount: backup.transactions.length,
        );
      } else {
        // Merge & Keep Newest
        int addedItems = 0;
        for (final item in backup.items) {
          if (!sBox.containsKey(item.id)) {
            final seriesEntity = item.toSeries();
            await sBox.put(seriesEntity.id, seriesEntity.toMap());
            addedItems++;
          }
        }

        int addedTxs = 0;
        for (final t in backup.transactions) {
          if (!tBox.containsKey(t.id)) {
            await tBox.put(t.id, t.toMap());
            addedTxs++;
          }
        }

        return CustomRestoreResult(
          success: true,
          itemsCount: addedItems,
          transactionsCount: addedTxs,
        );
      }
    } catch (e) {
      return CustomRestoreResult(
        success: false,
        errorMessage: 'Custom space restore failed: $e',
      );
    }
  }
}
