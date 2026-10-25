import 'dart:convert';
import '../../../models/custom_item.dart';
import '../../../models/profile.dart';
import '../../../models/purchase_transaction.dart';
import '../../../models/rule_config.dart';

/// Pure domain backup bundle representing the complete state of a Custom workspace.
class CustomSpaceBackup {
  final String version;
  final String spaceType;
  final DateTime exportedAt;
  final String schemaVersion;
  final Profile profile;
  final List<CustomItem> items;
  final RuleConfig ruleConfig;
  final List<PurchaseTransaction> transactions;

  const CustomSpaceBackup({
    this.version = '2.1.0',
    this.spaceType = 'custom',
    required this.exportedAt,
    this.schemaVersion = '2',
    required this.profile,
    required this.items,
    required this.ruleConfig,
    required this.transactions,
  });

  Map<String, dynamic> toMap() {
    return {
      'version': version,
      'spaceType': spaceType,
      'schemaVersion': schemaVersion,
      'exportedAt': exportedAt.toUtc().toIso8601String(),
      'profile': profile.toMap(),
      'items': items.map((i) => i.toMap()).toList(),
      'ruleConfig': ruleConfig.toMap(),
      'transactions': transactions.map((t) => t.toMap()).toList(),
    };
  }

  factory CustomSpaceBackup.fromMap(Map<dynamic, dynamic> map) {
    final profile = Profile.fromMap(map['profile'] as Map? ?? {});

    final itemsList = <CustomItem>[];
    final rawItems = map['items'] ?? map['series'];
    if (rawItems is List) {
      for (final item in rawItems) {
        if (item is Map) {
          itemsList.add(CustomItem.fromMap(item));
        }
      }
    }

    RuleConfig ruleConfig = RuleConfig.createDefault();
    if (map['ruleConfig'] is Map) {
      ruleConfig = RuleConfig.fromMap(map['ruleConfig'] as Map);
    }

    final transactionsList = <PurchaseTransaction>[];
    if (map['transactions'] is List) {
      for (final item in map['transactions'] as List) {
        if (item is Map) {
          transactionsList.add(PurchaseTransaction.fromMap(item));
        }
      }
    }

    DateTime parsedDate = DateTime.now();
    final dateStr = map['exportedAt']?.toString();
    if (dateStr != null && dateStr.isNotEmpty) {
      parsedDate = DateTime.tryParse(dateStr)?.toLocal() ?? DateTime.now();
    }

    return CustomSpaceBackup(
      version: map['version']?.toString() ?? '2.1.0',
      spaceType: 'custom',
      schemaVersion: map['schemaVersion']?.toString() ?? '2',
      exportedAt: parsedDate,
      profile: profile,
      items: itemsList,
      ruleConfig: ruleConfig,
      transactions: transactionsList,
    );
  }

  String toJson({bool indent = true}) {
    final encoder = indent ? const JsonEncoder.withIndent('  ') : const JsonEncoder();
    return encoder.convert(toMap());
  }

  factory CustomSpaceBackup.fromJson(String jsonStr) {
    final decoded = jsonDecode(jsonStr);
    if (decoded is! Map) {
      throw const FormatException('Invalid CustomSpaceBackup JSON: Root is not an object');
    }
    return CustomSpaceBackup.fromMap(decoded);
  }
}
