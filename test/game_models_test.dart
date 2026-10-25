import 'package:flutter_test/flutter_test.dart';
import 'package:canele/features/games/models/game_item.dart';
import 'package:canele/features/games/models/game_rule.dart';
import 'package:canele/features/games/models/game_series.dart';

void main() {
  group('Game Models Serialization Tests', () {
    test('GameSeries toMap and fromMap preserve all fields', () {
      final series = GameSeries(
        id: 'gs_1',
        title: 'Dark Souls',
        isStandalone: false,
        collectionStatus: 'completed',
        releaseStatus: 'completed',
        defaultGamePrice: 59.99,
        defaultCurrency: 'USD',
        tags: ['Soulslike', 'Action', 'RPG'],
      );

      final map = series.toMap();
      final restored = GameSeries.fromMap(map);

      expect(restored.id, 'gs_1');
      expect(restored.title, 'Dark Souls');
      expect(restored.isStandalone, isFalse);
      expect(restored.collectionStatus, 'completed');
      expect(restored.releaseStatus, 'completed');
      expect(restored.defaultGamePrice, 59.99);
      expect(restored.defaultCurrency, 'USD');
      expect(restored.tags, ['Soulslike', 'Action', 'RPG']);
    });

    test('GameItem toMap and fromMap preserve DLC and Watchlist Priority Target', () {
      final item = GameItem(
        id: 'gi_1',
        seriesId: 'gs_1',
        title: 'Artorias of the Abyss',
        itemType: GameItemType.dlc,
        gameNumber: 1.5,
        isOwned: true,
        isGift: true,
        price: 14.99,
        currency: 'USD',
        availability: GameAvailability.available,
        isPriorityTarget: true,
      );

      final map = item.toMap();
      final restored = GameItem.fromMap(map);

      expect(restored.id, 'gi_1');
      expect(restored.seriesId, 'gs_1');
      expect(restored.title, 'Artorias of the Abyss');
      expect(restored.itemType, GameItemType.dlc);
      expect(restored.gameNumber, 1.5);
      expect(restored.isOwned, isTrue);
      expect(restored.isGift, isTrue);
      expect(restored.price, 14.99);
      expect(restored.currency, 'USD');
      expect(restored.availability, GameAvailability.available);
      expect(restored.isPriorityTarget, isTrue);
    });

    test('GameRule toMap and fromMap preserve game triggers and priority target', () {
      final rule = GameRule(
        id: 'gr_1',
        name: 'Finish Near-Complete Franchises',
        isEnabled: true,
        priorityOrder: 1,
        scope: GameRuleScope.franchisesOnly,
        trigger: GameRuleTrigger.fewestRemaining,
        thresholdValue: 2,
        isPriorityTargetOnly: false,
        sortBy: GameSortCriteria.closestToFranchiseCompletion,
      );

      final map = rule.toMap();
      final restored = GameRule.fromMap(map);

      expect(restored.id, 'gr_1');
      expect(restored.name, 'Finish Near-Complete Franchises');
      expect(restored.isEnabled, isTrue);
      expect(restored.priorityOrder, 1);
      expect(restored.scope, GameRuleScope.franchisesOnly);
      expect(restored.trigger, GameRuleTrigger.fewestRemaining);
      expect(restored.thresholdValue, 2);
      expect(restored.sortBy, GameSortCriteria.closestToFranchiseCompletion);
    });
  });
}
