import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/series.dart';
import '../../models/volume.dart';
import '../../models/profile.dart';
import '../../providers/profile_provider.dart';
import '../../providers/series_provider.dart';
import '../../providers/quota_provider.dart';
import '../../providers/recommendation_provider.dart';
import '../../providers/rule_provider.dart';
import '../widgets/canele_card.dart';
import '../widgets/quota_status_card.dart';
import '../widgets/recommendation_slot_card.dart';
import '../widgets/log_transaction_sheet.dart';
import '../widgets/add_custom_item_sheet.dart';
import '../../models/custom_item.dart';
import '../../features/games/ui/views/game_dashboard_view.dart';
import '../../core/utils/workspace_terminology.dart';
import 'series_detail_screen.dart';
import 'stats_screen.dart';
import '../widgets/workspace_switcher_app_bar_title.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  void _showUpdateStatusSheet(BuildContext context, WidgetRef ref, Volume volume, Series series) {
    final activeProfile = ref.read(profileNotifierProvider).activeProfile;
    final isGames = activeProfile.type == ProfileType.games;
    final terms = activeProfile.terms;

    final customTitle = volume.customMetadata['title'] as String?;
    final itemType = volume.customMetadata['itemType'] as String?;
    final itemLabel = isGames
        ? ((customTitle != null && customTitle.isNotEmpty)
            ? '${itemType == 'dlc' ? '[DLC] ' : ''}$customTitle'
            : 'Game #${DateFormatter.formatVolumeNumber(volume.volumeNumber)}')
        : 'Vol. ${DateFormatter.formatVolumeNumber(volume.volumeNumber)}';

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Update Status · ${series.title} $itemLabel',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Divider(height: 20),
                ListTile(
                  leading: const Icon(Icons.check_circle_outline_rounded, color: AppColors.statusSuccess),
                  title: const Text('Mark In Stock / Available'),
                  subtitle: Text('${terms.itemLabel} is available for purchase'),
                  onTap: () async {
                    final updated = volume.copyWith(
                      availability: 'available',
                      isRestockedWatchlist: false,
                    );
                    await ref.read(volumesNotifierProvider.notifier).saveVolume(updated);
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context)
                        ..clearSnackBars()
                        ..showSnackBar(
                        SnackBar(
                          content: Text('${series.title} $itemLabel marked as Available!'),
                          backgroundColor: AppColors.caramelizedAmber,
                        ),
                      );
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.warning_amber_rounded, color: AppColors.statusWarning),
                  title: const Text('Out of Stock (OOS)'),
                  subtitle: const Text('Temporarily sold out at retailers'),
                  onTap: () async {
                    final updated = volume.copyWith(
                      availability: 'outOfStock',
                      isRestockedWatchlist: true,
                    );
                    await ref.read(volumesNotifierProvider.notifier).saveVolume(updated);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.block_rounded, color: AppColors.statusDanger),
                  title: const Text('Out of Print (OOP)'),
                  subtitle: const Text('No longer in standard production'),
                  onTap: () async {
                    final updated = volume.copyWith(
                      availability: 'outOfPrint',
                      isRestockedWatchlist: true,
                    );
                    await ref.read(volumesNotifierProvider.notifier).saveVolume(updated);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.notifications_off_outlined),
                  title: const Text('Remove from Watchlist'),
                  onTap: () async {
                    final updated = volume.copyWith(
                      isRestockedWatchlist: false,
                    );
                    await ref.read(volumesNotifierProvider.notifier).saveVolume(updated);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  Widget _buildCustomDashboard(BuildContext context, WidgetRef ref, Profile profile, bool isDark, List<Series> allSeries) {
    final theme = Theme.of(context);
    final terms = profile.terms;
    final allCustom = allSeries.map((s) => CustomItem.fromSeries(s)).toList();
    final availableStatuses = terms.availableStatuses;

    // Group items by status
    final statusMap = <String, List<CustomItem>>{};
    for (final st in availableStatuses) {
      statusMap[st.key] = [];
    }
    for (final item in allCustom) {
      statusMap.putIfAbsent(item.status, () => []).add(item);
    }

    final totalItems = allCustom.length;
    final isPriceOn = terms.isFieldEnabled('price');
    final totalValue = isPriceOn
        ? allCustom.fold<double>(0.0, (sum, item) => sum + (item.price ?? 0.0))
        : 0.0;

    // Pick top statuses for metric cards
    final primaryStatus = availableStatuses.length > 2
        ? availableStatuses[2]
        : (availableStatuses.isNotEmpty ? availableStatuses.last : null);
    final secondaryStatus = availableStatuses.isNotEmpty ? availableStatuses.first : null;

    final primaryCount = primaryStatus != null ? (statusMap[primaryStatus.key]?.length ?? 0) : 0;
    final secondaryCount = secondaryStatus != null ? (statusMap[secondaryStatus.key]?.length ?? 0) : 0;
    final completionRatio = totalItems > 0 ? (primaryCount / totalItems) : 0.0;

    // Distinct groups/creators
    final groupCount = allCustom
        .map((i) => i.groupTitle)
        .where((g) => g != null && g.trim().isNotEmpty)
        .toSet()
        .length;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Metric Header Row 1
          Row(
            children: [
              Expanded(
                child: _HeaderMetricCard(
                  label: 'Total ${terms.itemsLabel}',
                  value: '$totalItems',
                  icon: Icons.category_rounded,
                  subtitle: totalValue > 0 ? '\$${totalValue.toStringAsFixed(0)} catalog value' : 'Catalog size',
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeaderMetricCard(
                  label: primaryStatus?.label ?? 'Completed',
                  value: '$primaryCount',
                  icon: primaryStatus?.icon ?? Icons.check_circle_outline_rounded,
                  subtitle: '${(completionRatio * 100).toStringAsFixed(0)}% of total',
                  onTap: () {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Metric Header Row 2
          Row(
            children: [
              if (secondaryStatus != null)
                Expanded(
                  child: _HeaderMetricCard(
                    label: secondaryStatus.label,
                    value: '$secondaryCount',
                    icon: secondaryStatus.icon,
                    subtitle: 'Pending / Planned',
                    onTap: () {},
                  ),
                ),
              if (secondaryStatus != null) const SizedBox(width: 10),
              Expanded(
                child: _HeaderMetricCard(
                  label: 'Total ${terms.groupLabel}s',
                  value: '$groupCount',
                  icon: Icons.collections_bookmark_rounded,
                  subtitle: 'Unique creators',
                  onTap: () {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 2. Status Distribution Card
          CaneleCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${terms.itemLabel} Distribution',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      '$totalItems Total',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: AppColors.caramelizedAmber,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (totalItems == 0)
                  Text(
                    'No ${terms.itemsLabel.toLowerCase()} in this workspace yet.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextMuted : AppColors.deepCaramelMuted,
                    ),
                  )
                else ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      height: 8,
                      child: Row(
                        children: availableStatuses.map((st) {
                          final count = statusMap[st.key]?.length ?? 0;
                          if (count == 0) return const SizedBox.shrink();
                          final flex = (count / totalItems * 1000).toInt();
                          return Flexible(
                            flex: flex,
                            child: Container(color: st.color),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    children: availableStatuses.map((st) {
                      final count = statusMap[st.key]?.length ?? 0;
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: st.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${st.label}: $count',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextMuted : AppColors.deepCaramelMuted,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3. Spotlight / Recent Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent ${terms.itemsLabel}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              if (allCustom.isNotEmpty)
                Text(
                  '${allCustom.length} total',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.caramelizedAmber,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          if (allCustom.isEmpty)
            CaneleCard(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.folder_special_outlined,
                      size: 36,
                      color: isDark ? AppColors.darkTextMuted : AppColors.deepCaramelMuted,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'No ${terms.itemsLabel.toLowerCase()} tracked yet.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? AppColors.darkTextMuted : AppColors.deepCaramelMuted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => showAddCustomItemSheet(context, profile),
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: Text('Add ${terms.itemLabel}'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.caramelizedAmber,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: allCustom.take(5).map((item) {
                final statusMeta = terms.resolveStatus(item.status);
                return CaneleCard(
                  key: Key('custom_item_dash_${item.id}'),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  onTap: () => showAddCustomItemSheet(context, profile, existingItem: item),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: statusMeta.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(statusMeta.icon, color: statusMeta.color, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (item.groupTitle != null && item.groupTitle!.isNotEmpty)
                              Text(
                                item.groupTitle!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? AppColors.darkTextMuted : AppColors.deepCaramelMuted,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusMeta.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          statusMeta.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: statusMeta.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final metrics = ref.watch(dashboardMetricsProvider);
    final quotaSummary = ref.watch(quotaProvider);
    final recommendationSlots = ref.watch(recommendationSlotsProvider);
    final allVolumes = ref.watch(volumesNotifierProvider);
    final allSeries = ref.watch(seriesNotifierProvider);
    final rules = ref.watch(rulesNotifierProvider);
    final hasActiveRules = rules.any((r) => r.isEnabled);

    final now = DateTime.now();
    final nextMonthLimit = DateTime(now.year, now.month + 2, 1);

    final watchlistVolumes = allVolumes.where((v) {
      if (v.isOwned) return false;

      // 1. Out of stock
      if (v.availability == 'outOfStock') return true;

      // 2. Out of print
      if (v.availability == 'outOfPrint') return true;

      // 3. Upcoming releases in the next month
      if (v.releaseDate != null &&
          v.releaseDate!.isAfter(now) &&
          v.releaseDate!.isBefore(nextMonthLimit)) {
        return true;
      }

      // 4. Released books still marked announced — needs a status update
      if (v.releaseDate != null &&
          !v.releaseDate!.isAfter(now) &&
          v.availability == 'announced') {
        return true;
      }

      return false;
    }).toList()
      ..sort((a, b) {
        // Group priority: OOS=0, OOP=1, Announced/needs-update=2, Upcoming=3
        int groupOf(Volume v) {
          if (v.availability == 'outOfStock') return 0;
          if (v.availability == 'outOfPrint') return 1;
          final needsUpdate = v.releaseDate != null &&
              !v.releaseDate!.isAfter(now) &&
              v.availability == 'announced';
          if (needsUpdate) return 2;
          return 3; // upcoming
        }

        final ga = groupOf(a);
        final gb = groupOf(b);
        if (ga != gb) return ga.compareTo(gb);

        // Within upcoming group: sort by release date ascending
        if (ga == 3 && a.releaseDate != null && b.releaseDate != null) {
          final dateCmp = a.releaseDate!.compareTo(b.releaseDate!);
          if (dateCmp != 0) return dateCmp;
        }

        // Tiebreaker: volume number ascending
        return a.volumeNumber.compareTo(b.volumeNumber);
      });

    final activeProfile = ref.watch(profileNotifierProvider).activeProfile;
    final isGames = activeProfile.type == ProfileType.games;
    final isCustom = activeProfile.type == ProfileType.custom;

    if (isGames) {
      return const GameDashboardView();
    }

    if (isCustom) {
      return Scaffold(
        appBar: AppBar(
          title: const WorkspaceSwitcherAppBarTitle(fallbackTitle: 'Dashboard'),
        ),
        body: _buildCustomDashboard(context, ref, activeProfile, isDark, allSeries),
        floatingActionButton: FloatingActionButton(
          key: const Key('dashboard_add_custom_fab'),
          onPressed: () => showAddCustomItemSheet(context, activeProfile),
          backgroundColor: AppColors.caramelizedAmber,
          foregroundColor: Colors.white,
          tooltip: 'Add ${activeProfile.terms.itemLabel}',
          child: const Icon(Icons.add_rounded),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const WorkspaceSwitcherAppBarTitle(fallbackTitle: 'Dashboard'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              // 1. Metric Header Row
              Row(
                children: [
                  Expanded(
                    child: _HeaderMetricCard(
                      label: 'Total Owned',
                      value: '${metrics.totalOwned}',
                      icon: isGames ? Icons.sports_esports_rounded : Icons.auto_stories_rounded,
                      subtitle: isGames ? 'Games & DLCs' : 'Physical volumes',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const StatsScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _HeaderMetricCard(
                      label: isGames ? 'Game Series' : 'Active Series',
                      value: '${metrics.activeSeriesCount}',
                      icon: isGames ? Icons.category_rounded : Icons.collections_bookmark_rounded,
                      subtitle: isGames ? 'In library' : 'In collection',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const StatsScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 2. Quota & Credit Engine Card
              QuotaStatusCard(
                summary: quotaSummary,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const StatsScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              // 3. Recommendation Pipeline Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Monthly Acquisition Targets',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Deterministic multi-pass priority queue (4 slots)',
                          style: theme.textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkPastryCardElevated : AppColors.pastryCrustLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.pastryCrustBorder, width: 0.8),
                    ),
                    child: Text(
                      '${recommendationSlots.length} / 4 Filled',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.caramelizedAmber,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (recommendationSlots.isEmpty)
                CaneleCard(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          !hasActiveRules
                              ? Icons.tune_rounded
                              : Icons.check_circle_outline_rounded,
                          size: 40,
                          color: isDark ? AppColors.caramelizedAmberLight : AppColors.caramelizedAmber,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          !hasActiveRules
                              ? 'No Active Rules Configured'
                              : 'All Caught Up!',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          !hasActiveRules
                              ? 'Set up recommendation rules in Rule Studio to generate target recommendations.'
                              : (isGames
                                  ? 'No missing released games matching current recommendation passes.'
                                  : 'No missing released volumes matching current recommendation passes.'),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...recommendationSlots.map((slot) {
                  return RecommendationSlotCard(
                    slot: slot,
                    onLogAcquisition: () {
                      LogTransactionSheet.show(
                        context,
                        series: slot.series,
                        volume: slot.volume,
                      );
                    },
                    onTapSeries: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SeriesDetailScreen(seriesId: slot.series.id),
                        ),
                      );
                    },
                  );
                }),

              const SizedBox(height: 20),

              // 4. Watchlist Section
              if (watchlistVolumes.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Watchlist',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            isGames
                                ? 'Tracking out-of-stock and upcoming game releases'
                                : 'Tracking out-of-stock and upcoming releases',
                            style: theme.textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2C2219) : AppColors.statusWarningBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.statusWarning.withValues(alpha: 0.4),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        '${watchlistVolumes.length} ${watchlistVolumes.length == 1 ? 'Item' : 'Items'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.statusWarning,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...() {
                  final widgets = <Widget>[];
                  String? lastGroup;

                  for (final vol in watchlistVolumes) {
                    final isOOS = vol.availability == 'outOfStock';
                    final isOOP = vol.availability == 'outOfPrint';
                    final needsUpdate = vol.releaseDate != null &&
                        !vol.releaseDate!.isAfter(now) &&
                        vol.availability == 'announced';

                    final group = isOOS
                        ? 'Out of Stock'
                        : isOOP
                            ? 'Out of Print'
                            : needsUpdate
                                ? 'Released · Update Status'
                                : 'Upcoming Releases';

                    if (group != lastGroup) {
                      lastGroup = group;
                      final groupColor = isOOS
                          ? AppColors.statusWarning
                          : isOOP
                              ? AppColors.statusDanger
                              : needsUpdate
                                  ? AppColors.caramelizedAmber
                                  : (isDark ? AppColors.caramelizedAmberLight : AppColors.caramelizedAmber);
                      widgets.add(
                        Padding(
                          padding: const EdgeInsets.only(top: 4, bottom: 6),
                          child: Row(
                            children: [
                              Container(
                                width: 3,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: groupColor,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                group,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: groupColor,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final series = allSeries.firstWhere(
                      (s) => s.id == vol.seriesId,
                      orElse: () => Series(id: vol.seriesId, title: 'Unknown Series', type: 'Manga'),
                    );
                    widgets.add(
                      _WatchlistItemCard(
                        volume: vol,
                        series: series,
                        onUpdateStatus: () => _showUpdateStatusSheet(context, ref, vol, series),
                        onTapSeries: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => SeriesDetailScreen(seriesId: series.id),
                            ),
                          );
                        },
                      ),
                    );
                  }
                  return widgets;
                }(),
              ],

              const SizedBox(height: 80), // Space for FAB
            ],
          ),
        ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => LogTransactionSheet.show(context),
        backgroundColor: AppColors.caramelizedAmber,
        foregroundColor: Colors.white,
        tooltip: isGames ? 'Log Game Acquisition' : 'Log Acquisition',
        child: const Icon(Icons.add_shopping_cart_rounded),
      ),
    );
  }
}

class _WatchlistItemCard extends StatelessWidget {
  final Volume volume;
  final Series series;
  final VoidCallback onUpdateStatus;
  final VoidCallback onTapSeries;

  const _WatchlistItemCard({
    required this.volume,
    required this.series,
    required this.onUpdateStatus,
    required this.onTapSeries,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final now = DateTime.now();

    final isReleasedNeedsUpdate = volume.releaseDate != null &&
        !volume.releaseDate!.isAfter(now) &&
        volume.availability == 'announced';

    final isUpcoming = volume.releaseDate != null &&
        volume.releaseDate!.isAfter(now);

    Color badgeColor;
    Color badgeBg;
    IconData badgeIcon;

    if (isReleasedNeedsUpdate) {
      badgeColor = AppColors.caramelizedAmber;
      badgeBg = isDark ? const Color(0xFF2C2219) : AppColors.warmPastryCrust.withValues(alpha: 0.5);
      badgeIcon = Icons.update_rounded;
    } else if (isUpcoming) {
      badgeColor = isDark ? AppColors.caramelizedAmberLight : AppColors.caramelizedAmber;
      badgeBg = isDark ? AppColors.darkPastryCardElevated : AppColors.pastryCrustLight;
      badgeIcon = Icons.event_available_rounded;
    } else {
      switch (volume.availability) {
        case 'outOfStock':
          badgeColor = AppColors.statusWarning;
          badgeBg = isDark ? const Color(0xFF2C2219) : AppColors.statusWarningBg;
          badgeIcon = Icons.warning_amber_rounded;
          break;
        case 'outOfPrint':
          badgeColor = AppColors.statusDanger;
          badgeBg = isDark ? const Color(0xFF2C1919) : AppColors.statusDangerBg;
          badgeIcon = Icons.block_rounded;
          break;
        default:
          badgeColor = isDark ? AppColors.caramelizedAmberLight : AppColors.caramelizedAmber;
          badgeBg = isDark ? AppColors.darkPastryCardElevated : AppColors.pastryCrustLight;
          badgeIcon = Icons.notifications_active_rounded;
          break;
      }
    }

    final releaseDateText = isReleasedNeedsUpdate
        ? 'Released on ${DateFormatter.formatDisplay(volume.releaseDate!)}'
        : (isUpcoming
            ? 'Releases ${DateFormatter.formatDisplay(volume.releaseDate!)}'
            : null);

    final customTitle = volume.customMetadata['title'] as String?;
    final itemType = volume.customMetadata['itemType'] as String?;
    final isDlc = itemType == 'dlc';
    final volLabel = customTitle != null && customTitle.isNotEmpty
        ? (isDlc ? 'DLC · $customTitle' : customTitle)
        : 'Vol. ${DateFormatter.formatVolumeNumber(volume.volumeNumber)}';

    return CaneleCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      margin: const EdgeInsets.only(bottom: 8),
      onTap: onTapSeries,
      child: Row(
        children: [
          // Icon badge
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(
              badgeIcon,
              size: 20,
              color: badgeColor,
            ),
          ),
          const SizedBox(width: 12),

          // Series Title, Volume Info & Release Date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  series.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      volLabel,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.deepCaramel,
                      ),
                    ),
                    if (releaseDateText != null) ...[
                      Text(
                        ' · ',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark ? AppColors.darkTextMuted : AppColors.deepCaramelMuted,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          releaseDateText,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 12,
                            color: isReleasedNeedsUpdate
                                ? AppColors.caramelizedAmber
                                : (isDark ? AppColors.darkTextMuted : AppColors.deepCaramelMuted),
                            fontWeight: isReleasedNeedsUpdate ? FontWeight.w600 : FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Update Status Button
          OutlinedButton(
            onPressed: onUpdateStatus,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              visualDensity: VisualDensity.compact,
              side: BorderSide(
                color: AppColors.caramelizedAmber.withValues(alpha: 0.6),
                width: 1,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Update Status',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.caramelizedAmber,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final String subtitle;
  final VoidCallback? onTap;

  const _HeaderMetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return CaneleCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(
                icon,
                size: 18,
                color: isDark ? AppColors.caramelizedAmberLight : AppColors.caramelizedAmber,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkTextPrimary : AppColors.deepCaramel,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}
