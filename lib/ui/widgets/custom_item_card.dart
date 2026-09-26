import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_helper.dart';
import '../../core/utils/workspace_terminology.dart';
import '../../models/custom_item.dart';
import '../../models/profile.dart';
import 'canele_card.dart';

enum CustomCardStyle { grid, list }

class CustomItemCard extends StatelessWidget {
  final CustomItem item;
  final Profile profile;
  final CustomCardStyle style;
  final VoidCallback? onTap;
  final VoidCallback? onStatusCycle;

  const CustomItemCard({
    super.key,
    required this.item,
    required this.profile,
    this.style = CustomCardStyle.grid,
    this.onTap,
    this.onStatusCycle,
  });

  @override
  Widget build(BuildContext context) {
    if (style == CustomCardStyle.list) {
      return _buildListCard(context);
    }
    return _buildGridCard(context);
  }

  Widget _buildGridCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final terms = profile.terms;
    final showCover = terms.isFieldEnabled('coverUrl');
    final showPrice = terms.isFieldEnabled('price') && item.price != null && item.price! > 0;
    final statusDef = terms.resolveStatus(item.status);

    return CaneleCard(
      padding: EdgeInsets.zero,
      borderRadius: 16,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Optional Poster Cover
          if (showCover)
            AspectRatio(
              aspectRatio: 1.0,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: _buildCoverArtwork(context),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (item.groupTitle != null && item.groupTitle!.isNotEmpty) ...[
                  Text(
                    item.groupTitle!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextMuted : AppColors.deepCaramelMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  item.title,
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
                    _buildStatusChip(statusDef, isCompact: true),
                    if (showPrice)
                      Text(
                        CurrencyHelper.format(item.price!, currencyCode: item.currency),
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
    final terms = profile.terms;
    final showCover = terms.isFieldEnabled('coverUrl');
    final showPrice = terms.isFieldEnabled('price') && item.price != null && item.price! > 0;
    final showRating = terms.isFieldEnabled('rating') && item.rating != null && item.rating! > 0;
    final statusDef = terms.resolveStatus(item.status);

    return CaneleCard(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 10),
      onTap: onTap,
      child: Row(
        children: [
          // Optional Thumbnail Cover
          if (showCover) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 52,
                height: 52,
                child: _buildCoverArtwork(context),
              ),
            ),
            const SizedBox(width: 12),
          ],

          // Details Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.groupTitle != null && item.groupTitle!.isNotEmpty) ...[
                  Text(
                    item.groupTitle!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextMuted : AppColors.deepCaramelMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  item.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.edition != null && item.edition!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.edition!,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.darkTextMuted : AppColors.deepCaramelMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    _buildStatusChip(statusDef, isCompact: false),
                    if (item.platform != null && item.platform!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkPastryBorder : AppColors.pastryCrustLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.platform!,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.deepCaramelMuted),
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (showRating) ...[
                      const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFBBF24)),
                      const SizedBox(width: 2),
                      Text(
                        item.rating!.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (showPrice)
                      Text(
                        CurrencyHelper.format(item.price!, currencyCode: item.currency),
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

  Widget _buildStatusChip(CustomStatusDefinition status, {required bool isCompact}) {
    return InkWell(
      key: Key('custom_status_chip_${item.id}'),
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

    if (item.coverUrl != null && item.coverUrl!.trim().isNotEmpty) {
      return Image.network(
        item.coverUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildPlaceholderPoster(isDark),
      );
    }
    return _buildPlaceholderPoster(isDark);
  }

  Widget _buildPlaceholderPoster(bool isDark) {
    return Container(
      color: isDark ? AppColors.darkPastryCardElevated : AppColors.pastryCrustLight,
      alignment: Alignment.center,
      child: Icon(
        Icons.category_rounded,
        size: 28,
        color: isDark ? AppColors.caramelizedAmberLight : AppColors.caramelizedAmber,
      ),
    );
  }
}
