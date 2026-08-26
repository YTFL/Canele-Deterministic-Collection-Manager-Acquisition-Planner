import 'package:hive/hive.dart';

part 'rule_model.g.dart';

@HiveType(typeId: 10)
enum RuleScopeType {
  @HiveField(0)
  allSeries,

  @HiveField(1)
  specificSeries,

  @HiveField(2)
  tagBased,

  @HiveField(3)
  formatType,
}

@HiveType(typeId: 11)
enum ProgressTriggerType {
  @HiveField(0)
  none,

  @HiveField(1)
  exactVolumesLeft,

  @HiveField(2)
  leastRemainingVolumes,

  @HiveField(3)
  completionPercentage,

  @HiveField(4)
  gapFilling,
}

@HiveType(typeId: 12)
enum SortCriteria {
  @HiveField(0)
  earliestReleaseDate,

  @HiveField(1)
  lowestVolumeNumber,

  @HiveField(2)
  closestToCompletion,

  @HiveField(3)
  alphabetical,
}

@HiveType(typeId: 13)
class RuleModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  bool isEnabled;

  @HiveField(3)
  int priorityOrder; // Execution priority (0 runs first)

  // Scope Configuration
  @HiveField(4)
  RuleScopeType scopeType;

  @HiveField(5)
  List<String> targetSeriesIds; // Active if scopeType == specificSeries

  @HiveField(6)
  List<String> targetTags; // Active if scopeType == tagBased

  @HiveField(7)
  String? targetFormat; // LightNovel, Manga, Comic, Book

  // Progress Triggers
  @HiveField(8)
  ProgressTriggerType progressTrigger;

  @HiveField(9)
  int? volumeThresholdValue; // e.g., 1, 2, or 3 volumes left

  @HiveField(10)
  double? percentageThreshold; // e.g., 80.0 for >80%

  // Special Triggers
  @HiveField(11)
  bool restockPriorityEnabled; // Bumps volumes marked as recently restocked/available

  // Sorting
  @HiveField(12)
  SortCriteria sortBy;

  RuleModel({
    required this.id,
    required this.name,
    this.isEnabled = true,
    this.priorityOrder = 0,
    this.scopeType = RuleScopeType.allSeries,
    this.targetSeriesIds = const [],
    this.targetTags = const [],
    this.targetFormat,
    this.progressTrigger = ProgressTriggerType.none,
    this.volumeThresholdValue,
    this.percentageThreshold,
    this.restockPriorityEnabled = false,
    this.sortBy = SortCriteria.earliestReleaseDate,
  });

  RuleModel copyWith({
    String? id,
    String? name,
    bool? isEnabled,
    int? priorityOrder,
    RuleScopeType? scopeType,
    List<String>? targetSeriesIds,
    List<String>? targetTags,
    String? targetFormat,
    ProgressTriggerType? progressTrigger,
    int? volumeThresholdValue,
    double? percentageThreshold,
    bool? restockPriorityEnabled,
    SortCriteria? sortBy,
  }) {
    return RuleModel(
      id: id ?? this.id,
      name: name ?? this.name,
      isEnabled: isEnabled ?? this.isEnabled,
      priorityOrder: priorityOrder ?? this.priorityOrder,
      scopeType: scopeType ?? this.scopeType,
      targetSeriesIds: targetSeriesIds ?? this.targetSeriesIds,
      targetTags: targetTags ?? this.targetTags,
      targetFormat: targetFormat ?? this.targetFormat,
      progressTrigger: progressTrigger ?? this.progressTrigger,
      volumeThresholdValue: volumeThresholdValue ?? this.volumeThresholdValue,
      percentageThreshold: percentageThreshold ?? this.percentageThreshold,
      restockPriorityEnabled: restockPriorityEnabled ?? this.restockPriorityEnabled,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'isEnabled': isEnabled,
      'priorityOrder': priorityOrder,
      'scopeType': scopeType.name,
      'targetSeriesIds': targetSeriesIds,
      'targetTags': targetTags,
      'targetFormat': targetFormat,
      'progressTrigger': progressTrigger.name,
      'volumeThresholdValue': volumeThresholdValue,
      'percentageThreshold': percentageThreshold,
      'restockPriorityEnabled': restockPriorityEnabled,
      'sortBy': sortBy.name,
    };
  }

  factory RuleModel.fromMap(Map<dynamic, dynamic> map) {
    return RuleModel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'Custom Rule',
      isEnabled: map['isEnabled'] as bool? ?? true,
      priorityOrder: map['priorityOrder'] as int? ?? 0,
      scopeType: _parseScopeType(map['scopeType']),
      targetSeriesIds: (map['targetSeriesIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      targetTags: (map['targetTags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      targetFormat: map['targetFormat'] as String?,
      progressTrigger: _parseProgressTrigger(map['progressTrigger']),
      volumeThresholdValue: map['volumeThresholdValue'] as int?,
      percentageThreshold: (map['percentageThreshold'] as num?)?.toDouble(),
      restockPriorityEnabled: map['restockPriorityEnabled'] as bool? ?? false,
      sortBy: _parseSortCriteria(map['sortBy']),
    );
  }

  static RuleScopeType _parseScopeType(dynamic val) {
    if (val is RuleScopeType) return val;
    final str = val?.toString() ?? '';
    return RuleScopeType.values.firstWhere(
      (e) => e.name == str,
      orElse: () => RuleScopeType.allSeries,
    );
  }

  static ProgressTriggerType _parseProgressTrigger(dynamic val) {
    if (val is ProgressTriggerType) return val;
    final str = val?.toString() ?? '';
    return ProgressTriggerType.values.firstWhere(
      (e) => e.name == str,
      orElse: () => ProgressTriggerType.none,
    );
  }

  static SortCriteria _parseSortCriteria(dynamic val) {
    if (val is SortCriteria) return val;
    final str = val?.toString() ?? '';
    return SortCriteria.values.firstWhere(
      (e) => e.name == str,
      orElse: () => SortCriteria.earliestReleaseDate,
    );
  }
}
