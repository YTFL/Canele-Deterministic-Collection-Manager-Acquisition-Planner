import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../services/rule_evaluator.dart';
import 'canele_card.dart';

class RecommendationSlotCard extends StatelessWidget {
  final RecommendationSlot slot;
  final VoidCallback? onLogAcquisition;
  final VoidCallback? onTapSeries;

  const RecommendationSlotCard({
    super.key,
    required this.slot,
    this.onLogAcquisition,
    this.onTapSeries,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return CaneleCard(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 10),
      onTap: onTapSeries,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Slot Number Badge
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkPastryCardElevated
                  : AppColors.pastryCrustLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.caramelizedAmber.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              '#${slot.slotIndex + 1}',
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.caramelizedAmber,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Series Title & Volume Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        slot.series.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Volume / Game item label chip
                Builder(
                  builder: (context) {
                    final customTitle = slot.volume.customMetadata['title'] as String?;
                    final itemType = slot.volume.customMetadata['itemType'] as String?;
                    final isDlc = itemType == 'dlc';
                    final isGame = slot.series.customMetadata['isGame'] == true || slot.volume.customMetadata['isGame'] == true;
                    final itemLabel = (customTitle != null && customTitle.isNotEmpty)
                        ? (isDlc ? '[DLC] $customTitle' : customTitle)
                        : (isGame
                            ? 'Game #${DateFormatter.formatVolumeNumber(slot.volume.volumeNumber)}'
                            : 'Vol. ${DateFormatter.formatVolumeNumber(slot.volume.volumeNumber)}');

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDlc
                            ? AppColors.caramelizedAmber.withValues(alpha: 0.22)
                            : AppColors.caramelizedAmber.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        itemLabel,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.caramelizedAmber,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Log Acquisition Button
          IconButton(
            onPressed: onLogAcquisition,
            tooltip: 'Log Purchase/Gift',
            style: IconButton.styleFrom(
              backgroundColor: AppColors.caramelizedAmber,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(8),
            ),
            icon: const Icon(Icons.check_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}
