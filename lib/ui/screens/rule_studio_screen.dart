import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/rule_model.dart';
import '../../providers/rule_provider.dart';
import '../../providers/quota_provider.dart';
import '../widgets/canele_card.dart';
import '../widgets/canele_month_year_picker.dart';
import '../widgets/rule_card.dart';
import '../widgets/edit_rule_sheet.dart';

class RuleStudioScreen extends ConsumerStatefulWidget {
  const RuleStudioScreen({super.key});

  @override
  ConsumerState<RuleStudioScreen> createState() => _RuleStudioScreenState();
}

class _RuleStudioScreenState extends ConsumerState<RuleStudioScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _monthNames = const [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  bool _isManualBonusExpanded = false;
  bool _isNoBookMonthsExpanded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _showEditRuleSheet(BuildContext context, {RuleModel? rule}) {
    EditRuleSheet.show(context, rule: rule);
  }

  void _showAddManualBonusDialog(BuildContext context, String currentMonthKey) {
    DateTime selectedMonth = DateFormatter.fromMonthKey(currentMonthKey);
    final noteController = TextEditingController();
    int bonusCount = 1;

    showDialog(
      context: context,
      builder: (ctx) {
        final config = ref.read(ruleConfigNotifierProvider);

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Manual Bonus Credit'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Month:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  CaneleMonthYearSelector(
                    selectedDate: selectedMonth,
                    onChanged: (d) => setDialogState(() => selectedMonth = d),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Bonus Books Count:', style: TextStyle(fontWeight: FontWeight.w600)),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: bonusCount > 1 ? () => setDialogState(() => bonusCount--) : null,
                          ),
                          Text('+$bonusCount', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () => setDialogState(() => bonusCount++),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text('Reason / Note:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(
                      hintText: 'e.g., Birthday Gift, Summer Sale, Special Event',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    final monthKey = DateFormatter.toMonthKey(selectedMonth);
                    final updatedLedger = Map<String, int>.from(config.customBonusLedger);
                    final existing = updatedLedger[monthKey] ?? 0;
                    updatedLedger[monthKey] = existing + bonusCount;

                    final updated = config.copyWith(customBonusLedger: updatedLedger);
                    await ref.read(ruleConfigNotifierProvider.notifier).updateConfig(updated);

                    if (ctx.mounted) Navigator.pop(ctx);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Added +$bonusCount bonus credit for ${DateFormatter.formatMonthYear(selectedMonth)}!'),
                          backgroundColor: AppColors.statusSuccess,
                        ),
                      );
                    }
                  },
                  child: const Text('Add Bonus'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddNoBookMonthDialog(BuildContext context, String currentMonthKey) {
    DateTime selectedMonth = DateFormatter.fromMonthKey(currentMonthKey);

    showDialog(
      context: context,
      builder: (ctx) {
        final config = ref.read(ruleConfigNotifierProvider);

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add No-Book Month'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Month:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  CaneleMonthYearSelector(
                    selectedDate: selectedMonth,
                    onChanged: (d) => setDialogState(() => selectedMonth = d),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'In a No-Book Month, your regular monthly acquisition target is set to 0. Use this for budget pauses, vacations, or catch-up reading months.',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    final monthKey = DateFormatter.toMonthKey(selectedMonth);
                    final updatedList = List<String>.from(config.noBookMonths);
                    if (!updatedList.contains(monthKey)) {
                      updatedList.add(monthKey);
                      updatedList.sort();
                    }

                    final updated = config.copyWith(noBookMonths: updatedList);
                    await ref.read(ruleConfigNotifierProvider.notifier).updateConfig(updated);

                    if (ctx.mounted) Navigator.pop(ctx);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Marked ${DateFormatter.formatMonthYear(selectedMonth)} as a No-Book Month!'),
                          backgroundColor: AppColors.caramelizedAmber,
                        ),
                      );
                    }
                  },
                  child: const Text('Add No-Book Month'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _onToggleBonusMonth(int monthNum) async {
    final config = ref.read(ruleConfigNotifierProvider);
    final isSelected = config.bonusMonths.contains(monthNum);

    // Prompt user for scope (User Requirement 5)
    final scopeChoice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isSelected ? 'Remove Bonus Month?' : 'Add Bonus Month?'),
        content: Text(
          'How would you like to apply this recurring bonus change for ${_monthNames[monthNum - 1]}?\n\n'
          '• Apply from start date: Recalculates full historical quota timeline from start.\n'
          '• Apply from current month forward: Keeps past quota calculations intact.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'from_now'),
            child: const Text('From Now Forward'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, 'all_time'),
            child: const Text('From Start Date'),
          ),
        ],
      ),
    );

    if (scopeChoice == null) return;

    final updatedBonusMonths = List<int>.from(config.bonusMonths);
    if (isSelected) {
      updatedBonusMonths.remove(monthNum);
    } else {
      updatedBonusMonths.add(monthNum);
    }
    updatedBonusMonths.sort();

    final updatedConfig = config.copyWith(bonusMonths: updatedBonusMonths);
    await ref.read(ruleConfigNotifierProvider.notifier).updateConfig(updatedConfig);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Updated recurring bonus schedule for ${_monthNames[monthNum - 1]}!'),
          backgroundColor: AppColors.caramelizedAmber,
        ),
      );
    }
  }

  void _onToggleRecurringNoBookMonth(int monthNum) async {
    final config = ref.read(ruleConfigNotifierProvider);
    final isSelected = config.recurringNoBookMonths.contains(monthNum);

    // Prompt user for scope
    final scopeChoice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isSelected ? 'Remove Recurring No-Book Month?' : 'Add Recurring No-Book Month?'),
        content: Text(
          'How would you like to apply this recurring paused/no-book schedule for ${_monthNames[monthNum - 1]}?\n\n'
          '• Apply from start date: Recalculates full historical quota timeline from start.\n'
          '• Apply from current month forward: Keeps past quota calculations intact.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'from_now'),
            child: const Text('From Now Forward'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, 'all_time'),
            child: const Text('From Start Date'),
          ),
        ],
      ),
    );

    if (scopeChoice == null) return;

    final updatedNoBookMonths = List<int>.from(config.recurringNoBookMonths);
    if (isSelected) {
      updatedNoBookMonths.remove(monthNum);
    } else {
      updatedNoBookMonths.add(monthNum);
    }
    updatedNoBookMonths.sort();

    final updatedConfig = config.copyWith(recurringNoBookMonths: updatedNoBookMonths);
    await ref.read(ruleConfigNotifierProvider.notifier).updateConfig(updatedConfig);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Updated recurring no-book schedule for ${_monthNames[monthNum - 1]}!'),
          backgroundColor: AppColors.caramelizedAmber,
        ),
      );
    }
  }

  Widget _buildMonthGridButton({
    required String label,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.caramelizedAmber.withValues(alpha: isDark ? 0.25 : 0.15)
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
          label,
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
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final rules = ref.watch(rulesNotifierProvider);
    final config = ref.watch(ruleConfigNotifierProvider);
    final currentMonthKey = DateFormatter.toMonthKey(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rule Studio'),
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
              onPressed: () => _showEditRuleSheet(context),
              backgroundColor: AppColors.caramelizedAmber,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Rule'),
            )
          : null,
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Dynamic Pass Pipeline Tab with ReorderableListView
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
                          'No Rules Configured',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create custom recommendation rules to prioritize restocks, specific tags, series, or completion rush.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () => _showEditRuleSheet(context),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Create First Rule'),
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Recommendation Pipeline',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            'Long-press and drag cards to set evaluation order',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Expanded(
                        child: ReorderableListView.builder(
                          itemCount: rules.length,
                          proxyDecorator: (Widget child, int index, Animation<double> animation) {
                            return AnimatedBuilder(
                              animation: animation,
                              builder: (BuildContext context, Widget? child) {
                                return Material(
                                  color: Colors.transparent,
                                  elevation: 0,
                                  child: child,
                                );
                              },
                              child: child,
                            );
                          },
                          onReorderItem: (oldIndex, newIndex) {
                            ref.read(rulesNotifierProvider.notifier).reorderRules(oldIndex, newIndex);
                          },
                          itemBuilder: (context, index) {
                            final rule = rules[index];
                            return KeyedSubtree(
                              key: ValueKey(rule.id),
                              child: RuleCard(
                                rule: rule,
                                displayIndex: index,
                                onTap: () => _showEditRuleSheet(context, rule: rule),
                                onToggleEnabled: (val) {
                                  ref.read(rulesNotifierProvider.notifier).toggleRule(rule.id, val);
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

          // 2. Quota Cadence Settings Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Deterministic Cadence Settings',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  'Configure the arithmetic baseline for your acquisition schedule',
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
                      Text('Month quota tracking began', style: theme.textTheme.bodySmall),
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
                const SizedBox(height: 12),

                // Default Regular Books per Month
                CaneleCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Regular Cadence', style: theme.textTheme.titleMedium),
                          Text('Target books per active month', style: theme.textTheme.bodySmall),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: config.defaultRegularPerMonth > 1
                                ? () async {
                                    final updated = config.copyWith(
                                      defaultRegularPerMonth: config.defaultRegularPerMonth - 1,
                                    );
                                    await ref.read(ruleConfigNotifierProvider.notifier).updateConfig(updated);
                                  }
                                : null,
                          ),
                          Text(
                            '${config.defaultRegularPerMonth} / mo',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () async {
                              final updated = config.copyWith(
                                defaultRegularPerMonth: config.defaultRegularPerMonth + 1,
                              );
                              await ref.read(ruleConfigNotifierProvider.notifier).updateConfig(updated);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Recurring Bonus Months Selection
                CaneleCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Recurring Bonus Months', style: theme.textTheme.titleMedium),
                      Text('Select months with scheduled +1 bonus budget', style: theme.textTheme.bodySmall),
                      const SizedBox(height: 12),
                      Column(
                        children: [
                          Row(
                            children: [
                              for (int i = 0; i < 6; i++) ...[
                                if (i > 0) const SizedBox(width: 6),
                                Expanded(
                                  child: _buildMonthGridButton(
                                    label: _monthNames[i],
                                    isSelected: config.bonusMonths.contains(i + 1),
                                    isDark: isDark,
                                    onTap: () => _onToggleBonusMonth(i + 1),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              for (int i = 6; i < 12; i++) ...[
                                if (i > 6) const SizedBox(width: 6),
                                Expanded(
                                  child: _buildMonthGridButton(
                                    label: _monthNames[i],
                                    isSelected: config.bonusMonths.contains(i + 1),
                                    isDark: isDark,
                                    onTap: () => _onToggleBonusMonth(i + 1),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Recurring No-Book Months Selection
                CaneleCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Recurring No-Book Months', style: theme.textTheme.titleMedium),
                      Text('Select annual months with 0 regular book budget (e.g. Budget pause, Travel)', style: theme.textTheme.bodySmall),
                      const SizedBox(height: 12),
                      Column(
                        children: [
                          Row(
                            children: [
                              for (int i = 0; i < 6; i++) ...[
                                if (i > 0) const SizedBox(width: 6),
                                Expanded(
                                  child: _buildMonthGridButton(
                                    label: _monthNames[i],
                                    isSelected: config.recurringNoBookMonths.contains(i + 1),
                                    isDark: isDark,
                                    onTap: () => _onToggleRecurringNoBookMonth(i + 1),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              for (int i = 6; i < 12; i++) ...[
                                if (i > 6) const SizedBox(width: 6),
                                Expanded(
                                  child: _buildMonthGridButton(
                                    label: _monthNames[i],
                                    isSelected: config.recurringNoBookMonths.contains(i + 1),
                                    isDark: isDark,
                                    onTap: () => _onToggleRecurringNoBookMonth(i + 1),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Manual Bonus Allowance Ledger (Collapsible)
                CaneleCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() {
                            _isManualBonusExpanded = !_isManualBonusExpanded;
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text('Manual Bonus Allowance', style: theme.textTheme.titleMedium),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isDark ? AppColors.darkPastryCardElevated : AppColors.pastryCrustLight,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: AppColors.pastryCrustBorder, width: 0.8),
                                        ),
                                        child: Text(
                                          '${config.customBonusLedger.length}',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.caramelizedAmber,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text('One-off bonus quota ledger by month', style: theme.textTheme.bodySmall),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.caramelizedAmber),
                              onPressed: () => _showAddManualBonusDialog(context, currentMonthKey),
                              tooltip: 'Add Bonus Month',
                            ),
                            Icon(
                              _isManualBonusExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                              color: isDark ? AppColors.darkTextMuted : AppColors.deepCaramelMuted,
                            ),
                          ],
                        ),
                      ),
                      if (_isManualBonusExpanded) ...[
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 8),
                        if (config.customBonusLedger.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text('No one-off bonus months added yet.', style: theme.textTheme.bodySmall),
                          )
                        else
                          Column(
                            children: (config.customBonusLedger.entries.toList()
                                  ..sort((a, b) => b.key.compareTo(a.key)))
                                .map((entry) {
                              final date = DateFormatter.fromMonthKey(entry.key);
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(DateFormatter.formatMonthYear(date)),
                                subtitle: Text('+${entry.value} Bonus book(s)'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline, color: AppColors.statusDanger, size: 18),
                                  onPressed: () async {
                                    final updatedLedger = Map<String, int>.from(config.customBonusLedger)..remove(entry.key);
                                    final updated = config.copyWith(customBonusLedger: updatedLedger);
                                    await ref.read(ruleConfigNotifierProvider.notifier).updateConfig(updated);
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // No-Book Months (0 Regular Books) Ledger (Collapsible)
                CaneleCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() {
                            _isNoBookMonthsExpanded = !_isNoBookMonthsExpanded;
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text('No-Book Months (Paused)', style: theme.textTheme.titleMedium),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isDark ? AppColors.darkPastryCardElevated : AppColors.pastryCrustLight,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: AppColors.pastryCrustBorder, width: 0.8),
                                        ),
                                        child: Text(
                                          '${config.noBookMonths.length}',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.caramelizedAmber,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text('Months with 0 regular book target', style: theme.textTheme.bodySmall),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.caramelizedAmber),
                              onPressed: () => _showAddNoBookMonthDialog(context, currentMonthKey),
                              tooltip: 'Add No-Book Month',
                            ),
                            Icon(
                              _isNoBookMonthsExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                              color: isDark ? AppColors.darkTextMuted : AppColors.deepCaramelMuted,
                            ),
                          ],
                        ),
                      ),
                      if (_isNoBookMonthsExpanded) ...[
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 8),
                        if (config.noBookMonths.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text('No paused / no-book months scheduled.', style: theme.textTheme.bodySmall),
                          )
                        else
                          Column(
                            children: (List<String>.from(config.noBookMonths)
                                  ..sort((a, b) => b.compareTo(a)))
                                .map((monthKey) {
                              final date = DateFormatter.fromMonthKey(monthKey);
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(DateFormatter.formatMonthYear(date)),
                                subtitle: const Text('Regular Target: 0 books (Paused)'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline, color: AppColors.statusDanger, size: 18),
                                  onPressed: () async {
                                    final updatedList = List<String>.from(config.noBookMonths)..remove(monthKey);
                                    final updated = config.copyWith(noBookMonths: updatedList);
                                    await ref.read(ruleConfigNotifierProvider.notifier).updateConfig(updated);
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
