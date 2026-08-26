class RecommendationPass {
  final String id;
  final String name;
  final String description;
  final int order;
  final bool isEnabled;
  final int takeLimit;
  final Map<String, dynamic> filterCriteria;
  final String sortCriteria;

  const RecommendationPass({
    required this.id,
    required this.name,
    this.description = '',
    required this.order,
    this.isEnabled = true,
    this.takeLimit = 2,
    this.filterCriteria = const {},
    this.sortCriteria = 'releaseDateAsc',
  });

  RecommendationPass copyWith({
    String? id,
    String? name,
    String? description,
    int? order,
    bool? isEnabled,
    int? takeLimit,
    Map<String, dynamic>? filterCriteria,
    String? sortCriteria,
  }) {
    return RecommendationPass(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      order: order ?? this.order,
      isEnabled: isEnabled ?? this.isEnabled,
      takeLimit: takeLimit ?? this.takeLimit,
      filterCriteria: filterCriteria ?? this.filterCriteria,
      sortCriteria: sortCriteria ?? this.sortCriteria,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'order': order,
      'isEnabled': isEnabled,
      'takeLimit': takeLimit,
      'filterCriteria': filterCriteria,
      'sortCriteria': sortCriteria,
    };
  }

  factory RecommendationPass.fromMap(Map<dynamic, dynamic> map) {
    return RecommendationPass(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'Custom Pass',
      description: map['description'] as String? ?? '',
      order: map['order'] as int? ?? 0,
      isEnabled: map['isEnabled'] as bool? ?? true,
      takeLimit: map['takeLimit'] as int? ?? 2,
      filterCriteria: Map<String, dynamic>.from(map['filterCriteria'] as Map? ?? {}),
      sortCriteria: map['sortCriteria'] as String? ?? 'releaseDateAsc',
    );
  }

  static List<RecommendationPass> defaultPasses() {
    return [
      const RecommendationPass(
        id: 'pass_stay_caught_up',
        name: 'Stay Caught Up',
        description: 'Select active series missing exactly 1 released volume',
        order: 0,
        isEnabled: true,
        takeLimit: 2,
        filterCriteria: {
          'status': 'active',
          'missingVolumeCount': 'equals_1',
          'availability': 'available',
        },
        sortCriteria: 'releaseDateAsc',
      ),
      const RecommendationPass(
        id: 'pass_special_priority',
        name: 'Special Priority Rule',
        description: 'Select tagged priority series, checking restocked items first',
        order: 1,
        isEnabled: true,
        takeLimit: 2,
        filterCriteria: {
          'status': 'active',
          'requiredTag': 'special_priority',
          'prioritizeRestocked': true,
          'availability': 'available',
        },
        sortCriteria: 'releaseDateAsc',
      ),
      const RecommendationPass(
        id: 'pass_cascading_completion',
        name: 'Cascading Completion',
        description: 'Fill remaining slots from active series sorted by highest completion rate',
        order: 2,
        isEnabled: true,
        takeLimit: 4,
        filterCriteria: {
          'status': 'active',
          'availability': 'available',
        },
        sortCriteria: 'seriesCompletionDesc',
      ),
    ];
  }
}
