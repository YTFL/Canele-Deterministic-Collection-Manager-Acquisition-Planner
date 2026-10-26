import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../providers/quota_provider.dart';
import '../../../../ui/widgets/quota_status_card.dart';
import '../../../../ui/widgets/workspace_switcher_app_bar_title.dart';
import '../../providers/game_providers.dart';
import '../sheets/add_game_sheet.dart';
import '../sheets/log_game_acquisition_sheet.dart';
import '../widgets/game_slot_card.dart';

class GameDashboardView extends ConsumerWidget {
  const GameDashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final quotaSummary = ref.watch(quotaProvider);
    final slots = ref.watch(gameRecommendationSlotsProvider);
    final allSeries = ref.watch(gameSeriesNotifierProvider);
    final rules = ref.watch(gameRulesNotifierProvider);
    final hasActiveRules = rules.any((r) => r.isEnabled);

    return Scaffold(
      appBar: AppBar(
        title: const WorkspaceSwitcherAppBarTitle(fallbackTitle: 'Game Dashboard'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quota Status Card
            QuotaStatusCard(
              summary: quotaSummary,
            ),
            const SizedBox(height: 20),

            // Recommendation Targets Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monthly Game Targets',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                    Text(
                      'Deterministic recommendations based on your game rules',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Recommendation Slots List
            if (slots.isEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.pastryCrustBorder,
                    width: 0.8,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      !hasActiveRules
                          ? Icons.tune_rounded
                          : Icons.sports_esports_outlined,
                      size: 40,
                      color: AppColors.caramelizedAmber,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      allSeries.isEmpty
                          ? 'No games in your collection yet'
                          : (!hasActiveRules
                              ? 'No Active Game Rules'
                              : 'No pending acquisition targets for this month'),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      allSeries.isEmpty
                          ? 'Add game franchises or standalone titles to begin tracking monthly purchases.'
                          : (!hasActiveRules
                              ? 'Configure recommendation rules in Rule Studio to generate target recommendations.'
                              : 'All active game installments are currently acquired, or no rules match unowned items.'),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => AddGameSheet.show(context),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add Game'),
                    ),
                  ],
                ),
              ),
            ] else ...[
              for (final slot in slots)
                GameSlotCard(
                  slot: slot,
                  onLogAcquisition: () => LogGameAcquisitionSheet.show(
                    context,
                    series: slot.series,
                    item: slot.item,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
