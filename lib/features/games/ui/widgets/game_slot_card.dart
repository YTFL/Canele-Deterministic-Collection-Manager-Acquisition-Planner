import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../ui/widgets/canele_card.dart';
import '../../models/game_item.dart';
import '../../services/game_rule_evaluator.dart';
import '../screens/game_detail_screen.dart';

class GameSlotCard extends StatelessWidget {
  final GameRecommendationSlot slot;
  final VoidCallback? onLogAcquisition;

  const GameSlotCard({
    super.key,
    required this.slot,
    this.onLogAcquisition,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDlc = slot.item.itemType == GameItemType.dlc;

    return CaneleCard(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 10),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => GameDetailScreen(seriesId: slot.series.id),
          ),
        );
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Slot Number Badge
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkPastryCardElevated : AppColors.pastryCrustLight,
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

          // Series Title & Item Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slot.series.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                // Item Badge + Title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDlc
                            ? AppColors.caramelizedAmber.withValues(alpha: 0.22)
                            : AppColors.caramelizedAmber.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isDlc ? 'DLC' : 'GAME',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.caramelizedAmber,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        slot.item.title,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.deepCaramel,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Match Reason
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.statusSuccess.withValues(alpha: isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.statusSuccess.withValues(alpha: isDark ? 0.4 : 0.3),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    slot.reason,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.statusSuccess,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Action Button: Log Acquisition
          if (onLogAcquisition != null) ...[
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: onLogAcquisition,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.caramelizedAmber,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Acquire', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ],
        ],
      ),
    );
  }
}
