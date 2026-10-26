import '../../../core/database/hive_boxes.dart';
import '../../../services/profile_service.dart';
import '../../../services/universal_importer.dart';
import '../models/game_space_backup.dart';

class GameRestoreResult {
  final bool success;
  final int franchisesCount;
  final int gamesCount;
  final int rulesCount;
  final int transactionsCount;
  final String? errorMessage;

  const GameRestoreResult({
    required this.success,
    this.franchisesCount = 0,
    this.gamesCount = 0,
    this.rulesCount = 0,
    this.transactionsCount = 0,
    this.errorMessage,
  });
}

class GameSpaceImporter {
  /// Restores a Games workspace from a decoded JSON map or GameSpaceBackup object.
  static Future<GameRestoreResult> restoreFromJson({
    required String profileId,
    required Map<String, dynamic> data,
    required RestoreMode mode,
  }) async {
    try {
      final backup = GameSpaceBackup.fromMap(data);

      await HiveBoxes.preOpenBoxesForProfile(profileId);
      final sBox = HiveBoxes.getSeriesBox(profileId);
      final vBox = HiveBoxes.getVolumesBox(profileId);
      final tBox = HiveBoxes.getTransactionsBox(profileId);
      final cBox = HiveBoxes.getRuleConfigBox(profileId);
      final rBox = HiveBoxes.getRulesBox(profileId);

      if (mode == RestoreMode.replaceAll) {
        await sBox.clear();
        await vBox.clear();
        await tBox.clear();
        await cBox.clear();
        await rBox.clear();

        // 1. Franchises
        for (final f in backup.franchises) {
          await sBox.put(f.id, f.toMap());
        }

        // 2. Games & DLCs
        for (final g in backup.games) {
          await vBox.put(g.id, g.toMap());
        }

        // 3. Rules
        for (final r in backup.rules) {
          await rBox.put(r.id, r.toMap());
        }

        // 4. RuleConfig
        await cBox.put(backup.ruleConfig.id, backup.ruleConfig.toMap());

        // 5. Transactions
        for (final t in backup.transactions) {
          await tBox.put(t.id, t.toMap());
        }

        // 6. Update Profile metadata if present in backup
        if (backup.profile.id.isNotEmpty) {
          final currentProfile = ProfileService.instance.getProfileById(profileId);
          if (currentProfile != null) {
            final updated = currentProfile.copyWith(
              name: backup.profile.name.isNotEmpty ? backup.profile.name : currentProfile.name,
              icon: backup.profile.icon.isNotEmpty ? backup.profile.icon : currentProfile.icon,
            );
            await ProfileService.instance.updateProfile(updated);
          }
        }

        return GameRestoreResult(
          success: true,
          franchisesCount: backup.franchises.length,
          gamesCount: backup.games.length,
          rulesCount: backup.rules.length,
          transactionsCount: backup.transactions.length,
        );
      } else {
        // Merge & Keep Newest
        int addedFranchises = 0;
        for (final f in backup.franchises) {
          if (!sBox.containsKey(f.id)) {
            await sBox.put(f.id, f.toMap());
            addedFranchises++;
          }
        }

        int addedGames = 0;
        for (final g in backup.games) {
          if (!vBox.containsKey(g.id)) {
            await vBox.put(g.id, g.toMap());
            addedGames++;
          }
        }

        int addedRules = 0;
        for (final r in backup.rules) {
          if (!rBox.containsKey(r.id)) {
            await rBox.put(r.id, r.toMap());
            addedRules++;
          }
        }

        int addedTxs = 0;
        for (final t in backup.transactions) {
          if (!tBox.containsKey(t.id)) {
            await tBox.put(t.id, t.toMap());
            addedTxs++;
          }
        }

        return GameRestoreResult(
          success: true,
          franchisesCount: addedFranchises,
          gamesCount: addedGames,
          rulesCount: addedRules,
          transactionsCount: addedTxs,
        );
      }
    } catch (e) {
      return GameRestoreResult(
        success: false,
        errorMessage: 'Games restore failed: $e',
      );
    }
  }
}
