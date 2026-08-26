import '../core/utils/type_helper.dart';
import '../models/rule_model.dart';
import '../models/series.dart';
import '../models/volume.dart';

class RecommendationSlot {
  final int slotIndex;
  final Series series;
  final Volume volume;
  final String ruleId;
  final String ruleName;
  final String reason;
  final double seriesCompletion;

  const RecommendationSlot({
    required this.slotIndex,
    required this.series,
    required this.volume,
    required this.ruleId,
    required this.ruleName,
    required this.reason,
    required this.seriesCompletion,
  });

  // Backward compatibility aliases
  String get passId => ruleId;
  String get passName => ruleName;
}

class SeriesEvaluationContext {
  final Series series;
  final List<Volume> allVolumes;
  final List<Volume> releasedVolumes;
  final List<Volume> ownedVolumes;
  final List<Volume> missingReleasedVolumes;
  final double completionPercentage;

  SeriesEvaluationContext({
    required this.series,
    required this.allVolumes,
    required this.releasedVolumes,
    required this.ownedVolumes,
    required this.missingReleasedVolumes,
    required this.completionPercentage,
  });

  int get missingCount => missingReleasedVolumes.length;
}

class CandidateItem {
  final SeriesEvaluationContext context;
  final Volume volume;

  CandidateItem({required this.context, required this.volume});

  Series get series => context.series;
}

class RuleEvaluator {
  static List<RecommendationSlot> evaluate({
    required List<RuleModel> rules,
    required List<Series> seriesList,
    required List<Volume> volumesList,
    int maxSlots = 4,
    DateTime? asOfDate,
  }) {
    final now = asOfDate ?? DateTime.now();

    // 1. Build evaluation context for every series
    final contexts = <String, SeriesEvaluationContext>{};
    final activeContexts = <SeriesEvaluationContext>[];

    for (final s in seriesList) {
      final sVolumes = volumesList.where((v) => v.seriesId == s.id).toList()
        ..sort((a, b) => a.volumeNumber.compareTo(b.volumeNumber));

      final released = sVolumes.where((v) {
        return v.isReleased(now);
      }).toList();

      final owned = sVolumes.where((v) => v.isOwned).toList();
      final missingReleased = released.where((v) => !v.isOwned && v.availability == 'available').toList();

      final completion = released.isEmpty ? 0.0 : (owned.length / released.length) * 100.0;

      final ctx = SeriesEvaluationContext(
        series: s,
        allVolumes: sVolumes,
        releasedVolumes: released,
        ownedVolumes: owned,
        missingReleasedVolumes: missingReleased,
        completionPercentage: completion,
      );

      contexts[s.id] = ctx;

      // Exclude dropped or completed series from standard recommendations
      if (s.collectionStatus != 'dropped' && s.collectionStatus != 'completed' && missingReleased.isNotEmpty) {
        activeContexts.add(ctx);
      }
    }

    final slots = <RecommendationSlot>[];
    final selectedVolumeIds = <String>{};
    final selectedSeriesIds = <String>{};

    // Calculate count of candidate series with unowned volumes
    final distinctCandidateSeriesCount = activeContexts.length;

    // 2. Sort enabled rules by priorityOrder
    final activeRules = rules.where((r) => r.isEnabled).toList()
      ..sort((a, b) => a.priorityOrder.compareTo(b.priorityOrder));

    // 3. Execute Rules Sequentially
    for (final rule in activeRules) {
      if (slots.length >= maxSlots) break;

      final candidates = <CandidateItem>[];

      for (final ctx in activeContexts) {
        // Enforce 1 volume per series total across all passes unless candidate series count < 4
        if (selectedSeriesIds.contains(ctx.series.id) && distinctCandidateSeriesCount >= maxSlots) {
          continue;
        }

        // Scope Filter
        if (!_matchesScope(ctx.series, rule)) {
          continue;
        }

        // Progress Trigger Filter
        if (!_matchesProgressTrigger(ctx, rule)) {
          continue;
        }

        // Pick matching unowned volume(s) for this series
        for (final vol in ctx.missingReleasedVolumes) {
          if (selectedVolumeIds.contains(vol.id)) continue;

          // Special Trigger: Restock Priority (matches items marked as recently back in stock / restocked watchlist)
          if (rule.restockPriorityEnabled && !vol.isRestockedWatchlist) {
            continue;
          }

          candidates.add(CandidateItem(context: ctx, volume: vol));
          // Take the matching volume per series
          break;
        }
      }

      // Sort candidates for this rule
      _sortCandidates(candidates, rule.sortBy);

      // Add to recommendation slots
      for (final item in candidates) {
        if (slots.length >= maxSlots) break;
        if (selectedVolumeIds.contains(item.volume.id)) continue;
        if (selectedSeriesIds.contains(item.series.id) && distinctCandidateSeriesCount >= maxSlots) continue;

        slots.add(RecommendationSlot(
          slotIndex: slots.length,
          series: item.series,
          volume: item.volume,
          ruleId: rule.id,
          ruleName: rule.name,
          reason: _buildReason(rule, item),
          seriesCompletion: item.context.completionPercentage,
        ));

        selectedVolumeIds.add(item.volume.id);
        selectedSeriesIds.add(item.series.id);
      }
    }

    // 4. Fallback Handling: If fewer than 4 items, fill remaining slots with next sequential volume of active series
    if (slots.length < maxSlots) {
      final fallbackCandidates = <CandidateItem>[];

      for (final ctx in activeContexts) {
        for (final vol in ctx.missingReleasedVolumes) {
          if (selectedVolumeIds.contains(vol.id)) continue;
          fallbackCandidates.add(CandidateItem(context: ctx, volume: vol));
        }
      }

      // Sort fallback by lowest volume number, then closest to completion
      fallbackCandidates.sort((a, b) {
        final volCmp = a.volume.volumeNumber.compareTo(b.volume.volumeNumber);
        if (volCmp != 0) return volCmp;
        return a.context.missingCount.compareTo(b.context.missingCount);
      });

      for (final item in fallbackCandidates) {
        if (slots.length >= maxSlots) break;
        if (selectedVolumeIds.contains(item.volume.id)) continue;
        if (selectedSeriesIds.contains(item.series.id) && distinctCandidateSeriesCount >= maxSlots) continue;

        slots.add(RecommendationSlot(
          slotIndex: slots.length,
          series: item.series,
          volume: item.volume,
          ruleId: 'fallback',
          ruleName: 'Catch-Up Queue',
          reason: 'Next sequential unowned volume for ${item.series.title}',
          seriesCompletion: item.context.completionPercentage,
        ));

        selectedVolumeIds.add(item.volume.id);
        selectedSeriesIds.add(item.series.id);
      }
    }

    return slots;
  }

