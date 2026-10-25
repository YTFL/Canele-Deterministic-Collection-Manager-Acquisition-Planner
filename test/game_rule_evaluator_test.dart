import 'package:flutter_test/flutter_test.dart';
import 'package:canele/features/games/models/game_item.dart';
import 'package:canele/features/games/models/game_rule.dart';
import 'package:canele/features/games/models/game_series.dart';
import 'package:canele/features/games/services/game_rule_evaluator.dart';

void main() {
  group('GameRuleEvaluator Tests', () {
    test('Default game rules are correctly initialized with zero restock or volume references', () {
      final defaults = GameRule.defaultRules();
      expect(defaults.length, 4);

      expect(defaults[0].name, 'Prioritize Watchlist Games & DLCs');
      expect(defaults[0].isPriorityTargetOnly, isTrue);

      expect(defaults[1].name, 'Finish Near-Complete Franchises');
      expect(defaults[1].trigger, GameRuleTrigger.fewestRemaining);
      expect(defaults[1].thresholdValue, 2);

      expect(defaults[2].name, 'Next Sequential Installment');
      expect(defaults[2].trigger, GameRuleTrigger.sequentialNext);

      expect(defaults[3].name, 'DLC Expansions for Owned Games');
      expect(defaults[3].trigger, GameRuleTrigger.dlcOnly);
    });

    test('Prioritizes Watchlist Priority Target over other games', () {
      final series1 = GameSeries(
        id: 's_ds',
        title: 'Dark Souls',
        isStandalone: false,
        collectionStatus: 'active',
      );
      final series2 = GameSeries(
        id: 's_er',
        title: 'Elden Ring',
        isStandalone: true,
        collectionStatus: 'active',
      );

      final item1 = GameItem(
        id: 'item_ds1',
        seriesId: 's_ds',
        title: 'Dark Souls Remastered',
        gameNumber: 1.0,
        isOwned: false,
        isPriorityTarget: false,
      );

      final item2 = GameItem(
        id: 'item_er',
        seriesId: 's_er',
        title: 'Elden Ring',
        gameNumber: 1.0,
        isOwned: false,
        isPriorityTarget: true, // Watchlist target!
      );

      final rules = GameRule.defaultRules();
      final slots = GameRuleEvaluator.evaluate(
        rules: rules,
        seriesList: [series1, series2],
        itemsList: [item1, item2],
      );

      expect(slots.isNotEmpty, isTrue);
      // Elden Ring matches Rule 1 (Watchlist Target)
      expect(slots.first.series.title, 'Elden Ring');
      expect(slots.first.reason, 'Watchlist Priority Target');
    });

    test('Prioritizes near-complete franchise over larger franchise', () {
      // Franchise A has 1 game left
      final seriesA = GameSeries(
        id: 's_a',
        title: 'Portal',
        isStandalone: false,
        collectionStatus: 'active',
      );
      final itemA1 = GameItem(
        id: 'a1',
        seriesId: 's_a',
        title: 'Portal 1',
        gameNumber: 1.0,
        isOwned: true,
      );
      final itemA2 = GameItem(
        id: 'a2',
        seriesId: 's_a',
        title: 'Portal 2',
        gameNumber: 2.0,
        isOwned: false,
      );

      // Franchise B has 4 games left
      final seriesB = GameSeries(
        id: 's_b',
        title: 'Final Fantasy',
        isStandalone: false,
        collectionStatus: 'active',
      );
      final itemB1 = GameItem(
        id: 'b1',
        seriesId: 's_b',
        title: 'FF VII',
        gameNumber: 7.0,
        isOwned: false,
      );
      final itemB2 = GameItem(
        id: 'b2',
        seriesId: 's_b',
        title: 'FF VIII',
        gameNumber: 8.0,
        isOwned: false,
      );
      final itemB3 = GameItem(
        id: 'b3',
        seriesId: 's_b',
        title: 'FF IX',
        gameNumber: 9.0,
        isOwned: false,
      );
      final itemB4 = GameItem(
        id: 'b4',
        seriesId: 's_b',
        title: 'FF X',
        gameNumber: 10.0,
        isOwned: false,
      );

      final rules = [
        GameRule(
          id: 'rule_finish',
          name: 'Finish Near-Complete Franchises',
          trigger: GameRuleTrigger.fewestRemaining,
          thresholdValue: 2,
        ),
      ];

      final slots = GameRuleEvaluator.evaluate(
        rules: rules,
        seriesList: [seriesA, seriesB],
        itemsList: [itemA1, itemA2, itemB1, itemB2, itemB3, itemB4],
      );

      expect(slots.length, 1);
      expect(slots.first.series.title, 'Portal');
      expect(slots.first.reason, 'Only 1 game left to complete franchise');
    });

    test('DLC rule matches DLC only if base game is owned', () {
      final series = GameSeries(
        id: 's_witcher',
        title: 'The Witcher 3',
        isStandalone: true,
        collectionStatus: 'active',
      );

      final baseGame = GameItem(
        id: 'w3_base',
        seriesId: 's_witcher',
        title: 'The Witcher 3: Wild Hunt',
        itemType: GameItemType.game,
        gameNumber: 1.0,
        isOwned: true, // Base game owned!
      );

      final dlc = GameItem(
        id: 'w3_dlc1',
        seriesId: 's_witcher',
        title: 'Blood and Wine Expansion',
        itemType: GameItemType.dlc,
        gameNumber: 1.5,
        isOwned: false,
      );

      final rules = [
        GameRule(
          id: 'rule_dlc',
          name: 'DLC Expansions for Owned Games',
          trigger: GameRuleTrigger.dlcOnly,
        ),
      ];

      final slots = GameRuleEvaluator.evaluate(
        rules: rules,
        seriesList: [series],
        itemsList: [baseGame, dlc],
      );

      expect(slots.length, 1);
      expect(slots.first.item.title, 'Blood and Wine Expansion');
      expect(slots.first.reason, 'DLC expansion for owned game');
    });

    test('Scope StandaloneOnly excludes multi-game franchises', () {
      final franchise = GameSeries(
        id: 's_f',
        title: 'Halo',
        isStandalone: false,
        collectionStatus: 'active',
      );
      final standalone = GameSeries(
        id: 's_s',
        title: 'Celeste',
        isStandalone: true,
        collectionStatus: 'active',
      );

      final itemF = GameItem(id: 'i_f', seriesId: 's_f', title: 'Halo 1', gameNumber: 1.0);
      final itemS = GameItem(id: 'i_s', seriesId: 's_s', title: 'Celeste', gameNumber: 1.0);

      final rules = [
        GameRule(
          id: 'rule_standalone',
          name: 'Standalone Games Only',
          scope: GameRuleScope.standaloneOnly,
        ),
      ];

      final slots = GameRuleEvaluator.evaluate(
        rules: rules,
        seriesList: [franchise, standalone],
        itemsList: [itemF, itemS],
      );

      expect(slots.length, 1);
      expect(slots.first.series.title, 'Celeste');
    });

    test('Returns empty slots when no game rules are configured or all rules are disabled', () {
      final franchise = GameSeries(
        id: 's_f',
        title: 'Halo',
        isStandalone: false,
        collectionStatus: 'active',
      );
      final itemF = GameItem(id: 'i_f', seriesId: 's_f', title: 'Halo 1', gameNumber: 1.0);

      // 1. Empty rules list
      final slotsEmpty = GameRuleEvaluator.evaluate(
        rules: [],
        seriesList: [franchise],
        itemsList: [itemF],
      );
      expect(slotsEmpty, isEmpty);

      // 2. All rules disabled
      final slotsDisabled = GameRuleEvaluator.evaluate(
        rules: [
          GameRule(
            id: 'r_disabled',
            name: 'Disabled Game Rule',
            isEnabled: false,
          ),
        ],
        seriesList: [franchise],
        itemsList: [itemF],
      );
      expect(slotsDisabled, isEmpty);
    });
  });
}
