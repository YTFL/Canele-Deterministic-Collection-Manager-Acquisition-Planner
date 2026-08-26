import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/rule_model.dart';
import 'canele_card.dart';

class RuleCard extends StatelessWidget {
  final RuleModel rule;
  final int displayIndex;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggleEnabled;

  const RuleCard({
    super.key,
    required this.rule,
    required this.displayIndex,
    required this.onTap,
    required this.onToggleEnabled,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return CaneleCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Priority Badge + Name + Switch + Drag Handle
          Row(
            children: [
              // Priority Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: rule.isEnabled
                      ? AppColors.caramelizedAmber
                      : (isDark ? AppColors.darkPastryBorder : AppColors.pastryCrustBorder),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '#${displayIndex + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Rule Name
              Expanded(
                child: Text(
                  rule.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    decoration: rule.isEnabled ? null : TextDecoration.lineThrough,
                    color: rule.isEnabled
                        ? (isDark ? AppColors.darkTextPrimary : AppColors.deepCaramel)
                        : (isDark ? AppColors.darkTextMuted : AppColors.deepCaramelMuted),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Enable / Disable Switch
              Switch(
                value: rule.isEnabled,
                activeThumbColor: AppColors.caramelizedAmber,
                onChanged: onToggleEnabled,
              ),

              // Drag Handle
              const SizedBox(width: 4),
              const Icon(
                Icons.drag_indicator_rounded,
                color: AppColors.caramelizedAmber,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Parameter Summary Chips
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _buildSummaryChips(context, isDark),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSummaryChips(BuildContext context, bool isDark) {
    final chips = <Widget>[];

    // 1. Scope Chip
    String scopeLabel = 'All Series';
    switch (rule.scopeType) {
      case RuleScopeType.allSeries:
        scopeLabel = 'All Series';
        break;
      case RuleScopeType.specificSeries:
        scopeLabel = 'Specific (${rule.targetSeriesIds.length})';
        break;
      case RuleScopeType.tagBased:
        scopeLabel = 'Tags: ${rule.targetTags.join(', ')}';
        break;
      case RuleScopeType.formatType:
        scopeLabel = 'Format: ${rule.targetFormat ?? 'Any'}';
        break;
    }
    chips.add(_buildChip(scopeLabel, AppColors.caramelizedAmber, isDark));

    // 2. Restock Priority Chip
    if (rule.restockPriorityEnabled) {
      chips.add(_buildChip('Restock Priority', AppColors.statusSuccess, isDark));
    }

    // 3. Progress Trigger Chip
    if (rule.progressTrigger != ProgressTriggerType.none) {
      String triggerLabel = '';
      switch (rule.progressTrigger) {
        case ProgressTriggerType.exactVolumesLeft:
          triggerLabel = '${rule.volumeThresholdValue ?? 1} Vol Left';
          break;
        case ProgressTriggerType.leastRemainingVolumes:
          triggerLabel = '<= ${rule.volumeThresholdValue ?? 3} Vols Left';
          break;
        case ProgressTriggerType.completionPercentage:
          triggerLabel = '>= ${rule.percentageThreshold?.toStringAsFixed(0) ?? 80}% Complete';
          break;
        case ProgressTriggerType.gapFilling:
          triggerLabel = 'Gap Filling';
          break;
        case ProgressTriggerType.none:
          break;
      }
      if (triggerLabel.isNotEmpty) {
        chips.add(_buildChip(triggerLabel, AppColors.statusInfo, isDark));
      }
    }

    // 4. Sort Chip
    String sortLabel = '';
    switch (rule.sortBy) {
      case SortCriteria.earliestReleaseDate:
        sortLabel = 'Earliest Release';
        break;
      case SortCriteria.lowestVolumeNumber:
        sortLabel = 'Lowest Vol #';
        break;
      case SortCriteria.closestToCompletion:
        sortLabel = 'Closest to Complete';
        break;
      case SortCriteria.alphabetical:
        sortLabel = 'A - Z';
        break;
    }
    chips.add(_buildChip(sortLabel, isDark ? AppColors.darkTextMuted : AppColors.deepCaramelMuted, isDark));

    return chips;
  }

  Widget _buildChip(String label, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isDark && color == AppColors.caramelizedAmber ? AppColors.caramelizedAmberLight : color,
        ),
      ),
    );
  }
}
