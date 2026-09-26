import '../../services/universal_exporter.dart';
import '../../services/universal_importer.dart';
import '../../services/profile_service.dart';
import 'hive_boxes.dart';
import '../../models/rule_config.dart';

class JsonBackupService {
  /// Lossless export across all profiles and workspaces
  static Future<String> exportToJson() async {
    return UniversalExporter.exportFullAppStateToJson(indent: true);
  }

  /// Lossless restore handling both v2 multi-workspace and v1 legacy formats
  static Future<bool> importFromJson(String jsonString) async {
    final result = await UniversalImporter.restoreFromJson(
      jsonString,
      mode: RestoreMode.replaceAll,
    );
    return result.success;
  }

  static Future<void> wipeCompleteDatabase() async {
    for (final p in ProfileService.instance.getAllProfiles()) {
      await HiveBoxes.clearAll(p.id);
    }
    // Delete non-default profiles and switch to default books profile
    final all = ProfileService.instance.getAllProfiles();
    for (final p in all) {
      if (p.id != ProfileService.defaultBooksProfileId) {
        await ProfileService.instance.deleteProfile(p.id);
      }
    }
    await ProfileService.instance.switchProfile(ProfileService.defaultBooksProfileId);
    final defaultConfig = RuleConfig.createDefault();
    await HiveBoxes.ruleConfigBox.put(defaultConfig.id, defaultConfig.toMap());
  }

  static Future<void> clearAllUserData() async {
    for (final p in ProfileService.instance.getAllProfiles()) {
      await HiveBoxes.clearAllUserData(p.id);
    }
  }
}
