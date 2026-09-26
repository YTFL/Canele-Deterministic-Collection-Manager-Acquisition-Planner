import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_helper.dart';
import '../../models/game_item.dart';
import '../../providers/series_provider.dart';
import '../widgets/add_game_sheet.dart';
import '../widgets/canele_card.dart';

class GameDetailScreen extends ConsumerWidget {
  final String gameId;

  const GameDetailScreen({super.key, required this.gameId});

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, GameItem game) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Game'),
        content: Text('Are you sure you want to remove "${game.title}" from your collection?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            key: const Key('confirm_delete_game_button'),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(seriesNotifierProvider.notifier).deleteSeries(game.id);
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Removed "${game.title}"'),
                    backgroundColor: AppColors.caramelizedAmber,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusDanger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _changeBacklogStatus(BuildContext context, WidgetRef ref, GameItem game, GameBacklogStatus newStatus) async {
    final updated = game.copyWith(backlogStatus: newStatus);
    await ref.read(seriesNotifierProvider.notifier).saveSeries(updated.toSeries());

    if (context.mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status updated to ${newStatus.label}'),
          backgroundColor: newStatus.color,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _incrementPlaytime(BuildContext context, WidgetRef ref, GameItem game) async {
    final current = game.playtimeHours ?? 0.0;
    final updated = game.copyWith(playtimeHours: current + 1.0);
    await ref.read(seriesNotifierProvider.notifier).saveSeries(updated.toSeries());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final allSeries = ref.watch(seriesNotifierProvider);
    final match = allSeries.where((s) => s.id == gameId).firstOrNull;

    if (match == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Game Details')),
        body: const Center(child: Text('Game not found')),
      );
    }

    final game = GameItem.fromSeries(match);
    final platform = game.platformInfo;
    final status = game.backlogStatus;

    return Scaffold(
      appBar: AppBar(
        title: Text(game.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            key: const Key('edit_game_button'),
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Game',
            onPressed: () => showAddGameSheet(context, existingGame: game),
          ),
          IconButton(
            key: const Key('delete_game_button'),
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Delete Game',
            onPressed: () => _showDeleteConfirmation(context, ref, game),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Header Card (Cover artwork + basic info)
            CaneleCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2:3 Cover Poster
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: 100,
                      height: 145,
                      child: game.coverUrl != null && game.coverUrl!.trim().isNotEmpty
                          ? Image.network(
                              game.coverUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => _buildPlaceholderPoster(isDark, platform, game.title),
                            )
                          : _buildPlaceholderPoster(isDark, platform, game.title),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Header Meta details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          game.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          game.edition,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkTextMuted : AppColors.deepCaramelMuted,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Badges Row
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: platform.badgeColor.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: platform.badgeColor.withValues(alpha: 0.4)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(platform.icon, size: 12, color: platform.badgeColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    platform.displayName,
                                    style: TextStyle(
                                      color: platform.badgeColor,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkPastryBorder : AppColors.pastryCrustLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(game.format.icon, size: 12, color: AppColors.deepCaramelMuted),
                                  const SizedBox(width: 4),
                                  Text(
                                    game.format.label,
                                    style: TextStyle(
                                      color: isDark ? AppColors.darkTextPrimary : AppColors.deepCaramel,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Price
                        if (game.price != null && game.price! > 0)
                          Text(
                            CurrencyHelper.format(game.price!, currencyCode: game.currency),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.caramelizedAmber,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Backlog Status Interactive Card
            CaneleCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Playthrough Status',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: status.color.withValues(alpha: 0.20),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: status.color.withValues(alpha: 0.8)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(status.icon, size: 14, color: status.color),
                            const SizedBox(width: 5),
                            Text(
                              status.label,
                              style: TextStyle(
                                color: status.color,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  // Quick Switch Chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: GameBacklogStatus.values.map((s) {
                      final isSelected = s == status;
                      return ChoiceChip(
                        key: Key('detail_status_chip_${s.name}'),
                        label: Text(s.label),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) _changeBacklogStatus(context, ref, game, s);
                        },
                        selectedColor: s.color,
                        labelStyle: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? AppColors.darkTextPrimary : AppColors.deepCaramel),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Playtime & Rating
            Row(
              children: [
                // Playtime Card
                Expanded(
                  child: CaneleCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Playtime',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.darkTextMuted : AppColors.deepCaramelMuted,
                              ),
                            ),
                            InkWell(
                              onTap: () => _incrementPlaytime(context, ref, game),
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.caramelizedAmber.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  '+1 hr',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.caramelizedAmber),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          game.playtimeHours != null ? '${game.playtimeHours!.toStringAsFixed(1)} hrs' : '0.0 hrs',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Rating Card
                Expanded(
                  child: CaneleCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rating',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextMuted : AppColors.deepCaramelMuted,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 22, color: Color(0xFFFBBF24)),
                            const SizedBox(width: 4),
                            Text(
                              game.rating != null ? '${game.rating!.toStringAsFixed(1)} / 10' : 'Unrated',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Notes Section
            if (game.notes != null && game.notes!.trim().isNotEmpty) ...[
              CaneleCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.notes_rounded, size: 18, color: AppColors.caramelizedAmber),
                        const SizedBox(width: 8),
                        Text(
                          'Notes & Thoughts',
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      game.notes!,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderPoster(bool isDark, GamePlatform platform, String title) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkPastryCardElevated : AppColors.pastryCrustLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(platform.icon, size: 38, color: platform.badgeColor),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.deepCaramel,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
