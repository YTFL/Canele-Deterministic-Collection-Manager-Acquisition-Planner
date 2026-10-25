import '../models/game_item.dart';
import '../models/game_rule.dart';
import '../models/game_series.dart';

class GameRecommendationSlot {
  final int slotIndex;
  final GameSeries series;
  final GameItem item;
  final String ruleId;
  final String ruleName;
  final String reason;
  final double franchiseCompletion;

  const GameRecommendationSlot({
    required this.slotIndex,
    required this.series,
    required this.item,
    required this.ruleId,
    required this.ruleName,
    required this.reason,
    required this.franchiseCompletion,
  });
}

class GameEvaluationContext {
  final GameSeries series;
  final List<GameItem> allItems;
  final List<GameItem> releasedItems;
  final List<GameItem> ownedItems;
  final List<GameItem> missingReleasedItems;
  final double completionPercentage;

  GameEvaluationContext({
    required this.series,
    required this.allItems,
    required this.releasedItems,
    required this.ownedItems,
    required this.missingReleasedItems,
    required this.completionPercentage,
  });

  int get missingCount => missingReleasedItems.length;
  bool get hasOwnedBaseGame => ownedItems.any((i) => i.itemType == GameItemType.game);
}

class GameCandidateItem {
  final GameEvaluationContext context;
  final GameItem item;

  GameCandidateItem({required this.context, required this.item});

  GameSeries get series => context.series;
}

class GameRuleEvaluator {
  static List<GameRecommendationSlot> evaluate({
    required List<GameRule> rules,
    required List<GameSeries> seriesList,
    required List<GameItem> itemsList,
    int maxSlots = 4,
    DateTime? asOfDate,
  }) {
    final now = asOfDate ?? DateTime.now();

    // 1. Build evaluation contexts for active series
    final activeContexts = <GameEvaluationContext>[];

    for (final s in seriesList) {
      if (s.collectionStatus.toLowerCase() != 'active') continue;

      final sItems = itemsList.where((i) => i.seriesId == s.id).toList()
        ..sort((a, b) => a.gameNumber.compareTo(b.gameNumber));

      final released = sItems.where((i) => i.isReleased(now)).toList();
      final owned = sItems.where((i) => i.isOwned).toList();
      final missingReleased = released.where((i) => !i.isOwned && i.availability == GameAvailability.available).toList();

      if (missingReleased.isEmpty) continue;

      final completion = released.isEmpty ? 0.0 : (owned.length / released.length) * 100.0;

      activeContexts.add(GameEvaluationContext(
        series: s,
        allItems: sItems,
        releasedItems: released,
        ownedItems: owned,
        missingReleasedItems: missingReleased,
        completionPercentage: completion,
      ));
    }

    final slots = <GameRecommendationSlot>[];
    final selectedItemIds = <String>{};
    final selectedSeriesIds = <String>{};
    final candidateCount = activeContexts.length;

    final activeRules = rules.where((r) => r.isEnabled).toList()
      ..sort((a, b) => a.priorityOrder.compareTo(b.priorityOrder));

    // If there are no active/enabled rules configured, do not recommend any games
    if (activeRules.isEmpty) {
      return [];
    }

    // 2. Evaluate active rules sequentially
    for (final rule in activeRules) {
      if (slots.length >= maxSlots) break;

      final candidates = <GameCandidateItem>[];

      for (final ctx in activeContexts) {
        if (selectedSeriesIds.contains(ctx.series.id) && candidateCount >= maxSlots) {
          continue;
        }

        // Scope filter
        if (!_matchesScope(ctx.series, rule)) continue;

        // Trigger filter
        if (!_matchesTrigger(ctx, rule)) continue;

        // Find matching item in this series
        for (final item in ctx.missingReleasedItems) {
          if (selectedItemIds.contains(item.id)) continue;

          // Priority Target filter (Watchlist priority)
          if (rule.isPriorityTargetOnly && !item.isPriorityTarget) continue;

          // DLC-only trigger check
          if (rule.trigger == GameRuleTrigger.dlcOnly) {
            if (item.itemType != GameItemType.dlc || !ctx.hasOwnedBaseGame) {
              continue;
            }
          }

          candidates.add(GameCandidateItem(context: ctx, item: item));
          break; // Take one item per series per pass
        }
      }

      // Sort candidates
      _sortCandidates(candidates, rule.sortBy);

      // Add to slots
      for (final c in candidates) {
        if (slots.length >= maxSlots) break;
        if (selectedItemIds.contains(c.item.id)) continue;
        if (selectedSeriesIds.contains(c.series.id) && candidateCount >= maxSlots) continue;

        slots.add(GameRecommendationSlot(
          slotIndex: slots.length,
          series: c.series,
          item: c.item,
          ruleId: rule.id,
          ruleName: rule.name,
          reason: _buildReason(rule, c),
          franchiseCompletion: c.context.completionPercentage,
        ));

        selectedItemIds.add(c.item.id);
        selectedSeriesIds.add(c.series.id);
      }
    }

    return slots;
  }

