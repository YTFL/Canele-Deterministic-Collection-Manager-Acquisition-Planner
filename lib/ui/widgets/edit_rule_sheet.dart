import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/type_helper.dart';
import '../../core/utils/uuid_generator.dart';
import '../../models/rule_model.dart';
import '../../providers/rule_provider.dart';
import '../../providers/series_provider.dart';

class EditRuleSheet extends ConsumerStatefulWidget {
  final RuleModel? rule;

  const EditRuleSheet({super.key, this.rule});

  static Future<void> show(BuildContext context, {RuleModel? rule}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => EditRuleSheet(rule: rule),
    );
  }

  @override
  ConsumerState<EditRuleSheet> createState() => _EditRuleSheetState();
}

class _EditRuleSheetState extends ConsumerState<EditRuleSheet> {
  late TextEditingController _nameController;
  bool _hasNameError = false;
  late RuleScopeType _scopeType;
  late List<String> _targetSeriesIds;
  late List<String> _targetTags;
  String? _targetFormat;
  late ProgressTriggerType _progressTrigger;
  int _volumeThresholdValue = 1;
  double _percentageThreshold = 80.0;
  late bool _restockPriority;
  late SortCriteria _sortBy;

  @override
  void initState() {
    super.initState();
    final r = widget.rule;
    _nameController = TextEditingController(text: r?.name ?? '');
    _scopeType = r?.scopeType ?? RuleScopeType.allSeries;
    _targetSeriesIds = List.from(r?.targetSeriesIds ?? []);
    _targetTags = List.from(r?.targetTags ?? []);
    _targetFormat = r?.targetFormat;
    _progressTrigger = r?.progressTrigger ?? ProgressTriggerType.none;
    _volumeThresholdValue = r?.volumeThresholdValue ?? 1;
    _percentageThreshold = r?.percentageThreshold ?? 80.0;
    _restockPriority = r?.restockPriorityEnabled ?? false;
    _sortBy = r?.sortBy ?? SortCriteria.earliestReleaseDate;
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
          content: Text('Rule name is mandatory for rule creation'),
          backgroundColor: AppColors.statusDanger,
        ),
      );
      return;
    }

    final rule = RuleModel(
      id: widget.rule?.id ?? UuidGenerator.generate(),
      name: name,
      isEnabled: widget.rule?.isEnabled ?? true,
      priorityOrder: widget.rule?.priorityOrder ?? 0,
      scopeType: _scopeType,
      targetSeriesIds: _targetSeriesIds,
      targetTags: _targetTags,
      targetFormat: _targetFormat,
      progressTrigger: _progressTrigger,
      volumeThresholdValue: _volumeThresholdValue,
      percentageThreshold: _percentageThreshold,
      restockPriorityEnabled: _restockPriority,
      sortBy: _sortBy,
    );

    await ref.read(rulesNotifierProvider.notifier).saveRule(rule);

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
    await ref.read(rulesNotifierProvider.notifier).deleteRule(widget.rule!.id);
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
    final allSeries = ref.watch(seriesNotifierProvider);

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
            // Handle
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

            // Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.rule == null ? 'Create Rule' : 'Edit Rule',
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
                hintText: 'e.g., Rush to Complete, Restock Priority',
                helperText: 'Rule name is mandatory for rule creation',
                errorText: _hasNameError ? 'Rule name is mandatory for rule creation' : null,
              ),
            ),
            const SizedBox(height: 16),

            // Scope Selector
            Text('Series Scope', style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            SegmentedButton<RuleScopeType>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: RuleScopeType.allSeries, label: Text('All')),
                ButtonSegment(value: RuleScopeType.specificSeries, label: Text('Specific')),
                ButtonSegment(value: RuleScopeType.formatType, label: Text('Format')),
              ],
              selected: {_scopeType == RuleScopeType.tagBased ? RuleScopeType.allSeries : _scopeType},
              onSelectionChanged: (set) => setState(() => _scopeType = set.first),
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(height: 12),

            // Specific Series Checklist Selector
            if (_scopeType == RuleScopeType.specificSeries) ...[
              Text('Select Target Series (${_targetSeriesIds.length} selected)', style: theme.textTheme.bodyMedium),
              const SizedBox(height: 8),
              if (allSeries.isEmpty)
                Text('No series found in collection.', style: theme.textTheme.bodySmall)
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

            // Format Type Dropdown
            if (_scopeType == RuleScopeType.formatType) ...[
              Text('Target Book Format', style: theme.textTheme.bodyMedium),
              const SizedBox(height: 6),
              () {
                final availableTypes = TypeHelper.getAllAvailableTypes(allSeries.map((s) => s.type));
                final currentVal = _targetFormat != null
                    ? TypeHelper.formatTypeLabel(_targetFormat!)
                    : (availableTypes.isNotEmpty ? availableTypes.first : null);
                if (currentVal != null && !availableTypes.contains(currentVal)) {
                  availableTypes.add(currentVal);
                }

                return DropdownButtonFormField<String>(
                  initialValue: currentVal,
                  hint: const Text('Select or Add Format'),
                  items: [
                    ...availableTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))),
                    const DropdownMenuItem(
                      value: '__ADD_NEW__',
                      child: Row(
                        children: [
                          Icon(Icons.add_rounded, size: 16, color: AppColors.caramelizedAmber),
                          SizedBox(width: 4),
                          Text('+ Add New Type...', style: TextStyle(color: AppColors.caramelizedAmber, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (val) async {
                    if (val == '__ADD_NEW__') {
                      final custom = await showDialog<String>(
                        context: context,
                        builder: (ctx) {
                          final controller = TextEditingController();
                          return AlertDialog(
                            title: const Text('Add Custom Book Type'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Enter custom book format / type name:'),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: controller,
                                  autofocus: true,
                                  decoration: const InputDecoration(hintText: 'e.g. Manhwa, Webtoon, Artbook'),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('Cancel')),
                              ElevatedButton(
                                onPressed: () {
                                  final text = controller.text.trim();
                                  if (text.isNotEmpty) {
                                    Navigator.pop(ctx, TypeHelper.formatTypeLabel(text));
                                  }
                                },
                                child: const Text('Add Type'),
                              ),
                            ],
                          );
                        },
                      );
                      if (custom != null && custom.isNotEmpty) {
                        setState(() => _targetFormat = TypeHelper.normalizeKey(custom));
                      }
                    } else if (val != null) {
                      setState(() => _targetFormat = TypeHelper.normalizeKey(val));
                    }
                  },
                );
              }(),
              const SizedBox(height: 16),
            ],

            // Progress Trigger Selector
            Text('Progress Trigger', style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            DropdownButtonFormField<ProgressTriggerType>(
              initialValue: _progressTrigger,
              items: const [
                DropdownMenuItem(value: ProgressTriggerType.none, child: Text('None (Evaluate all unowned)')),
                DropdownMenuItem(value: ProgressTriggerType.exactVolumesLeft, child: Text('Exact Volumes Left to Complete')),
                DropdownMenuItem(value: ProgressTriggerType.leastRemainingVolumes, child: Text('Fewest Remaining Volumes')),
                DropdownMenuItem(value: ProgressTriggerType.completionPercentage, child: Text('Completion % Threshold')),
                DropdownMenuItem(value: ProgressTriggerType.gapFilling, child: Text('Sequential Gap Filling')),
              ],
              onChanged: (val) => setState(() => _progressTrigger = val!),
            ),
            const SizedBox(height: 10),

            // Progress Trigger Values
            if (_progressTrigger == ProgressTriggerType.exactVolumesLeft ||
                _progressTrigger == ProgressTriggerType.leastRemainingVolumes) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Volume Threshold ($_volumeThresholdValue vol)', style: theme.textTheme.bodyMedium),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: _volumeThresholdValue > 1 ? () => setState(() => _volumeThresholdValue--) : null,
                      ),
                      Text('$_volumeThresholdValue', style: const TextStyle(fontWeight: FontWeight.w700)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => setState(() => _volumeThresholdValue++),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],

            if (_progressTrigger == ProgressTriggerType.completionPercentage) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Minimum Completion', style: theme.textTheme.bodyMedium),
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

            // Special Triggers (Restock Priority)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Restock Priority'),
              subtitle: const Text('Bump volumes marked as recently restocked or available on watchlist'),
              activeThumbColor: AppColors.caramelizedAmber,
              value: _restockPriority,
              onChanged: (val) => setState(() => _restockPriority = val),
            ),
            const SizedBox(height: 10),

            // Sort Criteria Selector
            Text('Sort Candidates By', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Earliest Release'),
                  selected: _sortBy == SortCriteria.earliestReleaseDate,
                  showCheckmark: false,
                  onSelected: (val) => setState(() => _sortBy = SortCriteria.earliestReleaseDate),
                ),
                ChoiceChip(
                  label: const Text('Lowest Volume #'),
                  selected: _sortBy == SortCriteria.lowestVolumeNumber,
                  showCheckmark: false,
                  onSelected: (val) => setState(() => _sortBy = SortCriteria.lowestVolumeNumber),
                ),
                ChoiceChip(
                  label: const Text('Closest to Complete'),
                  selected: _sortBy == SortCriteria.closestToCompletion,
                  showCheckmark: false,
                  onSelected: (val) => setState(() => _sortBy = SortCriteria.closestToCompletion),
                ),
                ChoiceChip(
                  label: const Text('Alphabetical (A-Z)'),
                  selected: _sortBy == SortCriteria.alphabetical,
                  showCheckmark: false,
                  onSelected: (val) => setState(() => _sortBy = SortCriteria.alphabetical),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Action Buttons (Save / Delete)
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
                    child: Text(widget.rule == null ? 'Create Rule' : 'Save Changes'),
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
