import 'package:flutter_test/flutter_test.dart';
import 'package:canele/models/rule_config.dart';
import 'package:canele/models/purchase_transaction.dart';
import 'package:canele/services/quota_engine.dart';

void main() {
  group('QuotaEngine Deterministic Arithmetic & Timeline Tests', () {
    test('Calculates active months, regular expected, bonus expected with customBonusLedger & no-book months', () {
      // Timeline from 2024-01-01 to 2024-06-15 (6 total months: Jan, Feb, Mar, Apr, May, Jun)
      // With No-Book month = ["2024-03"] -> 5 active months
      // Bonus months = [5, 12] -> May is month 5 -> 1 recurring bonus
      // customBonusLedger = {"2024-02": 1, "2024-04": 2} -> 3 custom bonus books
      final config = RuleConfig(
        timelineStartDate: DateTime(2024, 1, 1),
        defaultRegularPerMonth: 1,
        bonusMonths: const [5, 12],
        noBookMonths: const ['2024-03'],
        manualBonusCount: 0,
        customBonusLedger: const {'2024-02': 1, '2024-04': 2},
      );

      final asOfDate = DateTime(2024, 6, 15);
      final transactions = <PurchaseTransaction>[
        PurchaseTransaction(
          id: 'tx1',
          volumeId: 'vol1',
          purchaseDate: DateTime(2024, 1, 10),
          quotaBucket: 'regular',
          price: 15.0,
        ),
        PurchaseTransaction(
          id: 'tx2',
          volumeId: 'vol2',
          purchaseDate: DateTime(2024, 2, 10),
          quotaBucket: 'regular',
          price: 15.0,
        ),
        PurchaseTransaction(
          id: 'tx3',
          volumeId: 'vol3',
          purchaseDate: DateTime(2024, 5, 10),
          quotaBucket: 'bonus',
          price: 20.0,
        ),
        PurchaseTransaction(
          id: 'tx4',
          volumeId: 'vol4',
          purchaseDate: DateTime(2024, 5, 12),
          quotaBucket: 'gift',
          price: 0.0,
        ),
      ];

      final summary = QuotaEngine.calculate(
        config: config,
        transactions: transactions,
        asOfDate: asOfDate,
      );

      expect(summary.activeMonthKeys.length, 5); // Jan, Feb, Apr, May, Jun
      expect(summary.regularExpected, 5); // 5 active months * 1
      expect(summary.regularBought, 3); // 3 non-gift bought books dynamically fill regular first
      expect(summary.regularRemaining, 2); // 5 - 3 = 2

      // Recurring (1) + CustomLedger (3) = 4
      expect(summary.bonusExpected, 4);
      expect(summary.bonusBought, 0); // 3 total bought used for regular, 0 overflow to bonus
      expect(summary.bonusRemaining, 4); // 4 - 0 = 4

      // Total open = 2 + 4 = 6
      expect(summary.totalRemaining, 6);

      // Gifts do not consume regular or bonus quota
      expect(summary.giftsCount, 1);
      expect(summary.totalSpent, 50.0);
      expect(summary.isAheadOfSchedule, false);
      expect(summary.creditsCount, 0);
    });

    test('Auto-Skip Timeline Projection when ahead of schedule (totalRemaining < 0)', () {
      // 3 active months (Jan, Feb, Mar 2024) -> regularExpected = 3
      // But user bought 6 regular books -> 3 books ahead (+3 months credit)
      // Future no-book month: "2024-05"
      // Progression:
      // - April 2024 (+1 -> 4)
      // - May 2024 (Skipped No-Book Month)
      // - June 2024 (+1 -> 5)
      // - July 2024 (+1 -> 6, catches up!)
      final config = RuleConfig(
        timelineStartDate: DateTime(2024, 1, 1),
        defaultRegularPerMonth: 1,
        bonusMonths: const [12],
        noBookMonths: const ['2024-05'],
      );

      final asOfDate = DateTime(2024, 3, 15);
      final transactions = List.generate(
        6,
        (i) => PurchaseTransaction(
          id: 'tx_$i',
          volumeId: 'vol_$i',
          purchaseDate: DateTime(2024, 3, 1),
          quotaBucket: 'regular',
          price: 10.0,
        ),
      );

      final summary = QuotaEngine.calculate(
        config: config,
        transactions: transactions,
        asOfDate: asOfDate,
      );

      expect(summary.regularExpected, 3);
      expect(summary.regularBought, 3); // Dynamically capped at regularExpected
      expect(summary.bonusBought, 3); // 6 - 3 = 3 overflow
      expect(summary.regularRemaining, 0);
      expect(summary.regularRemainingDisplay, 0);
      expect(summary.bonusRemaining, -3);
      expect(summary.bonusRemainingDisplay, 0);
      expect(summary.totalRemaining, -3);
      expect(summary.isAheadOfSchedule, true);
      expect(summary.creditsCount, 3);
      expect(summary.monthsAhead, 3);
      expect(summary.projectedCatchUpKey, '2024-07');
      expect(summary.projectedCatchUpMonth, 'July 2024');
    });

    test('Negative total open count increments properly as normal and bonus months advance', () {
      // Start 2024-01-01. User buys 5 books in Jan 2024.
      // Default: 1 book/month. Bonus month: Month 4 (April).
      final config = RuleConfig(
        timelineStartDate: DateTime(2024, 1, 1),
        defaultRegularPerMonth: 1,
        bonusMonths: const [4], // April has +1 bonus
        noBookMonths: const [],
      );

      final transactions = List.generate(
        5,
        (i) => PurchaseTransaction(
          id: 'tx_jan_$i',
          volumeId: 'vol_$i',
          purchaseDate: DateTime(2024, 1, 15),
          quotaBucket: 'regular',
          price: 10.0,
        ),
      );

      // 1. As of January 2024: Expected = 1 (1 reg, 0 bonus), Bought = 5
      final janSummary = QuotaEngine.calculate(
        config: config,
        transactions: transactions,
        asOfDate: DateTime(2024, 1, 31),
      );
      expect(janSummary.regularExpected, 1);
      expect(janSummary.regularBought, 1);
      expect(janSummary.bonusBought, 4);
      expect(janSummary.regularRemaining, 0);
      expect(janSummary.bonusRemaining, -4);
      expect(janSummary.regularRemainingDisplay, 0);
      expect(janSummary.bonusRemainingDisplay, 0);
      expect(janSummary.totalRemaining, -4); // Negative total open
      expect(janSummary.isAheadOfSchedule, true);
      expect(janSummary.creditsCount, 4);

      // 2. As of February 2024: Expected = 2 (2 reg, 0 bonus), Bought = 5
      final febSummary = QuotaEngine.calculate(
        config: config,
        transactions: transactions,
        asOfDate: DateTime(2024, 2, 28),
      );
      expect(febSummary.regularExpected, 2);
      expect(febSummary.regularBought, 2);
      expect(febSummary.bonusBought, 3);
      expect(febSummary.regularRemaining, 0);
      expect(febSummary.bonusRemaining, -3);
      expect(febSummary.regularRemainingDisplay, 0);
      expect(febSummary.totalRemaining, -3); // Incremented from -4 to -3

      // 3. As of March 2024: Expected = 3 (3 reg, 0 bonus), Bought = 5
      final marSummary = QuotaEngine.calculate(
        config: config,
        transactions: transactions,
        asOfDate: DateTime(2024, 3, 31),
      );
      expect(marSummary.regularExpected, 3);
      expect(marSummary.regularBought, 3);
      expect(marSummary.bonusBought, 2);
      expect(marSummary.regularRemaining, 0);
      expect(marSummary.bonusRemaining, -2);
      expect(marSummary.regularRemainingDisplay, 0);
      expect(marSummary.totalRemaining, -2); // Incremented to -2

      // 4. As of April 2024 (Bonus Month): Expected = 4 reg + 1 bonus = 5 total, Bought = 5
      final aprSummary = QuotaEngine.calculate(
        config: config,
        transactions: transactions,
        asOfDate: DateTime(2024, 4, 30),
      );
      expect(aprSummary.regularExpected, 4);
      expect(aprSummary.bonusExpected, 1);
      expect(aprSummary.regularBought, 4);
      expect(aprSummary.bonusBought, 1);
      expect(aprSummary.regularRemaining, 0);
      expect(aprSummary.bonusRemaining, 0);
      expect(aprSummary.regularRemainingDisplay, 0);
      expect(aprSummary.bonusRemainingDisplay, 0);
      expect(aprSummary.totalRemaining, 0); // Caught up! Total open is 0
      expect(aprSummary.isAheadOfSchedule, false);

      // 5. As of May 2024: Expected = 5 reg + 1 bonus = 6 total, Bought = 5
      final maySummary = QuotaEngine.calculate(
        config: config,
        transactions: transactions,
        asOfDate: DateTime(2024, 5, 31),
      );
      expect(maySummary.regularExpected, 5);
      expect(maySummary.bonusExpected, 1);
      expect(maySummary.regularBought, 5);
      expect(maySummary.bonusBought, 0);
      expect(maySummary.regularRemaining, 0);
      expect(maySummary.bonusRemaining, 1);
      expect(maySummary.regularRemainingDisplay, 0);
      expect(maySummary.bonusRemainingDisplay, 1);
      expect(maySummary.totalRemaining, 1); // Positive open count
    });

    test('Calculates active months and auto-skip forward simulation with recurringNoBookMonths', () {
      // 8 months from 2024-01 to 2024-08
      // recurringNoBookMonths = [3, 7] (March and July skipped every year)
      // noBookMonths = ['2024-05'] (May 2024 one-off skipped)
      // Active months: Jan(1), Feb(2), Apr(4), Jun(6), Aug(8) = 5 active months
      final config = RuleConfig(
        timelineStartDate: DateTime(2024, 1, 1),
        defaultRegularPerMonth: 2,
        bonusMonths: const [12],
        recurringNoBookMonths: const [3, 7],
        noBookMonths: const ['2024-05'],
      );

      final transactions = [
        PurchaseTransaction(
          id: 'tx1',
          volumeId: 'v1',
          purchaseDate: DateTime(2024, 1, 5),
          quotaBucket: 'regular',
          price: 12.0,
        ),
        PurchaseTransaction(
          id: 'tx2',
          volumeId: 'v2',
          purchaseDate: DateTime(2024, 2, 5),
          quotaBucket: 'regular',
          price: 12.0,
        ),
      ];

      final summary = QuotaEngine.calculate(
        config: config,
        transactions: transactions,
        asOfDate: DateTime(2024, 8, 15),
      );

      expect(summary.activeMonthKeys, ['2024-01', '2024-02', '2024-04', '2024-06', '2024-08']);
      expect(summary.regularExpected, 10); // 5 active * 2
      expect(summary.regularBought, 2);
      expect(summary.regularRemaining, 8);
      expect(summary.totalRemaining, 8);

      // Test simulation when ahead: User bought 8 books in Jan 2024 (as of Jan 2024)
      final aheadTx = List.generate(
        8,
        (i) => PurchaseTransaction(
          id: 'ahead_tx_$i',
          volumeId: 'vol_$i',
          purchaseDate: DateTime(2024, 1, 10),
          quotaBucket: 'regular',
          price: 10.0,
        ),
      );

      final aheadSummary = QuotaEngine.calculate(
        config: config,
        transactions: aheadTx,
        asOfDate: DateTime(2024, 1, 15),
      );

      // Expected in Jan = 2, bought = 8, ahead = 6
      // Future simulation:
      // - Feb: active (+2 -> 4)
      // - Mar: recurring skipped (+0 -> 4)
      // - Apr: active (+2 -> 6)
      // - May: one-off skipped (+0 -> 6)
      // - Jun: active (+2 -> 8, catches up in June 2024!)
      expect(aheadSummary.isAheadOfSchedule, true);
      expect(aheadSummary.creditsCount, 6);
      expect(aheadSummary.projectedCatchUpKey, '2024-06');
      expect(aheadSummary.projectedCatchUpMonth, 'June 2024');
    });

    test('User scenario: 33 books bought dynamically adjusts when 4 no-book months are added (prevents 33/29)', () {
      // 33 months timeline (e.g. 2024-01 to 2026-09)
      // Default: 1 book per month
      // 4 no-book months added -> regularExpected drops from 33 to 29
      final configWithNoBookMonths = RuleConfig(
        timelineStartDate: DateTime(2024, 1, 1),
        defaultRegularPerMonth: 1,
        bonusMonths: const [],
        noBookMonths: const ['2024-03', '2024-07', '2025-02', '2025-08'],
      );

      final transactions = List.generate(
        33,
        (i) => PurchaseTransaction(
          id: 'tx_$i',
          volumeId: 'vol_$i',
          purchaseDate: DateTime(2024, 1, 1),
          quotaBucket: 'regular', // Originally marked as regular at purchase time
          price: 10.0,
        ),
      );

      final summary = QuotaEngine.calculate(
        config: configWithNoBookMonths,
        transactions: transactions,
        asOfDate: DateTime(2026, 9, 1), // 33 months elapsed
      );

      expect(summary.activeMonthKeys.length, 29);
      expect(summary.regularExpected, 29);
      expect(summary.regularBought, 29); // Dynamically adjusted to 29 (not fixed at 33)
      expect(summary.bonusBought, 4); // Overflow 33 - 29 = 4
      expect(summary.regularRemaining, 0);
      expect(summary.bonusRemaining, -4);
      expect(summary.totalRemaining, -4);
      expect(summary.isAheadOfSchedule, true);
      expect(summary.creditsCount, 4);

      // Now suppose the user removes 2 no-book months (leaving 2 no-book months -> 31 regularExpected)
      final configUpdated = configWithNoBookMonths.copyWith(
        noBookMonths: const ['2024-03', '2024-07'],
      );

      final updatedSummary = QuotaEngine.calculate(
        config: configUpdated,
        transactions: transactions,
        asOfDate: DateTime(2026, 9, 1),
      );

      expect(updatedSummary.activeMonthKeys.length, 31);
      expect(updatedSummary.regularExpected, 31);
      expect(updatedSummary.regularBought, 31); // Dynamically adjusted to 31
      expect(updatedSummary.bonusBought, 2); // Overflow 33 - 31 = 2
      expect(updatedSummary.regularRemaining, 0);
      expect(updatedSummary.bonusRemaining, -2);
      expect(updatedSummary.totalRemaining, -2);
      expect(updatedSummary.creditsCount, 2);
    });

    test('Month can be both a no-book month and a bonus month (counts bonus book, 0 regular)', () {
      // Timeline from 2026-01-01 to 2026-07-31 (7 months: Jan, Feb, Mar, Apr, May, Jun, Jul)
      // July 2026 is a recurring bonus month (bonusMonths: [7])
      // July 2026 is ALSO a no-book month (noBookMonths: ['2026-07'])
      // Monthly regular = 1
      final config = RuleConfig(
        timelineStartDate: DateTime(2026, 1, 1),
        defaultRegularPerMonth: 1,
        bonusMonths: const [7], // July is bonus month
        noBookMonths: const ['2026-07'], // July is also no-book month
        customBonusLedger: const {'2026-07': 1}, // Also +1 custom bonus logged for July 2026
      );

      final asOfDate = DateTime(2026, 7, 31);

      // User logged 6 books
      final transactions = List.generate(
        6,
        (i) => PurchaseTransaction(
          id: 'tx_jul_$i',
          volumeId: 'vol_$i',
          purchaseDate: DateTime(2026, 1, 15),
          quotaBucket: 'regular',
          price: 10.0,
        ),
      );

      final summary = QuotaEngine.calculate(
        config: config,
        transactions: transactions,
        asOfDate: asOfDate,
      );

      // 6 active regular months (Jan-Jun), July regular is 0
      expect(summary.activeMonthKeys.length, 6);
      expect(summary.regularExpected, 6);
      expect(summary.regularBought, 6);
      expect(summary.regularRemaining, 0);

      // July recurring bonus (1) + July custom bonus (1) = 2 bonus expected
      expect(summary.bonusExpected, 2);
      expect(summary.bonusBought, 0);
      expect(summary.bonusRemaining, 2);
      expect(summary.totalRemaining, 2); // 2 bonus books remaining to acquire
      expect(summary.isAheadOfSchedule, false);
    });

    test('Simulation handles future months that are both no-book and bonus months', () {
      // As of Jan 2024, user bought 5 books (regularExpected in Jan = 1)
      // Future month Feb 2024 is a no-book month AND a bonus month (bonusMonths: [2])
      // Future progression:
      // - Jan: 1 reg, 0 bonus -> 1 expected
      // - Feb: 0 reg (no-book), 1 bonus -> cumulative expected = 2
      // - Mar: 1 reg -> cumulative expected = 3
      // - Apr: 1 reg -> cumulative expected = 4
      // - May: 1 reg -> cumulative expected = 5 (catches up in May 2024!)
      final config = RuleConfig(
        timelineStartDate: DateTime(2024, 1, 1),
        defaultRegularPerMonth: 1,
        bonusMonths: const [2], // Feb is bonus month
        noBookMonths: const ['2024-02'], // Feb is also no-book month
      );

      final transactions = List.generate(
        5,
        (i) => PurchaseTransaction(
          id: 'tx_$i',
          volumeId: 'vol_$i',
          purchaseDate: DateTime(2024, 1, 5),
          quotaBucket: 'regular',
          price: 10.0,
        ),
      );

      final summary = QuotaEngine.calculate(
        config: config,
        transactions: transactions,
        asOfDate: DateTime(2024, 1, 15),
      );

      expect(summary.isAheadOfSchedule, true);
      expect(summary.creditsCount, 4); // 5 bought - 1 expected in Jan = 4
      expect(summary.projectedCatchUpKey, '2024-05');
      expect(summary.projectedCatchUpMonth, 'May 2024');
    });
  });
}