  static bool _matchesScope(GameSeries series, GameRule rule) {
    switch (rule.scope) {
      case GameRuleScope.all:
        return true;
      case GameRuleScope.franchisesOnly:
        return !series.isStandalone;
      case GameRuleScope.standaloneOnly:
        return series.isStandalone;
      case GameRuleScope.specific:
        return rule.targetSeriesIds.contains(series.id);
    }
  }

  static bool _matchesTrigger(GameEvaluationContext ctx, GameRule rule) {
    switch (rule.trigger) {
      case GameRuleTrigger.none:
      case GameRuleTrigger.sequentialNext:
        return true;
      case GameRuleTrigger.fewestRemaining:
        return ctx.missingCount <= (rule.thresholdValue ?? 2);
      case GameRuleTrigger.exactRemaining:
        return ctx.missingCount == (rule.thresholdValue ?? 1);
      case GameRuleTrigger.completionPercentage:
        return ctx.completionPercentage >= (rule.percentageThreshold ?? 80.0);
      case GameRuleTrigger.dlcOnly:
        return ctx.hasOwnedBaseGame && ctx.missingReleasedItems.any((i) => i.itemType == GameItemType.dlc);
    }
  }

  static void _sortCandidates(List<GameCandidateItem> candidates, GameSortCriteria sortBy) {
    switch (sortBy) {
      case GameSortCriteria.earliestReleaseDate:
        candidates.sort((a, b) {
          final aDate = a.item.releaseDate;
          final bDate = b.item.releaseDate;
          if (aDate != null && bDate != null) {
            final cmp = aDate.compareTo(bDate);
            if (cmp != 0) return cmp;
          } else if (aDate != null) {
            return -1;
          } else if (bDate != null) {
            return 1;
          }
          return a.item.gameNumber.compareTo(b.item.gameNumber);
        });
        break;
      case GameSortCriteria.chronologicalOrder:
        candidates.sort((a, b) {
          final cmp = a.item.gameNumber.compareTo(b.item.gameNumber);
          if (cmp != 0) return cmp;
          return a.context.missingCount.compareTo(b.context.missingCount);
        });
        break;
      case GameSortCriteria.closestToFranchiseCompletion:
        candidates.sort((a, b) {
          final compCmp = b.context.completionPercentage.compareTo(a.context.completionPercentage);
          if (compCmp != 0) return compCmp;
          return a.context.missingCount.compareTo(b.context.missingCount);
        });
        break;
      case GameSortCriteria.alphabetical:
        candidates.sort((a, b) {
          final titleCmp = a.series.title.toLowerCase().compareTo(b.series.title.toLowerCase());
          if (titleCmp != 0) return titleCmp;
          return a.item.gameNumber.compareTo(b.item.gameNumber);
        });
        break;
      case GameSortCriteria.lowestPrice:
        candidates.sort((a, b) {
          final aPrice = a.item.price ?? a.series.defaultGamePrice ?? double.infinity;
          final bPrice = b.item.price ?? b.series.defaultGamePrice ?? double.infinity;
          return aPrice.compareTo(bPrice);
        });
        break;
    }
  }

  static String _buildReason(GameRule rule, GameCandidateItem candidate) {
    final item = candidate.item;
    final ctx = candidate.context;

    if (item.isPriorityTarget) {
      return item.itemType == GameItemType.dlc
          ? 'Watchlist Priority DLC'
          : 'Watchlist Priority Target';
    }

    if (item.itemType == GameItemType.dlc) {
      return 'DLC expansion for owned game';
    }

    switch (rule.trigger) {
      case GameRuleTrigger.fewestRemaining:
      case GameRuleTrigger.exactRemaining:
        return ctx.missingCount == 1
            ? 'Only 1 game left to complete franchise'
            : '${ctx.missingCount} games left to complete franchise';
      case GameRuleTrigger.completionPercentage:
        return '${ctx.completionPercentage.toStringAsFixed(0)}% franchise complete';
      case GameRuleTrigger.sequentialNext:
        return ctx.series.isStandalone
            ? 'Available standalone game'
            : 'Next chronological installment in franchise';
      case GameRuleTrigger.dlcOnly:
        return 'DLC expansion for owned game';
      case GameRuleTrigger.none:
        return 'Recommended game acquisition';
    }
  }
}
