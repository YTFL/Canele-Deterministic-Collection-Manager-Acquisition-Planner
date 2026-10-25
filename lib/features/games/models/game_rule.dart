import '../../../core/utils/uuid_generator.dart';

enum GameRuleScope {
  all,
  franchisesOnly,
  standaloneOnly,
  specific,
}

enum GameRuleTrigger {
  none,
  fewestRemaining,
  exactRemaining,
  completionPercentage,
  sequentialNext,
  dlcOnly,
}

enum GameSortCriteria {
  earliestReleaseDate,
  chronologicalOrder,
  closestToFranchiseCompletion,
  alphabetical,
  lowestPrice,
}

class GameRule {
  final String id;
  final String name;
  final bool isEnabled;
  final int priorityOrder;
  final GameRuleScope scope;
  final List<String> targetSeriesIds;
  final List<String> targetTags;
  final GameRuleTrigger trigger;
  final int? thresholdValue; // e.g. 2 games remaining
  final double? percentageThreshold; // e.g. 80.0
  final bool isPriorityTargetOnly; // Only matches games/DLCs marked on Watchlist / Priority Target (NO RESTOCK)
  final GameSortCriteria sortBy;

  GameRule({
    required this.id,
    required this.name,
    this.isEnabled = true,
    this.priorityOrder = 0,
    this.scope = GameRuleScope.all,
    this.targetSeriesIds = const [],
    this.targetTags = const [],
    this.trigger = GameRuleTrigger.none,
    this.thresholdValue,
    this.percentageThreshold,
    this.isPriorityTargetOnly = false,
    this.sortBy = GameSortCriteria.earliestReleaseDate,
  });

  GameRule copyWith({
    String? id,
    String? name,
    bool? isEnabled,
    int? priorityOrder,
    GameRuleScope? scope,
    List<String>? targetSeriesIds,
    List<String>? targetTags,
    GameRuleTrigger? trigger,
    int? thresholdValue,
    double? percentageThreshold,
    bool? isPriorityTargetOnly,
    GameSortCriteria? sortBy,
  }) {
    return GameRule(
      id: id ?? this.id,
      name: name ?? this.name,
      isEnabled: isEnabled ?? this.isEnabled,
      priorityOrder: priorityOrder ?? this.priorityOrder,
      scope: scope ?? this.scope,
      targetSeriesIds: targetSeriesIds ?? this.targetSeriesIds,
      targetTags: targetTags ?? this.targetTags,
      trigger: trigger ?? this.trigger,
      thresholdValue: thresholdValue ?? this.thresholdValue,
      percentageThreshold: percentageThreshold ?? this.percentageThreshold,
      isPriorityTargetOnly: isPriorityTargetOnly ?? this.isPriorityTargetOnly,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'isEnabled': isEnabled,
      'priorityOrder': priorityOrder,
      'scopeType': scope.name,
      'targetSeriesIds': targetSeriesIds,
      'targetTags': targetTags,
      'progressTrigger': trigger.name,
      'volumeThresholdValue': thresholdValue,
      'percentageThreshold': percentageThreshold,
      'restockPriorityEnabled': isPriorityTargetOnly, // mapped for backward compatibility in box
      'isPriorityTargetOnly': isPriorityTargetOnly,
      'sortBy': sortBy.name,
    };
  }

  factory GameRule.fromMap(Map<dynamic, dynamic> map) {
    final rawScope = map['scopeType']?.toString() ?? 'all';
    GameRuleScope scope = GameRuleScope.all;
    for (final s in GameRuleScope.values) {
      if (s.name.toLowerCase() == rawScope.toLowerCase()) {
        scope = s;
        break;
      }
    }
    // Handle legacy specificSeries
    if (rawScope == 'specificSeries') scope = GameRuleScope.specific;

    final rawTrigger = map['progressTrigger']?.toString() ?? 'none';
    GameRuleTrigger trigger = GameRuleTrigger.none;
    for (final t in GameRuleTrigger.values) {
      if (t.name.toLowerCase() == rawTrigger.toLowerCase()) {
        trigger = t;
        break;
      }
    }
    // Handle legacy leastRemainingVolumes
    if (rawTrigger == 'leastRemainingVolumes') trigger = GameRuleTrigger.fewestRemaining;
    if (rawTrigger == 'exactVolumesLeft') trigger = GameRuleTrigger.exactRemaining;

    final rawSort = map['sortBy']?.toString() ?? 'earliestReleaseDate';
    GameSortCriteria sortBy = GameSortCriteria.earliestReleaseDate;
    for (final sc in GameSortCriteria.values) {
      if (sc.name.toLowerCase() == rawSort.toLowerCase()) {
        sortBy = sc;
        break;
      }
    }
    if (rawSort == 'lowestVolumeNumber') sortBy = GameSortCriteria.chronologicalOrder;
    if (rawSort == 'closestToCompletion') sortBy = GameSortCriteria.closestToFranchiseCompletion;

    final isPriority = map['isPriorityTargetOnly'] == true ||
        map['restockPriorityEnabled'] == true;

    return GameRule(
      id: map['id']?.toString() ?? UuidGenerator.generate(),
      name: map['name']?.toString() ?? 'Game Rule',
      isEnabled: map['isEnabled'] as bool? ?? true,
      priorityOrder: map['priorityOrder'] as int? ?? 0,
      scope: scope,
      targetSeriesIds: (map['targetSeriesIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      targetTags: (map['targetTags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      trigger: trigger,
      thresholdValue: map['volumeThresholdValue'] as int? ?? map['thresholdValue'] as int?,
      percentageThreshold: (map['percentageThreshold'] as num?)?.toDouble(),
      isPriorityTargetOnly: isPriority,
      sortBy: sortBy,
    );
  }

  static List<GameRule> defaultRules() {
    return [
      GameRule(
        id: UuidGenerator.generate(),
        name: 'Prioritize Watchlist Games & DLCs',
        priorityOrder: 0,
        scope: GameRuleScope.all,
        isPriorityTargetOnly: true,
        trigger: GameRuleTrigger.none,
        sortBy: GameSortCriteria.earliestReleaseDate,
      ),
      GameRule(
        id: UuidGenerator.generate(),
        name: 'Finish Near-Complete Franchises',
        priorityOrder: 1,
        scope: GameRuleScope.franchisesOnly,
        trigger: GameRuleTrigger.fewestRemaining,
        thresholdValue: 2,
        sortBy: GameSortCriteria.closestToFranchiseCompletion,
      ),
      GameRule(
        id: UuidGenerator.generate(),
        name: 'Next Sequential Installment',
        priorityOrder: 2,
        scope: GameRuleScope.franchisesOnly,
        trigger: GameRuleTrigger.sequentialNext,
        sortBy: GameSortCriteria.chronologicalOrder,
      ),
      GameRule(
        id: UuidGenerator.generate(),
        name: 'DLC Expansions for Owned Games',
        priorityOrder: 3,
        scope: GameRuleScope.all,
        trigger: GameRuleTrigger.dlcOnly,
        sortBy: GameSortCriteria.chronologicalOrder,
      ),
    ];
  }
}
