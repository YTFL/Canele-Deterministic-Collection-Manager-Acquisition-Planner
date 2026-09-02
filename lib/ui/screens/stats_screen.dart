import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_helper.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/type_helper.dart';
import '../../providers/series_provider.dart';
import '../../providers/quota_provider.dart';
import '../widgets/canele_card.dart';
import '../widgets/canele_progress_bar.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(exchangeRatesNotifierProvider.notifier).checkAndAutoFetch();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final allVolumes = ref.watch(volumesNotifierProvider);
    final allSeries = ref.watch(seriesNotifierProvider);
    final quotaSummary = ref.watch(quotaProvider);
    final config = ref.watch(ruleConfigNotifierProvider);
    ref.watch(exchangeRatesNotifierProvider);

    // Volume metrics
    final ownedVolumes = allVolumes.where((v) => v.isOwned).toList();
    final totalOwned = ownedVolumes.length;
    final giftedVolumes = ownedVolumes.where((v) => v.isGift).toList();
    final totalGifted = giftedVolumes.length;
    final totalBought = totalOwned - totalGifted;
    final giftPercentage = totalOwned > 0 ? (totalGifted / totalOwned * 100) : 0.0;
    final boughtPercentage = totalOwned > 0 ? (totalBought / totalOwned * 100) : 0.0;

    // Series metrics
    final totalSeries = allSeries.length;
    final activeSeries = allSeries.where((s) => s.status == 'active').toList();
    final completedSeries = allSeries.where((s) => s.status == 'completed').toList();
    final wishlistSeries = allSeries.where((s) => s.status == 'wishlist').toList();
    final droppedSeries = allSeries.where((s) => s.status == 'dropped').toList();

    // User-defined format breakdown (dynamic from actual series data)
    final seriesById = {for (final s in allSeries) s.id: s};
    final formatVolumeCounts = <String, int>{};
    final formatSeriesCounts = <String, int>{};

    for (final s in allSeries) {
      final raw = s.type.trim();
      if (raw.isNotEmpty) {
        final label = TypeHelper.formatTypeLabel(raw);
        formatSeriesCounts[label] = (formatSeriesCounts[label] ?? 0) + 1;
      }
    }

    for (final v in ownedVolumes) {
      final s = seriesById[v.seriesId];
      if (s != null && s.type.trim().isNotEmpty) {
        final label = TypeHelper.formatTypeLabel(s.type);
        formatVolumeCounts[label] = (formatVolumeCounts[label] ?? 0) + 1;
      }
    }

    final userDefinedFormats = formatVolumeCounts.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics & Insights'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. High-Level Summary Grid (Total Owned & Total Series)
            Row(
              children: [
                Expanded(
                  child: _StatOverviewCard(
                    title: 'Total Owned',
                    value: '$totalOwned',
                    subtitle: 'Physical volumes',
                    icon: Icons.auto_stories_rounded,
                    color: isDark ? AppColors.caramelizedAmberLight : AppColors.caramelizedAmber,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatOverviewCard(
                    title: 'Total Series',
                    value: '$totalSeries',
                    subtitle: '${activeSeries.length} active in collection',
                    icon: Icons.collections_bookmark_rounded,
                    color: AppColors.statusSuccess,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            // 2. Acquisition Quota & Pace
            const _SectionHeader(
              title: 'Acquisition Quota & Pace',
              subtitle: 'Timeline progression and deterministic quota balance',
              icon: Icons.pie_chart_rounded,
            ),
            const SizedBox(height: 10),

            CaneleCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ahead of Schedule Banner
                  if (quotaSummary.isAheadOfSchedule) ...[
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
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ahead of Schedule',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppColors.caramelizedAmberLight : AppColors.caramelizedAmber,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Normal quota pace catches up in ${quotaSummary.projectedCatchUpMonth ?? 'upcoming month'}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: isDark ? AppColors.darkTextMuted : AppColors.deepCaramelMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 3 Balance Tiles (Regular, Bonus, Total Open)
                  Row(
                    children: [
                      Expanded(
                        child: _BalanceBox(
                          title: 'Regular',
                          value: '${quotaSummary.regularRemainingDisplay}',
                          expected: quotaSummary.regularExpected,
                          bought: quotaSummary.regularBought,
                          status: quotaSummary.regularRemaining > 0
                              ? 'Remaining'
                              : 'Fulfilled',
                          statusColor: quotaSummary.regularRemaining > 0
                              ? (isDark ? AppColors.caramelizedAmberLight : AppColors.caramelizedAmber)
                              : (isDark ? AppColors.darkTextPrimary : AppColors.deepCaramel),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _BalanceBox(
                          title: 'Bonus',
                          value: '${quotaSummary.bonusRemainingDisplay}',
                          expected: quotaSummary.bonusExpected,
                          bought: quotaSummary.bonusBought,
                          status: quotaSummary.bonusRemaining > 0
                              ? 'Remaining'
                              : 'Fulfilled',
                          statusColor: quotaSummary.bonusRemaining > 0
                              ? AppColors.statusWarning
                              : (isDark ? AppColors.darkTextPrimary : AppColors.deepCaramel),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _BalanceBox(
                          title: 'Total Open',
                          value: '${quotaSummary.totalRemaining}',
                          expected: quotaSummary.regularExpected + quotaSummary.bonusExpected,
                          bought: quotaSummary.regularBought + quotaSummary.bonusBought,
                          status: quotaSummary.totalRemaining > 0
                              ? 'To Acquire'
                              : (quotaSummary.totalRemaining == 0 ? 'Fulfilled' : 'Credit'),
                          statusColor: quotaSummary.totalRemaining > 0
                              ? (isDark ? AppColors.caramelizedAmberLight : AppColors.caramelizedAmber)
                              : (quotaSummary.totalRemaining < 0
                                  ? (isDark ? AppColors.caramelizedAmberLight : AppColors.caramelizedAmber)
                                  : (isDark ? AppColors.darkTextPrimary : AppColors.deepCaramel)),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 14),

                  // Timeline & Configuration Rules
                  Text(
                    'Timeline Schedule Rules',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  _DetailRow(
                    label: 'Timeline Start',
                    value: DateFormatter.formatMonthYear(config.timelineStartDate),
                  ),
                  _DetailRow(
                    label: 'Active Tracked Months',
                    value: '${quotaSummary.activeMonthKeys.length} months (${config.noBookMonths.length} skipped)',
                  ),
                  _DetailRow(
                    label: 'Regular Rate',
                    value: '${config.defaultRegularPerMonth} volume / month',
                  ),
                  _DetailRow(
                    label: 'Configured Bonus Months',
                    value: config.bonusMonths.isEmpty
                        ? 'None'
                        : config.bonusMonths.map((m) => _monthName(m)).join(', '),
                  ),
                  if (config.recurringNoBookMonths.isNotEmpty)
                    _DetailRow(
                      label: 'Recurring No-Book Months',
                      value: config.recurringNoBookMonths.map((m) => _monthName(m)).join(', '),
                    ),
                  if (config.customBonusLedger.isNotEmpty)
                    _DetailRow(
                      label: 'Custom Bonuses Added',
                      value: '+${config.customBonusLedger.values.fold<int>(0, (a, b) => a + b)} across ${config.customBonusLedger.length} months',
                    ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // 3. Bought vs. Gifted Breakdown
            const _SectionHeader(
              title: 'Bought vs. Gifted',
              subtitle: 'Acquisition breakdown across your library',
              icon: Icons.card_giftcard_rounded,
            ),
            const SizedBox(height: 10),

            CaneleCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dual Segment Visual Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      height: 14,
                      child: Row(
                        children: [
                          if (totalOwned == 0)
                            Expanded(
                              child: Container(
                                color: isDark ? AppColors.darkPastryCardElevated : AppColors.pastryCrustLight,
                              ),
                            )
                          else ...[
                            if (totalBought > 0)
                              Expanded(
                                flex: totalBought,
                                child: Container(
                                  color: isDark ? AppColors.caramelizedAmberLight : AppColors.caramelizedAmber,
                                ),
                              ),
                            if (totalGifted > 0)
                              Expanded(
                                flex: totalGifted,
                                child: Container(
                                  color: AppColors.statusSuccess,
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: _LegendItem(
                          label: 'Bought Volumes',
                          count: totalBought,
                          percentage: boughtPercentage,
                          color: isDark ? AppColors.caramelizedAmberLight : AppColors.caramelizedAmber,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _LegendItem(
                          label: 'Gifted Volumes',
                          count: totalGifted,
                          percentage: giftPercentage,
                          color: AppColors.statusSuccess,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // Financial & Spending Analytics
            const _SectionHeader(
              title: 'Financial & Spend Insights',
              subtitle: 'Cost overview and average investment per volume',
              icon: Icons.payments_rounded,
            ),
            const SizedBox(height: 10),

            CaneleCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Spent',
                              style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              CurrencyHelper.format(quotaSummary.totalSpent, currencyCode: config.currency),
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: isDark ? AppColors.caramelizedAmberLight : AppColors.caramelizedAmber,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Across all logged acquisitions',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? AppColors.darkTextMuted : AppColors.deepCaramelMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 48,
                        color: isDark ? AppColors.darkPastryBorder : AppColors.pastryCrustBorder,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Average / Volume',
                              style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              totalBought > 0
                                  ? CurrencyHelper.format(quotaSummary.totalSpent / totalBought, currencyCode: config.currency)
                                  : 'N/A',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Per purchased volume',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? AppColors.darkTextMuted : AppColors.deepCaramelMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // 4. Series Status & Format Distribution
            const _SectionHeader(
              title: 'Series & Format Distribution',
              subtitle: 'Collection status and user-defined media formats',
              icon: Icons.category_rounded,
            ),
            const SizedBox(height: 10),

            CaneleCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Collection Series Status',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _StatusChip(
                        label: 'Active',
                        count: activeSeries.length,
                        color: isDark ? AppColors.caramelizedAmberLight : AppColors.caramelizedAmber,
                      ),
                      const SizedBox(width: 8),
                      _StatusChip(
                        label: 'Completed',
                        count: completedSeries.length,
                        color: AppColors.statusSuccess,
                      ),
                      const SizedBox(width: 8),
                      _StatusChip(
                        label: 'Wishlist',
                        count: wishlistSeries.length,
                        color: AppColors.statusWarning,
                      ),
                      if (droppedSeries.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        _StatusChip(
                          label: 'Dropped',
                          count: droppedSeries.length,
                          color: AppColors.statusDanger,
                        ),
                      ],
                    ],
                  ),

                  if (userDefinedFormats.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 14),

                    Text(
                      'Format Breakdown (Owned Volumes)',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    ...userDefinedFormats.map((formatName) {
                      final count = formatVolumeCounts[formatName] ?? 0;
                      final sCount = formatSeriesCounts[formatName] ?? 0;
                      final pct = totalOwned > 0 ? (count / totalOwned * 100) : 0.0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  formatName,
                                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  '$count vols (${pct.toStringAsFixed(1)}%) · $sCount series',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: isDark ? AppColors.darkTextMuted : AppColors.deepCaramelMuted,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            CaneleProgressBar(
                              value: pct / 100,
                              height: 6,
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  static String _monthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    if (month >= 1 && month <= 12) {
      return months[month - 1];
    }
    return '$month';
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: isDark ? AppColors.caramelizedAmberLight : AppColors.caramelizedAmber,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatOverviewCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _StatOverviewCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return CaneleCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              Icon(icon, size: 18, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkTextPrimary : AppColors.deepCaramel,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _BalanceBox extends StatelessWidget {
  final String title;
  final String value;
  final int expected;
  final int bought;
  final String status;
  final Color statusColor;

  const _BalanceBox({
    required this.title,
    required this.value,
    required this.expected,
    required this.bought,
    required this.status,
    required this.statusColor,
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
            title,
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 11, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: statusColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            status,
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 10, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            '${bought > expected ? expected : bought} / $expected',
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 9,
              color: isDark ? AppColors.darkTextMuted : AppColors.deepCaramelMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? AppColors.darkTextMuted : AppColors.deepCaramelMuted,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final int count;
  final double percentage;
  final Color color;

  const _LegendItem({
    required this.label,
    required this.count,
    required this.percentage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkPastryCardElevated : AppColors.pastryCrustLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$count (${percentage.toStringAsFixed(1)}%)',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatusChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkPastryCardElevated : AppColors.pastryCrustLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 0.8),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              '$count',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

