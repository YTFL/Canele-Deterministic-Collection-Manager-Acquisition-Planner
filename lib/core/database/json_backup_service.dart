import 'dart:convert';
import 'hive_boxes.dart';
import '../../models/series.dart';
import '../../models/volume.dart';
import '../../models/purchase_transaction.dart';
import '../../models/rule_config.dart';
import '../../models/recommendation_pass.dart';

class JsonBackupService {
  static Future<String> exportToJson() async {
    final series = HiveBoxes.seriesBox.values.toList();
    final volumes = HiveBoxes.volumesBox.values.toList();
    final transactions = HiveBoxes.transactionsBox.values.toList();
    final ruleConfig = HiveBoxes.ruleConfigBox.get('global_config') ?? RuleConfig.createDefault().toMap();
    final passes = HiveBoxes.passesBox.values.toList();

    final data = {
      'version': '1.0.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'series': series,
      'volumes': volumes,
      'transactions': transactions,
      'ruleConfig': ruleConfig,
      'passes': passes,
    };

    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(data);
  }

  static Future<bool> importFromJson(String jsonString) async {
    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      
      await HiveBoxes.clearAll();

      if (data.containsKey('series') && data['series'] is List) {
        for (final item in data['series'] as List) {
          final s = Series.fromMap(item as Map);
          await HiveBoxes.seriesBox.put(s.id, s.toMap());
        }
      }

      if (data.containsKey('volumes') && data['volumes'] is List) {
        for (final item in data['volumes'] as List) {
          final v = Volume.fromMap(item as Map);
          await HiveBoxes.volumesBox.put(v.id, v.toMap());
        }
      }

      if (data.containsKey('transactions') && data['transactions'] is List) {
        for (final item in data['transactions'] as List) {
          final t = PurchaseTransaction.fromMap(item as Map);
          await HiveBoxes.transactionsBox.put(t.id, t.toMap());
        }
      }

      if (data.containsKey('ruleConfig') && data['ruleConfig'] is Map) {
        final r = RuleConfig.fromMap(data['ruleConfig'] as Map);
        await HiveBoxes.ruleConfigBox.put(r.id, r.toMap());
      } else {
        final defaultConfig = RuleConfig.createDefault();
        await HiveBoxes.ruleConfigBox.put(defaultConfig.id, defaultConfig.toMap());
      }

      if (data.containsKey('passes') && data['passes'] is List) {
        for (final item in data['passes'] as List) {
          final p = RecommendationPass.fromMap(item as Map);
          await HiveBoxes.passesBox.put(p.id, p.toMap());
        }
      } else {
        final defaultPasses = RecommendationPass.defaultPasses();
        for (final pass in defaultPasses) {
          await HiveBoxes.passesBox.put(pass.id, pass.toMap());
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<void> wipeCompleteDatabase() async {
    await HiveBoxes.clearAll();
    final defaultConfig = RuleConfig.createDefault();
    await HiveBoxes.ruleConfigBox.put(defaultConfig.id, defaultConfig.toMap());
  }

  static Future<void> clearAllUserData() async {
    await HiveBoxes.seriesBox.clear();
    await HiveBoxes.volumesBox.clear();
    await HiveBoxes.transactionsBox.clear();
  }
}
