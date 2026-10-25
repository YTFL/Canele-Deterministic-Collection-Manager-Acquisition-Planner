import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:canele/models/profile.dart';
import 'package:canele/models/purchase_transaction.dart';
import 'package:canele/models/rule_config.dart';
import 'package:canele/features/games/models/game_item.dart';
import 'package:canele/features/games/models/game_rule.dart';
import 'package:canele/features/games/models/game_series.dart';
import 'package:canele/features/games/models/game_space_backup.dart';

void main() {
  group('GameSpaceBackup Domain Serialization Tests', () {
    test('GameSpaceBackup serializes and deserializes cleanly with full game semantics', () {
      final profile = Profile(
        id: 'games_profile_1',
        name: 'Steam & Epic Library',
        type: ProfileType.games,
        icon: 'gamepad',
        createdAt: DateTime(2026, 1, 1),
      );

      final franchise = GameSeries(
        id: 's_witcher',
        title: 'The Witcher',
        isStandalone: false,
        collectionStatus: 'active',
        releaseStatus: 'completed',
        defaultGamePrice: 39.99,
        defaultCurrency: 'USD',
        tags: ['rpg', 'open_world'],
      );

      final game1 = GameItem(
        id: 'item_w3',
        seriesId: 's_witcher',
        title: 'The Witcher 3: Wild Hunt',
        itemType: GameItemType.game,
        gameNumber: 3.0,
        isOwned: true,
        isGift: false,
        price: 39.99,
        currency: 'USD',
        availability: GameAvailability.available,
        isPriorityTarget: false,
      );

      final dlc1 = GameItem(
        id: 'item_w3_dlc',
        seriesId: 's_witcher',
        title: 'Blood and Wine Expansion',
        itemType: GameItemType.dlc,
        gameNumber: 3.5,
        isOwned: false,
        isGift: false,
        price: 19.99,
        currency: 'USD',
        availability: GameAvailability.available,
        isPriorityTarget: true,
      );

      final rule = GameRule(
        id: 'rule_dlc',
        name: 'DLC Expansions for Owned Games',
        scope: GameRuleScope.all,
        trigger: GameRuleTrigger.dlcOnly,
        isPriorityTargetOnly: false,
        priorityOrder: 0,
      );

      final tx = PurchaseTransaction(
        id: 'tx_w3',
        volumeId: 'item_w3',
        purchaseDate: DateTime(2026, 2, 1),
        quotaBucket: 'regular',
        price: 39.99,
        currency: 'USD',
        notes: 'Bought on Steam Sale',
      );

      final backup = GameSpaceBackup(
        exportedAt: DateTime(2026, 3, 1),
        profile: profile,
        franchises: [franchise],
        games: [game1, dlc1],
        rules: [rule],
        ruleConfig: RuleConfig.createDefault().copyWith(currency: 'USD'),
        transactions: [tx],
      );

      // JSON roundtrip
      final jsonStr = backup.toJson(indent: true);
      expect(jsonStr, contains('The Witcher'));
      expect(jsonStr, contains('Blood and Wine Expansion'));
      expect(jsonStr, contains('"spaceType": "games"'));

      final restored = GameSpaceBackup.fromJson(jsonStr);

      expect(restored.spaceType, 'games');
      expect(restored.profile.name, 'Steam & Epic Library');
      expect(restored.profile.type, ProfileType.games);

      expect(restored.franchises.length, 1);
      expect(restored.franchises.first.title, 'The Witcher');
      expect(restored.franchises.first.isStandalone, isFalse);

      expect(restored.games.length, 2);
      final restoredDlc = restored.games.firstWhere((g) => g.id == 'item_w3_dlc');
      expect(restoredDlc.itemType, GameItemType.dlc);
      expect(restoredDlc.isPriorityTarget, isTrue);
      expect(restoredDlc.price, 19.99);

      expect(restored.rules.length, 1);
      expect(restored.rules.first.trigger, GameRuleTrigger.dlcOnly);

      expect(restored.transactions.length, 1);
      expect(restored.transactions.first.notes, 'Bought on Steam Sale');
    });

    test('GameSpaceBackup gracefully handles legacy series/volumes payload format', () {
      final legacyMap = {
        'version': '2.0.0',
        'exportedAt': '2026-03-01T12:00:00.000Z',
        'profile': {
          'id': 'p_games',
          'name': 'Games',
          'type': 'games',
          'icon': 'gamepad',
          'createdAt': '2026-01-01T00:00:00.000Z',
        },
        'series': [
          {
            'id': 's_zelda',
            'title': 'The Legend of Zelda',
            'isStandalone': false,
            'collectionStatus': 'active',
          }
        ],
        'volumes': [
          {
            'id': 'g_totk',
            'seriesId': 's_zelda',
            'title': 'Tears of the Kingdom',
            'gameNumber': 2.0,
            'isOwned': true,
            'isGift': true,
          }
        ],
        'rules': [],
        'ruleConfig': {'id': 'cfg', 'currency': 'EUR'},
        'transactions': [],
      };

      final backup = GameSpaceBackup.fromMap(legacyMap);
      expect(backup.franchises.length, 1);
      expect(backup.franchises.first.title, 'The Legend of Zelda');
      expect(backup.games.length, 1);
      expect(backup.games.first.title, 'Tears of the Kingdom');
      expect(backup.games.first.isGift, isTrue);
    });
  });
}
