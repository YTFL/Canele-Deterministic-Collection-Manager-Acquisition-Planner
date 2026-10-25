import 'dart:convert';
import '../../../models/profile.dart';
import '../../../models/purchase_transaction.dart';
import '../../../models/rule_config.dart';
import 'game_item.dart';
import 'game_rule.dart';
import 'game_series.dart';

/// Pure domain backup bundle representing the complete state of a Games workspace.
class GameSpaceBackup {
  final String version;
  final String spaceType;
  final DateTime exportedAt;
  final String schemaVersion;
  final Profile profile;
  final List<GameSeries> franchises;
  final List<GameItem> games;
  final List<GameRule> rules;
  final RuleConfig ruleConfig;
  final List<PurchaseTransaction> transactions;

  const GameSpaceBackup({
    this.version = '2.1.0',
    this.spaceType = 'games',
    required this.exportedAt,
    this.schemaVersion = '2',
    required this.profile,
    required this.franchises,
    required this.games,
    required this.rules,
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
      'franchises': franchises.map((f) => f.toMap()).toList(),
      'games': games.map((g) => g.toMap()).toList(),
      'rules': rules.map((r) => r.toMap()).toList(),
      'ruleConfig': ruleConfig.toMap(),
      'transactions': transactions.map((t) => t.toMap()).toList(),
    };
  }

  factory GameSpaceBackup.fromMap(Map<dynamic, dynamic> map) {
    final profile = Profile.fromMap(map['profile'] as Map? ?? {});

    final franchisesList = <GameSeries>[];
    // Support 'franchises' and backward-compatible 'series'
    final rawFranchises = map['franchises'] ?? map['series'];
    if (rawFranchises is List) {
      for (final item in rawFranchises) {
        if (item is Map) {
          franchisesList.add(GameSeries.fromMap(item));
        }
      }
    }

    final gamesList = <GameItem>[];
    // Support 'games' and backward-compatible 'items' or 'volumes'
    final rawGames = map['games'] ?? map['items'] ?? map['volumes'];
    if (rawGames is List) {
      for (final item in rawGames) {
        if (item is Map) {
          gamesList.add(GameItem.fromMap(item));
        }
      }
    }

    final rulesList = <GameRule>[];
    final rawRules = map['rules'] ?? map['passes'];
    if (rawRules is List) {
      for (final item in rawRules) {
        if (item is Map) {
          rulesList.add(GameRule.fromMap(item));
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

    return GameSpaceBackup(
      version: map['version']?.toString() ?? '2.1.0',
      spaceType: 'games',
      schemaVersion: map['schemaVersion']?.toString() ?? '2',
      exportedAt: parsedDate,
      profile: profile,
      franchises: franchisesList,
      games: gamesList,
      rules: rulesList,
      ruleConfig: ruleConfig,
      transactions: transactionsList,
    );
  }

  String toJson({bool indent = true}) {
    final encoder = indent ? const JsonEncoder.withIndent('  ') : const JsonEncoder();
    return encoder.convert(toMap());
  }

  factory GameSpaceBackup.fromJson(String jsonStr) {
    final decoded = jsonDecode(jsonStr);
    if (decoded is! Map) {
      throw const FormatException('Invalid GameSpaceBackup JSON: Root is not an object');
    }
    return GameSpaceBackup.fromMap(decoded);
  }
}
