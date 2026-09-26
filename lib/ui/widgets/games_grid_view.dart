import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/game_item.dart';
import 'game_card.dart';

class GamesCollectionView extends StatelessWidget {
  final List<GameItem> games;
  final GameCardStyle viewStyle;
  final String emptyMessage;
  final VoidCallback? onAddGame;
  final ValueChanged<GameItem> onGameTap;
  final ValueChanged<GameItem> onStatusCycle;

  const GamesCollectionView({
    super.key,
    required this.games,
    required this.viewStyle,
    required this.emptyMessage,
    this.onAddGame,
    required this.onGameTap,
    required this.onStatusCycle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (games.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkPastryCardElevated : AppColors.pastryCrustLight,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? AppColors.darkPastryBorder : AppColors.pastryCrustBorder,
                  ),
                ),
                child: const Icon(
                  Icons.sports_esports_rounded,
                  size: 32,
                  color: AppColors.caramelizedAmber,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppColors.darkTextMuted : AppColors.deepCaramelMuted,
                  fontSize: 14,
                ),
              ),
              if (onAddGame != null) ...[
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: onAddGame,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add Game'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.caramelizedAmber,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (viewStyle == GameCardStyle.list) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: games.length,
        itemBuilder: (context, index) {
          final game = games[index];
          return GameCard(
            key: Key('game_card_${game.id}'),
            game: game,
            style: GameCardStyle.list,
            onTap: () => onGameTap(game),
            onStatusCycle: () => onStatusCycle(game),
          );
        },
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 700
            ? 4
            : (constraints.maxWidth > 480 ? 3 : 2);

        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.60,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: games.length,
          itemBuilder: (context, index) {
            final game = games[index];
            return GameCard(
              key: Key('game_card_${game.id}'),
              game: game,
              style: GameCardStyle.grid,
              onTap: () => onGameTap(game),
              onStatusCycle: () => onStatusCycle(game),
            );
          },
        );
      },
    );
  }
}
