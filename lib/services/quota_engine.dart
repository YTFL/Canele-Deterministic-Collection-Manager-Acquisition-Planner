import 'dart:math';
import '../models/rule_config.dart';
import '../models/purchase_transaction.dart';
import '../models/series.dart';
import '../models/volume.dart';
import '../core/utils/date_formatter.dart';
import '../core/utils/currency_helper.dart';
import 'exchange_rate_service.dart';

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
  final String suggestedAutoBucket; // Auto-fill bucket for new purchases: 'regular' | 'bonus' | 'gift'

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
    this.suggestedAutoBucket = 'regular',
  });

  int get regularRemainingDisplay => regularRemaining > 0 ? regularRemaining : 0;
  int get bonusRemainingDisplay => bonusRemaining > 0 ? bonusRemaining : 0;

  String get quotaAllocationPreview {
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
    List<Series>? allSeries,
    List<Volume>? allVolumes,
    DateTime? asOfDate,
    ExchangeRates? exchangeRates,
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

    // Filter active months (exclude noBookMonths & recurringNoBookMonths)
    final activeMonthKeys = allMonthKeys.where((key) {
      if (config.noBookMonths.contains(key)) return false;
      final date = DateFormatter.fromMonthKey(key);
      if (config.recurringNoBookMonths.contains(date.month)) return false;
      return true;
    }).toList();

    final regularExpected = activeMonthKeys.length * config.defaultRegularPerMonth;

    // Bonus expected:
    // 1. Recurring bonus months occurred in timeline (bonus books count even if regular books are paused in that month)
    int recurringBonusMonthsOccurred = 0;
    for (final monthKey in allMonthKeys) {
      final date = DateFormatter.fromMonthKey(monthKey);
      if (config.bonusMonths.contains(date.month)) {
        recurringBonusMonthsOccurred++;
      }
    }

    // 2. Custom bonus ledger one-off entries occurred up to now (bonus books count even if regular books are paused in that month)
    int customLedgerBonusCount = 0;
    config.customBonusLedger.forEach((monthKey, bonusCount) {
      final date = DateFormatter.fromMonthKey(monthKey);
      if (!date.isAfter(targetEnd) && !date.isBefore(DateTime(start.year, start.month, 1))) {
        customLedgerBonusCount += bonusCount;
      }
    });

    final bonusExpected = recurringBonusMonthsOccurred + customLedgerBonusCount + config.manualBonusCount;

    // Transactions breakdown with multi-currency and seriesPrice normalization
    int totalBought = 0;
    int giftsCount = 0;
    double totalSpent = 0.0;

    final purchasedSeriesIds = (allVolumes != null)
        ? allVolumes.where((v) => v.isOwned && !v.isGift).map((v) => v.seriesId).toSet()
        : <String>{};
    final seriesWithPrice = allSeries
            ?.where((s) => s.seriesPrice != null && s.seriesPrice! > 0 && purchasedSeriesIds.contains(s.id))
            .toList() ??
        [];
    final seriesWithPriceIds = seriesWithPrice.map((s) => s.id).toSet();
    final volumeIdsWithSeriesPrice = (allVolumes != null && seriesWithPriceIds.isNotEmpty)
        ? allVolumes
            .where((v) => seriesWithPriceIds.contains(v.seriesId))
            .map((v) => v.id)
            .toSet()
        : <String>{};

    // Add spend from series-level bundle prices (only for series with purchased volumes)
    for (final s in seriesWithPrice) {
      final normalizedPrice = CurrencyHelper.convert(
        amount: s.seriesPrice!,
        fromCurrency: s.currency ?? config.currency,
        toCurrency: config.currency,
        rates: exchangeRates,
      );
      totalSpent += normalizedPrice;
    }

    final seriesMap = allSeries != null ? {for (final s in allSeries) s.id: s} : <String, Series>{};
    final txMap = {for (final t in transactions) t.volumeId: t};

    if (allVolumes != null) {
      for (final v in allVolumes) {
        if (!v.isOwned || v.isGift) continue;
        if (volumeIdsWithSeriesPrice.contains(v.id)) continue;

        final s = seriesMap[v.seriesId];
        final t = txMap[v.id];

        if (t != null && t.price > 0) {
          final txCurrency = t.currency ?? config.currency;
          totalSpent += CurrencyHelper.convert(
            amount: t.price,
            fromCurrency: txCurrency,
            toCurrency: config.currency,
            rates: exchangeRates,
          );
        } else if (v.price != null && v.price! > 0) {
          final volCurrency = v.currency ?? config.currency;
          totalSpent += CurrencyHelper.convert(
            amount: v.price!,
            fromCurrency: volCurrency,
            toCurrency: config.currency,
            rates: exchangeRates,
          );
        } else {
          final defPrice = s?.defaultVolumePrice ?? CurrencyHelper.defaultVolumePrice;
          final defCurr = s?.defaultVolumeCurrency ?? CurrencyHelper.defaultVolumeCurrency;
          totalSpent += CurrencyHelper.convert(
            amount: defPrice,
            fromCurrency: defCurr,
            toCurrency: config.currency,
            rates: exchangeRates,
          );
        }
      }
    } else {
      // Fallback if allVolumes not passed
      for (final t in transactions) {
        if (t.price > 0 && !volumeIdsWithSeriesPrice.contains(t.volumeId)) {
          final txCurrency = t.currency ?? config.currency;
          totalSpent += CurrencyHelper.convert(
            amount: t.price,
            fromCurrency: txCurrency,
            toCurrency: config.currency,
            rates: exchangeRates,
          );
        }
      }
    }

    for (final t in transactions) {
      if (t.quotaBucket == 'gift') {
        giftsCount++;
      } else {
        totalBought++;
      }
    }

    // Dynamically allocate bought books: fill regular quota first, remainder to bonus quota
    final int regularBought = min(totalBought, regularExpected);
    final int bonusBought = totalBought - regularBought;

    final regularRemaining = regularExpected - regularBought;
    final bonusRemaining = bonusExpected - bonusBought;
    final int totalRemaining = regularRemaining + bonusRemaining;
    final int totalExpected = regularExpected + bonusExpected;
    final isAhead = totalRemaining < 0;
    final creditsCount = isAhead ? (totalBought - totalExpected) : 0;

    String? projectedCatchUpMonth;
    String? projectedCatchUpKey;
    int monthsAhead = 0;

    if (isAhead) {
      // Simulate future months until cumulative expected >= totalBought
      int simCumulativeRegular = regularExpected;
      int simCumulativeBonus = bonusExpected;
      var simMonth = DateTime(now.year, now.month + 1, 1);
      int futureActiveMonthsCount = 0;
      int simIterations = 0;

      while ((simCumulativeRegular + simCumulativeBonus) < totalBought && simIterations < 1200) {
        simIterations++;
        final key = DateFormatter.toMonthKey(simMonth);
        final isNoBook = config.noBookMonths.contains(key) ||
            config.recurringNoBookMonths.contains(simMonth.month);
        final hasBonus = config.bonusMonths.contains(simMonth.month);
        final customBonus = config.customBonusLedger[key] ?? 0;

        if (!isNoBook) {
          simCumulativeRegular += config.defaultRegularPerMonth;
        }
        if (hasBonus) {
          simCumulativeBonus++;
        }
        if (customBonus > 0) {
          simCumulativeBonus += customBonus;
        }

        if (!isNoBook || hasBonus || customBonus > 0) {
          futureActiveMonthsCount++;
        }

        if ((simCumulativeRegular + simCumulativeBonus) >= totalBought) {
          projectedCatchUpKey = key;
          projectedCatchUpMonth = DateFormatter.formatMonthYear(simMonth);
          break;
        }
        simMonth = DateTime(simMonth.year, simMonth.month + 1, 1);
      }
      monthsAhead = futureActiveMonthsCount;
    }

    final suggestedAutoBucket = regularRemaining > 0 ? 'regular' : 'bonus';

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
      suggestedAutoBucket: suggestedAutoBucket,
    );
  }
}
