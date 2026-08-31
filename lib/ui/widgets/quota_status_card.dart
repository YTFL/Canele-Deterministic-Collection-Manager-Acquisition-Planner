import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../services/quota_engine.dart';
import '../../providers/quota_provider.dart';
import 'canele_card.dart';

class QuotaStatusCard extends ConsumerWidget {
  final QuotaSummary summary;
  final VoidCallback? onTap;

  const QuotaStatusCard({super.key, required this.summary, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final config = ref.watch(ruleConfigNotifierProvider);

    final now = DateTime.now();
    final currentMonthKey = DateFormatter.toMonthKey(now);
    final isCurrentMonthSkipped = config.noBookMonths.contains(currentMonthKey) ||
        config.recurringNoBookMonths.contains(now.month);

    return CaneleCard(
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkPastryCardElevated
                            : AppColors.pastryCrustLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.pie_chart_rounded,
                        color: AppColors.caramelizedAmber,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Acquisition Quota & Ledger',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${DateFormatter.formatMonthYear(now)} · ${summary.activeMonthKeys.length} active schedule months',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: isDark ? AppColors.darkTextMuted : AppColors.deepCaramelMuted,
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Stylized Pastry-Crust Ahead of Schedule Banner
          if (summary.isAheadOfSchedule) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkPastryCardElevated
                    : AppColors.warmPastryCrust.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? AppColors.caramelizedAmberLight.withValues(alpha: 0.4)
                      : AppColors.pastryCrustBorder,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.fast_forward_rounded,
                    color: isDark ? AppColors.caramelizedAmberLight : AppColors.caramelizedAmber,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ahead of schedule (+${summary.creditsCount} Books / +${summary.monthsAhead} mo credit)',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.caramelizedAmberLight : AppColors.caramelizedAmber,
                          ),
                        ),
                        Text(
                          'Quota resumes in ${summary.projectedCatchUpMonth ?? 'upcoming month'}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppColors.darkTextMuted
                                : AppColors.deepCaramelMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // 3 Metric Tiles: Regular Remaining, Bonus Remaining, Total Remaining
          Row(
            children: [
              Expanded(
                child: _QuotaBalanceTile(
                  label: 'Regular',
                  value: summary.regularRemaining > 0
                      ? '${summary.regularRemaining}'
                      : '0',
                  status: summary.regularRemaining > 0
                      ? 'Remaining'
                      : 'Fulfilled',
                  valueColor: summary.regularRemaining > 0
                      ? (isDark ? AppColors.caramelizedAmberLight : AppColors.caramelizedAmber)
                      : (isDark ? AppColors.darkTextPrimary : AppColors.deepCaramel),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _QuotaBalanceTile(
                  label: 'Bonus',
                  value: summary.bonusRemaining > 0
                      ? '${summary.bonusRemaining}'
                      : '0',
                  status: summary.bonusRemaining > 0
                      ? 'Remaining'
                      : 'Fulfilled',
                  valueColor: summary.bonusRemaining > 0
                      ? AppColors.statusWarning
                      : (isDark ? AppColors.darkTextPrimary : AppColors.deepCaramel),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _QuotaBalanceTile(
                  label: 'Total Open',
                  value: '${summary.totalRemaining}',
                  status: summary.totalRemaining > 0
                      ? 'To Acquire'
                      : (summary.totalRemaining == 0 ? 'Fulfilled' : 'Credit'),
                  valueColor: summary.totalRemaining > 0
                      ? (isDark ? AppColors.caramelizedAmberLight : AppColors.caramelizedAmber)
                      : (summary.totalRemaining < 0
                          ? (isDark ? AppColors.caramelizedAmberLight : AppColors.caramelizedAmber)
                          : (isDark ? AppColors.darkTextPrimary : AppColors.deepCaramel)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Quick Action Buttons (+1 Bonus, Skip Month)
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final currentBonus = config.customBonusLedger[currentMonthKey] ?? 0;
                    final updatedLedger = Map<String, int>.from(config.customBonusLedger);
                    updatedLedger[currentMonthKey] = currentBonus + 1;

                    final updatedConfig = config.copyWith(customBonusLedger: updatedLedger);
                    await ref.read(ruleConfigNotifierProvider.notifier).updateConfig(updatedConfig);

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Added +1 Bonus Quota for ${DateFormatter.formatMonthYear(now)}!'),
                          backgroundColor: AppColors.statusWarning,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                  label: const Text('+1 Bonus', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final newNoBookMonths = List<String>.from(config.noBookMonths);
                    final newRecurringNoBookMonths = List<int>.from(config.recurringNoBookMonths);
                    if (isCurrentMonthSkipped) {
                      newNoBookMonths.remove(currentMonthKey);
                      newRecurringNoBookMonths.remove(now.month);
                    } else {
                      if (!newNoBookMonths.contains(currentMonthKey)) {
                        newNoBookMonths.add(currentMonthKey);
                        newNoBookMonths.sort();
                      }
                    }

                    final updatedConfig = config.copyWith(
                      noBookMonths: newNoBookMonths,
                      recurringNoBookMonths: newRecurringNoBookMonths,
                    );
                    await ref.read(ruleConfigNotifierProvider.notifier).updateConfig(updatedConfig);

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isCurrentMonthSkipped
                                ? 'Resumed regular quota for ${DateFormatter.formatMonthYear(now)}'
                                : 'Marked ${DateFormatter.formatMonthYear(now)} as No-Book Month',
                          ),
                          backgroundColor: AppColors.caramelizedAmber,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  icon: Icon(
                    isCurrentMonthSkipped ? Icons.play_circle_outline_rounded : Icons.pause_circle_outline_rounded,
                    size: 16,
                  ),
                  label: Text(
                    isCurrentMonthSkipped ? 'Resume Mo.' : 'Skip Month',
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuotaBalanceTile extends StatelessWidget {
  final String label;
  final String value;
  final String status;
  final Color valueColor;

  const _QuotaBalanceTile({
    required this.label,
    required this.value,
    required this.status,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkPastryCardElevated : AppColors.pastryCrustLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppColors.darkPastryBorder : AppColors.pastryCrustBorder,
          width: 0.8,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 11, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            status,
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }
}
