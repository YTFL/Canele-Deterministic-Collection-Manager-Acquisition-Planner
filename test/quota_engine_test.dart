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
      expect(summary.regularBought, 2);
      expect(summary.regularRemaining, 3); // 5 - 2 = 3

      // Recurring (1) + CustomLedger (3) = 4
      expect(summary.bonusExpected, 4);
      expect(summary.bonusBought, 1);
      expect(summary.bonusRemaining, 3); // 4 - 1 = 3

      // Total open = 3 + 3 = 6
      expect(summary.totalRemaining, 6);

      // Gifts do not consume regular or bonus quota
      expect(summary.giftsCount, 1);
      expect(summary.totalSpent, 50.0);
      expect(summary.isAheadOfSchedule, false);
      expect(summary.creditsCount, 0);
    });

    test('Auto-Skip Timeline Projection when ahead of schedule (regularRemaining < 0)', () {
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
      expect(summary.regularBought, 6);
      expect(summary.regularRemaining, -3);
      expect(summary.isAheadOfSchedule, true);
      expect(summary.creditsCount, 3);
      expect(summary.monthsAhead, 3);
      expect(summary.projectedCatchUpKey, '2024-07');
      expect(summary.projectedCatchUpMonth, 'July 2024');
    });
  });
}
