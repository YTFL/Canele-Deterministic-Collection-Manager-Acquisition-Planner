import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../providers/quota_provider.dart';
import '../../../../ui/widgets/canele_card.dart';
import '../../../../ui/widgets/canele_month_year_picker.dart';
import '../../../../ui/widgets/workspace_switcher_app_bar_title.dart';
import '../../providers/game_providers.dart';
import '../sheets/edit_game_rule_sheet.dart';
import '../widgets/game_rule_card.dart';

class GameRuleStudioView extends ConsumerStatefulWidget {
  const GameRuleStudioView({super.key});

  @override
  ConsumerState<GameRuleStudioView> createState() => _GameRuleStudioViewState();
}

class _GameRuleStudioViewState extends ConsumerState<GameRuleStudioView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _monthNames = const [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onToggleRecurringNoGameMonth(int monthNum) async {
    final config = ref.read(ruleConfigNotifierProvider);
    final isSelected = config.recurringNoBookMonths.contains(monthNum);

    final updated = List<int>.from(config.recurringNoBookMonths);
    if (isSelected) {
      updated.remove(monthNum);
    } else {
      updated.add(monthNum);
    }
    updated.sort();

    await ref.read(ruleConfigNotifierProvider.notifier).updateConfig(
          config.copyWith(recurringNoBookMonths: updated),
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final rules = ref.watch(gameRulesNotifierProvider);
    final config = ref.watch(ruleConfigNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const WorkspaceSwitcherAppBarTitle(fallbackTitle: 'Game Rule Studio'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.caramelizedAmber,
          labelColor: isDark ? AppColors.caramelizedAmberLight : AppColors.caramelizedAmber,
          unselectedLabelColor: isDark ? AppColors.darkTextMuted : AppColors.deepCaramelMuted,
          tabs: const [
            Tab(text: 'Pass Pipeline'),
            Tab(text: 'Quota Cadence'),
          ],
        ),
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: () => EditGameRuleSheet.show(context),
              backgroundColor: AppColors.caramelizedAmber,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Game Rule'),
            )
          : null,
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Pass Pipeline Tab
          rules.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.tune_rounded,
                          size: 54,
                          color: AppColors.caramelizedAmber,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Game Rules Configured',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Configure recommendation rules to prioritize watchlist targets, franchise completion, sequential installments, or DLC expansions.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () => EditGameRuleSheet.show(context),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Create Game Rule'),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: () async {
                            await ref.read(gameRulesNotifierProvider.notifier).loadDefaultRules();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Loaded default game acquisition rules!'),
                                  backgroundColor: AppColors.statusSuccess,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.auto_fix_high_rounded, size: 18),
                          label: const Text('Load Default Game Rules'),
                        ),
                      ],
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Game Recommendation Pipeline',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'Long-press and drag cards to set rule evaluation order',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ReorderableListView.builder(
                          itemCount: rules.length,
                          onReorderItem: (oldIndex, newIndex) {
                            ref.read(gameRulesNotifierProvider.notifier).reorderRules(oldIndex, newIndex);
                          },
                          itemBuilder: (context, index) {
                            final rule = rules[index];
                            return KeyedSubtree(
                              key: ValueKey(rule.id),
                              child: GameRuleCard(
                                rule: rule,
                                displayIndex: index,
                                onTap: () => EditGameRuleSheet.show(context, rule: rule),
                                onToggleEnabled: (val) {
                                  ref.read(gameRulesNotifierProvider.notifier).toggleRule(rule.id, val);
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

          // 2. Quota Cadence Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Game Quota Cadence Settings',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  'Configure the deterministic monthly purchase schedule for video games',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 16),

                // Timeline Start Date Card
                CaneleCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Timeline Start Month', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 2),
                      const Text('Month game acquisition tracking began', style: TextStyle(fontSize: 12)),
                      const SizedBox(height: 10),
                      CaneleMonthYearSelector(
                        selectedDate: config.timelineStartDate,
                        onChanged: (picked) async {
                          final updated = config.copyWith(timelineStartDate: picked);
                          await ref.read(ruleConfigNotifierProvider.notifier).updateConfig(updated);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Default Games per Month
                CaneleCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Default Games per Month', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 2),
                      const Text('Base monthly acquisition quota for games', style: TextStyle(fontSize: 12)),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: config.defaultRegularPerMonth > 0
                                ? () async {
                                    final updated = config.copyWith(
                                        defaultRegularPerMonth: config.defaultRegularPerMonth - 1);
                                    await ref.read(ruleConfigNotifierProvider.notifier).updateConfig(updated);
                                  }
                                : null,
                          ),
                          Text(
                            '${config.defaultRegularPerMonth} games / month',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () async {
                              final updated = config.copyWith(
                                  defaultRegularPerMonth: config.defaultRegularPerMonth + 1);
                              await ref.read(ruleConfigNotifierProvider.notifier).updateConfig(updated);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Recurring No-Game Months
                CaneleCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Recurring No-Game Months', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 2),
                      const Text('Months where game budget is paused (0 quota target)', style: TextStyle(fontSize: 12)),
                      const SizedBox(height: 12),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 2.2,
                        ),
                        itemCount: 12,
                        itemBuilder: (context, i) {
                          final monthNum = i + 1;
                          final isSelected = config.recurringNoBookMonths.contains(monthNum);
                          return InkWell(
                            onTap: () => _onToggleRecurringNoGameMonth(monthNum),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.caramelizedAmber.withValues(alpha: 0.2)
                                    : (isDark ? AppColors.darkPastryCardElevated : AppColors.pastryCrustLight),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.caramelizedAmber
                                      : (isDark ? AppColors.darkPastryBorder : AppColors.pastryCrustBorder),
                                  width: isSelected ? 1.5 : 1.0,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                _monthNames[i],
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                  color: isSelected
                                      ? (isDark ? AppColors.caramelizedAmberLight : AppColors.caramelizedAmber)
                                      : (isDark ? AppColors.darkTextMuted : AppColors.deepCaramelMuted),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
