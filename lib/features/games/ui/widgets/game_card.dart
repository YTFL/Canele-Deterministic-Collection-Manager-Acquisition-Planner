import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/uuid_generator.dart';
import '../../../../ui/widgets/canele_card.dart';
import '../../../../ui/widgets/canele_progress_bar.dart';
import '../../models/game_item.dart';
import '../../models/game_series.dart';
import '../../providers/game_providers.dart';
import '../screens/game_detail_screen.dart';
import '../sheets/edit_game_series_sheet.dart';

class GameCard extends ConsumerWidget {
  final GameSeries series;

  const GameCard({super.key, required this.series});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final allItems = ref.watch(gameItemsNotifierProvider);
    final seriesItems = allItems.where((i) => i.seriesId == series.id).toList();
    final games = seriesItems.where((i) => i.itemType == GameItemType.game).toList()
      ..sort((a, b) => a.gameNumber.compareTo(b.gameNumber));
    final dlcs = seriesItems.where((i) => i.itemType == GameItemType.dlc).toList();

    final ownedGamesCount = games.where((i) => i.isOwned).length;
    final totalGamesCount = games.length;

    // Standalone progress is 1/1 if owned, 0/1 if unowned. Franchise is ownedGames/totalGames.
    final progressRatio = series.isStandalone
        ? (ownedGamesCount > 0 ? 1.0 : 0.0)
        : (totalGamesCount > 0 ? (ownedGamesCount / totalGamesCount) : 0.0);

    // Find next unowned item (first unowned game, or unowned DLC)
    GameItem? nextMissingItem;
    for (final g in games) {
      if (!g.isOwned) {
        nextMissingItem = g;
        break;
      }
    }
    if (nextMissingItem == null) {
      for (final d in dlcs) {
        if (!d.isOwned) {
          nextMissingItem = d;
          break;
        }
      }
    }

    return CaneleCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => GameDetailScreen(seriesId: series.id),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Title, Badge, Quick Add, Popup Menu
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  series.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),

              // Structure Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkPastryCardElevated : AppColors.pastryCrustLight,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.pastryCrustBorder, width: 0.8),
                ),
                child: Text(
                  series.isStandalone ? 'STANDALONE' : 'GAME SERIES',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 4),

              // Quick Add Next Installment for Franchises
              if (!series.isStandalone)
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    double maxNum = 0.0;
                    for (final g in games) {
                      if (g.gameNumber > maxNum) maxNum = g.gameNumber;
                    }
                    final nextNum = maxNum > 0 ? (maxNum + 1.0) : 1.0;
                    final newItem = GameItem(
                      id: UuidGenerator.generate(),
                      seriesId: series.id,
                      title: '${series.title} ${nextNum.toInt()}',
                      itemType: GameItemType.game,
                      gameNumber: nextNum,
                      isOwned: false,
                      price: series.defaultGamePrice,
                      currency: series.defaultCurrency,
                    );
                    await ref.read(gameItemsNotifierProvider.notifier).saveItem(newItem);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context)
                        ..clearSnackBars()
                        ..showSnackBar(
                          SnackBar(
                            content: Text('Added "${newItem.title}" to ${series.title}'),
                            backgroundColor: AppColors.caramelizedAmber,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                    }
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.add_circle_outline_rounded,
                      size: 18,
                      color: AppColors.caramelizedAmber,
                    ),
                  ),
                ),

              // Popup Menu: Edit, Mark Complete, Delete
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.more_vert_rounded, size: 18, color: AppColors.caramelizedAmber),
                onSelected: (val) async {
                  if (val == 'edit') {
                    EditGameSeriesSheet.show(context, series: series);
                  } else if (val == 'complete') {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text('Mark ${series.title} as Completed?'),
                        content: Text(
                          'Are you sure you want to mark "${series.title}" as completed?\n\n'
                          'This will mark all ${seriesItems.length} games and DLCs as acquired and move this into the Acquired collection.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.caramelizedAmber),
                            child: const Text('Mark Completed'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      for (final it in seriesItems) {
                        if (!it.isOwned) {
                          await ref.read(gameItemsNotifierProvider.notifier).toggleOwned(it.id, true);
                        }
                      }
                      await ref.read(gameSeriesNotifierProvider.notifier).markCompleted(series.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context)
                          ..clearSnackBars()
                          ..showSnackBar(
                            SnackBar(
                              content: Text('Marked "${series.title}" as Acquired / Completed!'),
                              backgroundColor: AppColors.statusSuccess,
                            ),
                          );
                      }
                    }
                  } else if (val == 'delete') {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text('Delete "${series.title}"?'),
                        content: const Text(
                          'Are you sure you want to delete this game collection? All its tracked installments and items will be deleted. This cannot be undone.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusDanger),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      for (final it in seriesItems) {
                        await ref.read(gameItemsNotifierProvider.notifier).deleteItem(it.id);
                      }
                      await ref.read(gameSeriesNotifierProvider.notifier).deleteSeries(series.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context)
                          ..clearSnackBars()
                          ..showSnackBar(
                            SnackBar(
                              content: Text('Deleted "${series.title}"'),
                              backgroundColor: AppColors.statusDanger,
                            ),
                          );
                      }
                    }
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18, color: AppColors.caramelizedAmber),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  if (series.collectionStatus != 'completed')
                    const PopupMenuItem(
                      value: 'complete',
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline_rounded, size: 18, color: AppColors.caramelizedAmber),
                          SizedBox(width: 8),
                          Text('Mark as Completed'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 18, color: AppColors.statusDanger),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: AppColors.statusDanger)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Progress Row: Owned count on left, Next Missing Item badge on right
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                series.isStandalone
                    ? (ownedGamesCount > 0 ? '1/1 Owned' : '0/1 Owned')
                    : '$ownedGamesCount/$totalGamesCount Owned',
                style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              if (nextMissingItem != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.caramelizedAmber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Next: ${nextMissingItem.title}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.caramelizedAmber,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),

          // Progress Bar with percentage
          CaneleProgressBar(
            value: progressRatio,
            showPercentage: true,
          ),
        ],
      ),
    );
  }
}
