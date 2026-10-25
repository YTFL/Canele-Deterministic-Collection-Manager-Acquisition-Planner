import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../ui/widgets/canele_card.dart';
import '../../models/game_rule.dart';

class GameRuleCard extends StatelessWidget {
  final GameRule rule;
  final int displayIndex;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggleEnabled;

  const GameRuleCard({
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

              Switch(
                value: rule.isEnabled,
                activeThumbColor: AppColors.caramelizedAmber,
                onChanged: onToggleEnabled,
              ),

              const SizedBox(width: 4),
              const Icon(
                Icons.drag_indicator_rounded,
                color: AppColors.caramelizedAmber,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Summary Parameter Chips (Game-Specific, NO RESTOCK, NO VOLUMES)
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
    String scopeLabel = 'All Games & Franchises';
    switch (rule.scope) {
      case GameRuleScope.all:
        scopeLabel = 'All Games';
        break;
      case GameRuleScope.franchisesOnly:
        scopeLabel = 'Franchises Only';
        break;
      case GameRuleScope.standaloneOnly:
        scopeLabel = 'Standalone Only';
        break;
      case GameRuleScope.specific:
        scopeLabel = 'Specific (${rule.targetSeriesIds.length})';
        break;
    }
    chips.add(_buildChip(scopeLabel, AppColors.caramelizedAmber, isDark));

    // 2. Watchlist Priority Target Chip (Replaces Restock Priority)
    if (rule.isPriorityTargetOnly) {
      chips.add(_buildChip('Watchlist Priority Target', AppColors.statusSuccess, isDark));
    }

    // 3. Trigger Chip (Games Terminology)
    String triggerLabel = '';
    switch (rule.trigger) {
      case GameRuleTrigger.none:
        break;
      case GameRuleTrigger.fewestRemaining:
        triggerLabel = '<= ${rule.thresholdValue ?? 2} Games Left';
        break;
      case GameRuleTrigger.exactRemaining:
        triggerLabel = '${rule.thresholdValue ?? 1} Game Left';
        break;
      case GameRuleTrigger.completionPercentage:
        triggerLabel = '>= ${rule.percentageThreshold?.toStringAsFixed(0) ?? 80}% Complete';
        break;
      case GameRuleTrigger.sequentialNext:
        triggerLabel = 'Next Sequential Installment';
        break;
      case GameRuleTrigger.dlcOnly:
        triggerLabel = 'DLCs for Owned Games';
        break;
    }
    if (triggerLabel.isNotEmpty) {
      chips.add(_buildChip(triggerLabel, AppColors.statusInfo, isDark));
    }

    // 4. Sort Chip
    String sortLabel = '';
    switch (rule.sortBy) {
      case GameSortCriteria.earliestReleaseDate:
        sortLabel = 'Earliest Release';
        break;
      case GameSortCriteria.chronologicalOrder:
        sortLabel = 'Chronological Order';
        break;
      case GameSortCriteria.closestToFranchiseCompletion:
        sortLabel = 'Closest to Complete';
        break;
      case GameSortCriteria.alphabetical:
        sortLabel = 'A-Z';
        break;
      case GameSortCriteria.lowestPrice:
        sortLabel = 'Lowest Price';
        break;
    }
    chips.add(_buildChip(sortLabel, isDark ? AppColors.darkTextMuted : AppColors.deepCaramelMuted, isDark));

    return chips;
  }

  Widget _buildChip(String text, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.5 : 0.35),
          width: 0.8,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.darkTextPrimary : AppColors.deepCaramel,
        ),
      ),
    );
  }
}
