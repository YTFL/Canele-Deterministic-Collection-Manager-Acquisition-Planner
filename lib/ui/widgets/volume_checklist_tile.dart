import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_helper.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/volume.dart';
import '../../models/purchase_transaction.dart';
import 'canele_card.dart';

class VolumeChecklistTile extends StatelessWidget {
  final Volume volume;
  final PurchaseTransaction? transaction;
  final String currency;
  final double? defaultVolumePrice;
  final String? defaultVolumeCurrency;
  final ValueChanged<bool>? onToggleOwned;
  final ValueChanged<bool>? onToggleWatchlist;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const VolumeChecklistTile({
    super.key,
    required this.volume,
    this.transaction,
    this.currency = 'USD',
    this.defaultVolumePrice,
    this.defaultVolumeCurrency,
    this.onToggleOwned,
    this.onToggleWatchlist,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color availabilityColor;
    Color availabilityBg;
    String availabilityLabel;

    switch (volume.availability) {
      case 'available':
        availabilityColor = isDark ? AppColors.caramelizedAmberLight : AppColors.caramelizedAmber;
        availabilityBg = isDark ? AppColors.darkPastryCardElevated : AppColors.warmPastryCrust.withValues(alpha: 0.5);
        availabilityLabel = 'Available';
        break;
      case 'outOfStock':
        availabilityColor = AppColors.statusWarning;
        availabilityBg = isDark ? const Color(0xFF2C2219) : AppColors.statusWarningBg;
        availabilityLabel = 'Out of Stock';
        break;
      case 'outOfPrint':
        availabilityColor = AppColors.statusDanger;
        availabilityBg = isDark ? const Color(0xFF2C1919) : AppColors.statusDangerBg;
        availabilityLabel = 'Out of Print';
        break;
      case 'announced':
      default:
        availabilityColor = isDark ? AppColors.darkTextMuted : AppColors.deepCaramelMuted;
        availabilityBg = isDark ? AppColors.darkPastryCardElevated : AppColors.pastryCrustLight;
        availabilityLabel = 'Announced';
        break;
    }

    final isGift = volume.isOwned && volume.isGift;
    final hasSpecificPrice = (transaction != null && transaction!.price > 0) || (volume.price != null && volume.price! > 0);
    final defPrice = defaultVolumePrice ?? CurrencyHelper.defaultVolumePrice;
    final defCurr = defaultVolumeCurrency ?? CurrencyHelper.defaultVolumeCurrency;
    final hasDefaultPrice = defPrice > 0;
    final hasPriceInfo = !isGift && (hasSpecificPrice || hasDefaultPrice);

    final formattedPrice = hasSpecificPrice
        ? CurrencyHelper.format(
            (transaction != null && transaction!.price > 0) ? transaction!.price : volume.price!,
            currencyCode: transaction?.currency ?? volume.currency ?? currency,
          )
        : CurrencyHelper.format(defPrice, currencyCode: defCurr);

    final showAvailabilityBadge = !volume.isOwned;
    final showGiftBadge = isGift;
    final showSecondRow = showAvailabilityBadge || showGiftBadge || hasPriceInfo;

    return CaneleCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Quick Owned Checkbox Toggle
          IconButton(
            onPressed: () => onToggleOwned?.call(!volume.isOwned),
            icon: Icon(
              volume.isOwned
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: volume.isOwned
                  ? (isDark ? AppColors.caramelizedAmberLight : AppColors.caramelizedAmber)
                  : (isDark ? AppColors.darkTextMuted : AppColors.pastryCrustBorder),
              size: 26,
            ),
          ),
          const SizedBox(width: 8),

          // Details Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top row: Volume title
                Row(
                  children: [
                    Text(
                      'Vol. ${DateFormatter.formatVolumeNumber(volume.volumeNumber)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),

                // Next row: Availability tag / Gift tag and clean price typography
                if (showSecondRow) ...[
                  const SizedBox(height: 5),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (showGiftBadge)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkPastryCardElevated : AppColors.pastryCrustLight,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isDark ? AppColors.darkPastryBorder : AppColors.pastryCrustBorder,
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            'GIFT',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppColors.caramelizedAmberLight : AppColors.caramelizedAmber,
                            ),
                          ),
                        ),

                      if (showAvailabilityBadge)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: availabilityBg,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            availabilityLabel.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: availabilityColor,
                            ),
                          ),
                        ),

                      if (hasPriceInfo)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              formattedPrice,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: hasSpecificPrice
                                    ? (isDark ? AppColors.darkTextPrimary : AppColors.deepCaramel)
                                    : (isDark ? AppColors.darkTextMuted : AppColors.deepCaramelMuted),
                              ),
                            ),
                            if (!hasSpecificPrice && hasDefaultPrice)
                              Text(
                                ' (Default)',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                  color: isDark ? AppColors.darkTextMuted : AppColors.deepCaramelMuted,
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Quick Watchlist Toggle (Hidden for owned volumes)
          if (!volume.isOwned)
            IconButton(
              onPressed: () => onToggleWatchlist?.call(!volume.isRestockedWatchlist),
              tooltip: volume.isRestockedWatchlist ? 'Remove from Watchlist' : 'Add to Watchlist',
              icon: Icon(
                volume.isRestockedWatchlist
                    ? Icons.notifications_active_rounded
                    : Icons.notifications_none_rounded,
                color: volume.isRestockedWatchlist
                    ? AppColors.statusWarning
                    : (isDark ? AppColors.darkTextMuted : AppColors.deepCaramelMuted),
                size: 20,
              ),
            ),

          // Menu for Edit / Delete
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert_rounded,
              color: isDark ? AppColors.darkTextMuted : AppColors.deepCaramelMuted,
              size: 20,
            ),
            onSelected: (value) {
              if (value == 'edit') onEdit?.call();
              if (value == 'delete') onDelete?.call();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Edit Volume'),
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
    );
  }
}
