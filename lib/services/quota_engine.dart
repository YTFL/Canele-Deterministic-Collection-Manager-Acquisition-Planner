import 'dart:math';
import '../models/rule_config.dart';
import '../models/purchase_transaction.dart';
import '../core/utils/date_formatter.dart';

class QuotaSummary {
  final int regularExpected;
  final int regularBought;
  final int regularRemaining;
  final int bonusExpected;
  final int bonusBought;
  final int bonusRemaining;
  final int totalRemaining;
  final int giftsCount;
  final double totalSpent;
  final bool isAheadOfSchedule;
  final int creditsCount; // How many extra regular books acquired
  final String? projectedCatchUpMonth; // e.g. "November 2026"
  final String? projectedCatchUpKey; // e.g. "2026-11"
  final int monthsAhead;
  final List<String> activeMonthKeys;

  const QuotaSummary({
    required this.regularExpected,
    required this.regularBought,
    required this.regularRemaining,
    required this.bonusExpected,
    required this.bonusBought,
    required this.bonusRemaining,
    required this.totalRemaining,
    required this.giftsCount,
    required this.totalSpent,
    required this.isAheadOfSchedule,
    required this.creditsCount,
    this.projectedCatchUpMonth,
    this.projectedCatchUpKey,
    this.monthsAhead = 0,
    required this.activeMonthKeys,
  });

  String get suggestedAutoBucket {
    if (regularRemaining > 0) {
      return 'regular';
    } else {
      return 'bonus';
    }
  }

  String get allocationDescription {
    if (regularRemaining > 0) {
      return 'Will use 1 Regular Quota ($regularRemaining remaining)';
    } else if (bonusRemaining > 0) {
      return 'Regular quota met — Allocating to Bonus ($bonusRemaining remaining)';
    } else {
      return 'Regular & scheduled bonus met — Extra bonus acquisition';
    }
  }
}

class QuotaEngine {
  static QuotaSummary calculate({
    required RuleConfig config,
    required List<PurchaseTransaction> transactions,
    DateTime? asOfDate,
  }) {
    final now = asOfDate ?? DateTime.now();
    final start = config.timelineStartDate;

    // Build list of months from start to now (inclusive)
    final allMonthKeys = <String>[];
    var current = DateTime(start.year, start.month, 1);
    final targetEnd = DateTime(now.year, now.month, 1);

    while (!current.isAfter(targetEnd)) {
      allMonthKeys.add(DateFormatter.toMonthKey(current));
      current = DateTime(current.year, current.month + 1, 1);
    }

    // Filter active months (exclude noBookMonths)
    final activeMonthKeys = allMonthKeys
        .where((key) => !config.noBookMonths.contains(key))
        .toList();

    final regularExpected = activeMonthKeys.length * config.defaultRegularPerMonth;

    // Bonus expected:
    // 1. Recurring bonus months occurred in timeline
    int recurringBonusMonthsOccurred = 0;
    for (final monthKey in activeMonthKeys) {
      final date = DateFormatter.fromMonthKey(monthKey);
      if (config.bonusMonths.contains(date.month)) {
        recurringBonusMonthsOccurred++;
      }
    }

    // 2. Custom bonus ledger one-off entries occurred up to now
    int customLedgerBonusCount = 0;
    config.customBonusLedger.forEach((monthKey, bonusCount) {
      final date = DateFormatter.fromMonthKey(monthKey);
      if (!date.isAfter(targetEnd) && !date.isBefore(DateTime(start.year, start.month, 1))) {
        customLedgerBonusCount += bonusCount;
      }
    });

    final bonusExpected = recurringBonusMonthsOccurred + customLedgerBonusCount + config.manualBonusCount;

    // Transactions breakdown
    int regularBought = 0;
    int bonusBought = 0;
    int giftsCount = 0;
    double totalSpent = 0.0;

    for (final t in transactions) {
      totalSpent += t.price;
      if (t.quotaBucket == 'regular') {
        regularBought++;
      } else if (t.quotaBucket == 'bonus') {
        bonusBought++;
      } else if (t.quotaBucket == 'gift') {
        giftsCount++;
      }
    }

    final regularRemaining = regularExpected - regularBought;
    final bonusRemaining = bonusExpected - bonusBought;
    final int totalRemaining = max<int>(0, regularRemaining) + max<int>(0, bonusRemaining);
    final isAhead = regularRemaining < 0;
    final creditsCount = isAhead ? (regularBought - regularExpected) : 0;

    String? projectedCatchUpMonth;
    String? projectedCatchUpKey;
    int monthsAhead = 0;

    if (isAhead) {
      // Simulate future months until cumulative regular expected >= regularBought
      int simCumulativeExpected = regularExpected;
      var simMonth = DateTime(now.year, now.month + 1, 1);
      int futureActiveMonthsCount = 0;

      while (simCumulativeExpected < regularBought) {
        final key = DateFormatter.toMonthKey(simMonth);
        if (!config.noBookMonths.contains(key)) {
          simCumulativeExpected += config.defaultRegularPerMonth;
          futureActiveMonthsCount++;
          if (simCumulativeExpected >= regularBought) {
            projectedCatchUpKey = key;
            projectedCatchUpMonth = DateFormatter.formatMonthYear(simMonth);
            break;
          }
        }
        simMonth = DateTime(simMonth.year, simMonth.month + 1, 1);
      }
      monthsAhead = futureActiveMonthsCount;
    }

    return QuotaSummary(
      regularExpected: regularExpected,
      regularBought: regularBought,
      regularRemaining: regularRemaining,
      bonusExpected: bonusExpected,
      bonusBought: bonusBought,
      bonusRemaining: bonusRemaining,
      totalRemaining: totalRemaining,
      giftsCount: giftsCount,
      totalSpent: totalSpent,
      isAheadOfSchedule: isAhead,
      creditsCount: creditsCount,
      projectedCatchUpMonth: projectedCatchUpMonth,
      projectedCatchUpKey: projectedCatchUpKey,
      monthsAhead: monthsAhead,
      activeMonthKeys: activeMonthKeys,
    );
  }
}
