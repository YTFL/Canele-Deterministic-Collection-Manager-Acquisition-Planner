import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/uuid_generator.dart';
import '../../models/game_rule.dart';
import '../../providers/game_providers.dart';

class EditGameRuleSheet extends ConsumerStatefulWidget {
  final GameRule? rule;

  const EditGameRuleSheet({super.key, this.rule});

  static Future<void> show(BuildContext context, {GameRule? rule}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => EditGameRuleSheet(rule: rule),
    );
  }

  @override
  ConsumerState<EditGameRuleSheet> createState() => _EditGameRuleSheetState();
}

class _EditGameRuleSheetState extends ConsumerState<EditGameRuleSheet> {
  late TextEditingController _nameController;
  bool _hasNameError = false;
  late GameRuleScope _scope;
  late List<String> _targetSeriesIds;
  late GameRuleTrigger _trigger;
  int _thresholdValue = 2;
  double _percentageThreshold = 80.0;
  late bool _isPriorityTargetOnly;
  late GameSortCriteria _sortBy;

  @override
  void initState() {
    super.initState();
    final r = widget.rule;
    _nameController = TextEditingController(text: r?.name ?? '');
    _scope = r?.scope ?? GameRuleScope.all;
    _targetSeriesIds = List.from(r?.targetSeriesIds ?? []);
    _trigger = r?.trigger ?? GameRuleTrigger.none;
    _thresholdValue = r?.thresholdValue ?? 2;
    _percentageThreshold = r?.percentageThreshold ?? 80.0;
    _isPriorityTargetOnly = r?.isPriorityTargetOnly ?? false;
    _sortBy = r?.sortBy ?? GameSortCriteria.earliestReleaseDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _hasNameError = true);
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text('Rule name is mandatory'),
            backgroundColor: AppColors.statusDanger,
          ),
        );
      return;
    }

    final rule = GameRule(
      id: widget.rule?.id ?? UuidGenerator.generate(),
      name: name,
      isEnabled: widget.rule?.isEnabled ?? true,
      priorityOrder: widget.rule?.priorityOrder ?? 0,
      scope: _scope,
      targetSeriesIds: _targetSeriesIds,
      trigger: _trigger,
      thresholdValue: _thresholdValue,
      percentageThreshold: _percentageThreshold,
      isPriorityTargetOnly: _isPriorityTargetOnly,
      sortBy: _sortBy,
    );

    await ref.read(gameRulesNotifierProvider.notifier).saveRule(rule);

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text('Saved rule "$name"'),
            backgroundColor: AppColors.caramelizedAmber,
          ),
        );
    }
  }

  Future<void> _delete() async {
    if (widget.rule == null) return;
    await ref.read(gameRulesNotifierProvider.notifier).deleteRule(widget.rule!.id);
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text('Rule deleted')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final allSeries = ref.watch(gameSeriesNotifierProvider);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkPastryCard : AppColors.custardCream,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: isDark ? AppColors.darkPastryBorder : AppColors.pastryCrustBorder,
        ),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkPastryBorder : AppColors.pastryCrustBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.rule == null ? 'Create Game Rule' : 'Edit Game Rule',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const Divider(height: 20),

            // Rule Name
            Row(
              children: [
                Text('Rule Name', style: theme.textTheme.titleMedium),
                const SizedBox(width: 4),
                const Text('*', style: TextStyle(color: AppColors.statusDanger, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _nameController,
              onChanged: (val) {
                if (_hasNameError && val.trim().isNotEmpty) {
                  setState(() => _hasNameError = false);
                }
              },
              decoration: InputDecoration(
                hintText: 'e.g., Rush to Complete Franchise, DLC Priority, Sale Watchlist',
                errorText: _hasNameError ? 'Rule name is mandatory' : null,
              ),
            ),
            const SizedBox(height: 16),

            // Scope Selector
            Text('Game Scope', style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            SegmentedButton<GameRuleScope>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: GameRuleScope.all, label: Text('All')),
                ButtonSegment(value: GameRuleScope.franchisesOnly, label: Text('Franchises')),
                ButtonSegment(value: GameRuleScope.standaloneOnly, label: Text('Standalone')),
                ButtonSegment(value: GameRuleScope.specific, label: Text('Specific')),
              ],
              selected: {_scope},
              onSelectionChanged: (set) => setState(() => _scope = set.first),
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(height: 12),

            // Specific Franchises Checklist
            if (_scope == GameRuleScope.specific) ...[
              Text('Target Franchises / Games (${_targetSeriesIds.length} selected)', style: theme.textTheme.bodyMedium),
              const SizedBox(height: 8),
              if (allSeries.isEmpty)
                Text('No game series found in collection.', style: theme.textTheme.bodySmall)
              else
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: allSeries.map((s) {
                    final isSelected = _targetSeriesIds.contains(s.id);
                    return FilterChip(
                      label: Text(s.title),
                      selected: isSelected,
                      showCheckmark: false,
                      selectedColor: AppColors.caramelizedAmber.withValues(alpha: 0.2),
                      onSelected: (val) {
                        setState(() {
                          if (val) {
                            _targetSeriesIds.add(s.id);
                          } else {
                            _targetSeriesIds.remove(s.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              const SizedBox(height: 16),
            ],

            // Watchlist Priority Target Toggle (NO RESTOCK)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Watchlist Priority Target'),
              subtitle: const Text('Only recommend games & DLCs flagged as high-priority purchase targets'),
              activeThumbColor: AppColors.caramelizedAmber,
              value: _isPriorityTargetOnly,
              onChanged: (val) => setState(() => _isPriorityTargetOnly = val),
            ),
            const SizedBox(height: 10),

            // Progress Trigger Selector
            Text('Acquisition Trigger', style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            DropdownButtonFormField<GameRuleTrigger>(
              initialValue: _trigger,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: GameRuleTrigger.none, child: Text('None (Evaluate all unowned games)')),
                DropdownMenuItem(value: GameRuleTrigger.fewestRemaining, child: Text('Fewest Remaining Games in Franchise')),
                DropdownMenuItem(value: GameRuleTrigger.exactRemaining, child: Text('Exact Games Left to Complete Franchise')),
                DropdownMenuItem(value: GameRuleTrigger.completionPercentage, child: Text('Franchise Completion % Threshold')),
                DropdownMenuItem(value: GameRuleTrigger.sequentialNext, child: Text('Next Sequential Installment')),
                DropdownMenuItem(value: GameRuleTrigger.dlcOnly, child: Text('DLC Expansions for Owned Games')),
              ],
              onChanged: (val) => setState(() => _trigger = val!),
            ),
            const SizedBox(height: 10),

            // Trigger Values
            if (_trigger == GameRuleTrigger.fewestRemaining ||
                _trigger == GameRuleTrigger.exactRemaining) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Games Remaining Threshold ($_thresholdValue)', style: theme.textTheme.bodyMedium),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: _thresholdValue > 1 ? () => setState(() => _thresholdValue--) : null,
                      ),
                      Text('$_thresholdValue', style: const TextStyle(fontWeight: FontWeight.w700)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => setState(() => _thresholdValue++),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],

            if (_trigger == GameRuleTrigger.completionPercentage) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Minimum Franchise Completion', style: TextStyle(fontSize: 14)),
                  Text('${_percentageThreshold.toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
              Slider(
                value: _percentageThreshold,
                min: 10,
                max: 95,
                divisions: 17,
                activeColor: AppColors.caramelizedAmber,
                label: '${_percentageThreshold.toStringAsFixed(0)}%',
                onChanged: (val) => setState(() => _percentageThreshold = val),
              ),
              const SizedBox(height: 10),
            ],

            // Sort Criteria Selector
            Text('Sort Candidates By', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Earliest Release'),
                  selected: _sortBy == GameSortCriteria.earliestReleaseDate,
                  showCheckmark: false,
                  onSelected: (val) => setState(() => _sortBy = GameSortCriteria.earliestReleaseDate),
                ),
                ChoiceChip(
                  label: const Text('Chronological Order'),
                  selected: _sortBy == GameSortCriteria.chronologicalOrder,
                  showCheckmark: false,
                  onSelected: (val) => setState(() => _sortBy = GameSortCriteria.chronologicalOrder),
                ),
                ChoiceChip(
                  label: const Text('Closest to Completion'),
                  selected: _sortBy == GameSortCriteria.closestToFranchiseCompletion,
                  showCheckmark: false,
                  onSelected: (val) => setState(() => _sortBy = GameSortCriteria.closestToFranchiseCompletion),
                ),
                ChoiceChip(
                  label: const Text('Alphabetical (A-Z)'),
                  selected: _sortBy == GameSortCriteria.alphabetical,
                  showCheckmark: false,
                  onSelected: (val) => setState(() => _sortBy = GameSortCriteria.alphabetical),
                ),
                ChoiceChip(
                  label: const Text('Lowest Price'),
                  selected: _sortBy == GameSortCriteria.lowestPrice,
                  showCheckmark: false,
                  onSelected: (val) => setState(() => _sortBy = GameSortCriteria.lowestPrice),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                if (widget.rule != null) ...[
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.statusDanger),
                    onPressed: _delete,
                    tooltip: 'Delete Rule',
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: ElevatedButton(
                    onPressed: _save,
                    child: Text(widget.rule == null ? 'Create Game Rule' : 'Save Changes'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
