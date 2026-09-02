class RuleConfig {
  final String id;
  final DateTime timelineStartDate;
  final int defaultRegularPerMonth;
  final List<int> bonusMonths; // e.g. [5, 12] for May and December (optional)
  final List<int> recurringNoBookMonths; // e.g. [6] for recurring June (0 regular books)
  final List<String> noBookMonths; // e.g. ["2024-06"]
  final int manualBonusCount;
  final Map<String, int> customBonusLedger; // e.g. {"2024-07": 1, "2026-03": 2}
  final bool isOnboardingCompleted;
  final String currency; // CAD, USD, INR, JPY

  const RuleConfig({
    this.id = 'global_config',
    required this.timelineStartDate,
    this.defaultRegularPerMonth = 1,
    this.bonusMonths = const [],
    this.recurringNoBookMonths = const [],
    this.noBookMonths = const [],
    this.manualBonusCount = 0,
    this.customBonusLedger = const {},
    this.isOnboardingCompleted = false,
    this.currency = 'USD',
  });

  RuleConfig copyWith({
    String? id,
    DateTime? timelineStartDate,
    int? defaultRegularPerMonth,
    List<int>? bonusMonths,
    List<int>? recurringNoBookMonths,
    List<String>? noBookMonths,
    int? manualBonusCount,
    Map<String, int>? customBonusLedger,
    bool? isOnboardingCompleted,
    String? currency,
  }) {
    return RuleConfig(
      id: id ?? this.id,
      timelineStartDate: timelineStartDate ?? this.timelineStartDate,
      defaultRegularPerMonth: defaultRegularPerMonth ?? this.defaultRegularPerMonth,
      bonusMonths: bonusMonths ?? this.bonusMonths,
      recurringNoBookMonths: recurringNoBookMonths ?? this.recurringNoBookMonths,
      noBookMonths: noBookMonths ?? this.noBookMonths,
      manualBonusCount: manualBonusCount ?? this.manualBonusCount,
      customBonusLedger: customBonusLedger ?? this.customBonusLedger,
      isOnboardingCompleted: isOnboardingCompleted ?? this.isOnboardingCompleted,
      currency: currency ?? this.currency,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timelineStartDate': timelineStartDate.toIso8601String(),
      'defaultRegularPerMonth': defaultRegularPerMonth,
      'bonusMonths': bonusMonths,
      'recurringNoBookMonths': recurringNoBookMonths,
      'noBookMonths': noBookMonths,
      'manualBonusCount': manualBonusCount,
      'customBonusLedger': customBonusLedger,
      'isOnboardingCompleted': isOnboardingCompleted,
      'currency': currency,
    };
  }

  factory RuleConfig.fromMap(Map<dynamic, dynamic> map) {
    DateTime parsedDate;
    if (map['timelineStartDate'] is String) {
      parsedDate = DateTime.tryParse(map['timelineStartDate'] as String) ?? DateTime(2024, 1, 1);
    } else {
      parsedDate = DateTime(2024, 1, 1);
    }

    final rawBonusLedger = map['customBonusLedger'];
    final Map<String, int> bonusLedger = {};
    if (rawBonusLedger is Map) {
      rawBonusLedger.forEach((key, val) {
        if (val is num) {
          bonusLedger[key.toString()] = val.toInt();
        }
      });
    }

    return RuleConfig(
      id: map['id'] as String? ?? 'global_config',
      timelineStartDate: parsedDate,
      defaultRegularPerMonth: map['defaultRegularPerMonth'] as int? ?? 1,
      bonusMonths: (map['bonusMonths'] as List<dynamic>?)?.map((e) => e as int).toList() ?? [],
      recurringNoBookMonths: (map['recurringNoBookMonths'] as List<dynamic>?)?.map((e) => e as int).toList() ?? [],
      noBookMonths: (map['noBookMonths'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      manualBonusCount: map['manualBonusCount'] as int? ?? 0,
      customBonusLedger: bonusLedger,
      isOnboardingCompleted: map['isOnboardingCompleted'] as bool? ?? false,
      currency: map['currency'] as String? ?? 'USD',
    );
  }

  static RuleConfig createDefault() {
    final now = DateTime.now();
    return RuleConfig(
      id: 'global_config',
      timelineStartDate: DateTime(now.year, now.month, 1),
      defaultRegularPerMonth: 1,
      bonusMonths: const [],
      recurringNoBookMonths: const [],
      noBookMonths: const [],
      manualBonusCount: 0,
      customBonusLedger: const {},
      isOnboardingCompleted: false,
      currency: 'USD',
    );
  }
}