  static bool _matchesScope(Series s, RuleModel rule) {
    switch (rule.scopeType) {
      case RuleScopeType.allSeries:
        return true;
      case RuleScopeType.specificSeries:
        return rule.targetSeriesIds.contains(s.id);
      case RuleScopeType.tagBased:
        if (rule.targetTags.isEmpty) return true;
        return s.tags.any((tag) => rule.targetTags.any((t) => t.toLowerCase() == tag.toLowerCase()));
      case RuleScopeType.formatType:
        if (rule.targetFormat == null || rule.targetFormat!.isEmpty) return true;
        return TypeHelper.normalizeKey(s.type).toLowerCase() == TypeHelper.normalizeKey(rule.targetFormat!).toLowerCase();
    }
  }

  static bool _matchesProgressTrigger(SeriesEvaluationContext ctx, RuleModel rule) {
    switch (rule.progressTrigger) {
      case ProgressTriggerType.none:
        return true;
      case ProgressTriggerType.exactVolumesLeft:
        final threshold = rule.volumeThresholdValue ?? 1;
        return ctx.missingCount == threshold;
      case ProgressTriggerType.leastRemainingVolumes:
        return ctx.missingCount <= (rule.volumeThresholdValue ?? 3);
      case ProgressTriggerType.completionPercentage:
        final threshold = rule.percentageThreshold ?? 80.0;
        return ctx.completionPercentage >= threshold;
      case ProgressTriggerType.gapFilling:
        return _hasSequentialGap(ctx);
    }
  }

  static bool _hasSequentialGap(SeriesEvaluationContext ctx) {
    // If there is an unowned volume before an owned volume
    bool foundUnowned = false;
    for (final v in ctx.allVolumes) {
      if (!v.isOwned) {
        foundUnowned = true;
      } else if (foundUnowned && v.isOwned) {
        return true; // Gap exists!
      }
    }
    return false;
  }

  static void _sortCandidates(List<CandidateItem> list, SortCriteria sortBy) {
    switch (sortBy) {
      case SortCriteria.earliestReleaseDate:
        list.sort((a, b) {
          final dateA = a.volume.releaseDate ?? DateTime(1970);
          final dateB = b.volume.releaseDate ?? DateTime(1970);
          final cmp = dateA.compareTo(dateB);
          if (cmp != 0) return cmp;
          return a.volume.volumeNumber.compareTo(b.volume.volumeNumber);
        });
        break;
      case SortCriteria.lowestVolumeNumber:
        list.sort((a, b) => a.volume.volumeNumber.compareTo(b.volume.volumeNumber));
        break;
      case SortCriteria.closestToCompletion:
        list.sort((a, b) => a.context.missingCount.compareTo(b.context.missingCount));
        break;
      case SortCriteria.alphabetical:
        list.sort((a, b) => a.series.title.toLowerCase().compareTo(b.series.title.toLowerCase()));
        break;
    }
  }

  static String _buildReason(RuleModel rule, CandidateItem item) {
    if (rule.restockPriorityEnabled && item.volume.isRestockedWatchlist) {
      return 'Restocked / Available Watchlist Volume';
    }
    if (rule.progressTrigger == ProgressTriggerType.exactVolumesLeft) {
      return '${item.context.missingCount} volume(s) left to complete series';
    }
    if (rule.progressTrigger == ProgressTriggerType.completionPercentage) {
      return '${item.context.completionPercentage.toStringAsFixed(0)}% series completed';
    }
    if (rule.progressTrigger == ProgressTriggerType.gapFilling) {
      return 'Fills chronological collection gap';
    }
    return 'Matched rule "${rule.name}"';
  }
}
