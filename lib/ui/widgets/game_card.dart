import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_helper.dart';
import '../../models/game_item.dart';
import 'canele_card.dart';

enum GameCardStyle { grid, list }

class GameCard extends StatelessWidget {
  final GameItem game;
  final GameCardStyle style;
  final VoidCallback? onTap;
  final VoidCallback? onStatusCycle;

  const GameCard({
    super.key,
    required this.game,
    this.style = GameCardStyle.grid,
    this.onTap,
    this.onStatusCycle,
  });

  @override
  Widget build(BuildContext context) {
    if (style == GameCardStyle.list) {
      return _buildListCard(context);
    }
    return _buildGridCard(context);
  }

  Widget _buildGridCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final platform = game.platformInfo;

    return CaneleCard(
      padding: EdgeInsets.zero,
      borderRadius: 18,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 2:3 Cover Poster Section
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildCoverArtwork(context),

                // Top Gradient Overlay for readability
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 60,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.65),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // Platform Badge (Top-Left)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: platform.badgeColor.withValues(alpha: 0.90),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(platform.icon, size: 12, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          platform.displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Format Icon (Top-Right: Physical disc / Digital cloud)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      game.format.icon,
                      size: 13,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ),

                // Bottom Rating / Playtime if set
                if (game.rating != null || game.playtimeHours != null)
                  Positioned(
                    bottom: 6,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (game.rating != null) ...[
                            const Icon(Icons.star_rounded, size: 12, color: Color(0xFFFBBF24)),
                            const SizedBox(width: 2),
                            Text(
                              game.rating!.toStringAsFixed(1),
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ],
                          if (game.rating != null && game.playtimeHours != null)
                            const SizedBox(width: 6),
                          if (game.playtimeHours != null) ...[
                            const Icon(Icons.timer_outlined, size: 11, color: Colors.white70),
                            const SizedBox(width: 2),
                            Text(
                              '${game.playtimeHours!.toStringAsFixed(0)}h',
                              style: const TextStyle(color: Colors.white, fontSize: 10),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Metadata Footer Section
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  game.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    height: 1.15,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Backlog Status Chip (Tappable to cycle)
                    _buildStatusChip(context, isCompact: true),
                    if (game.price != null && game.price! > 0)
                      Text(
                        CurrencyHelper.format(game.price!, currencyCode: game.currency),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextMuted : AppColors.deepCaramelMuted,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final platform = game.platformInfo;

    return CaneleCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      onTap: onTap,
      child: Row(
        children: [
          // 2:3 Aspect ratio cover thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 54,
              height: 78,
              child: _buildCoverArtwork(context),
            ),
          ),
          const SizedBox(width: 14),

          // Game details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  game.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: platform.badgeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        platform.displayName,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: platform.badgeColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      game.edition,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.darkTextMuted : AppColors.deepCaramelMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _buildStatusChip(context, isCompact: false),
                    const Spacer(),
                    if (game.playtimeHours != null && game.playtimeHours! > 0) ...[
                      Icon(Icons.timer_outlined, size: 13, color: isDark ? AppColors.darkTextMuted : AppColors.deepCaramelMuted),
                      const SizedBox(width: 3),
                      Text(
                        '${game.playtimeHours!.toStringAsFixed(1)} hrs',
                        style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextMuted : AppColors.deepCaramelMuted),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (game.price != null && game.price! > 0)
                      Text(
                        CurrencyHelper.format(game.price!, currencyCode: game.currency),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.caramelizedAmberLight : AppColors.caramelizedAmber,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, {required bool isCompact}) {
    final status = game.backlogStatus;

    return InkWell(
      key: Key('game_status_chip_${game.id}'),
      onTap: onStatusCycle,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 7 : 9,
          vertical: isCompact ? 3 : 4,
        ),
        decoration: BoxDecoration(
          color: status.color.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: status.color.withValues(alpha: 0.70),
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(status.icon, size: isCompact ? 11 : 13, color: status.color),
            const SizedBox(width: 4),
            Text(
              status.label,
              style: TextStyle(
                fontSize: isCompact ? 10 : 11,
                fontWeight: FontWeight.w700,
                color: status.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverArtwork(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final platform = game.platformInfo;

    if (game.coverUrl != null && game.coverUrl!.trim().isNotEmpty) {
      return Image.network(
        game.coverUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildPlaceholderPoster(isDark, platform),
        loadingBuilder: (_, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: isDark ? AppColors.darkPastryCardElevated : AppColors.pastryCrustLight,
            child: const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.caramelizedAmber),
              ),
            ),
          );
        },
      );
    }
    return _buildPlaceholderPoster(isDark, platform);
  }

  Widget _buildPlaceholderPoster(bool isDark, GamePlatform platform) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppColors.darkPastryCardElevated,
                  platform.badgeColor.withValues(alpha: 0.35),
                  AppColors.darkPastryCard,
                ]
              : [
                  AppColors.pastryCrustLight,
                  platform.badgeColor.withValues(alpha: 0.15),
                  AppColors.warmPastryCrust,
                ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              platform.icon,
              size: 36,
              color: platform.badgeColor.withValues(alpha: 0.75),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                game.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
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
