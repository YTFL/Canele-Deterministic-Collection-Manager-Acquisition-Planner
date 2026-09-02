import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_helper.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/uuid_generator.dart';
import '../../models/rule_config.dart';
import '../../models/rule_model.dart';
import '../../providers/quota_provider.dart';
import '../../providers/rule_provider.dart';
import '../widgets/canele_card.dart';
import '../widgets/canele_month_year_picker.dart';
import '../widgets/rule_card.dart';
import '../widgets/edit_rule_sheet.dart';
import 'main_shell_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _currentStep = 0;

  // Step 1 State: Timeline Start & Cadence
  late DateTime _startDate;
  int _regularPerMonth = 1;
  String _currency = 'USD';

  // Step 2 State: Recurring Bonus Months & Recurring No-Book Months (Optional)
  final Set<int> _selectedBonusMonths = {};
  final Set<int> _selectedRecurringNoBookMonths = {};

  // Step 3 State: Historical Catch-Up
  final Set<String> _selectedNoBookMonths = {};
  final Map<String, int> _customBonusLedger = {};

  bool _isPastNoBookExpanded = false;
  bool _isPastBonusesExpanded = false;

  late DateTime _noBookPickerDate;
  late DateTime _bonusPickerDate;
  int _bonusPickerCount = 1;

  final List<String> _monthNames = const [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  // Step 4 State: Rule Setup Mode ('default' vs 'custom')
  String _ruleSetupOption = 'default';

  List<RuleModel> _getDefaultRules() {
    return [
      RuleModel(
        id: UuidGenerator.generate(),
        name: 'Prioritize Restocked Volumes',
        scopeType: RuleScopeType.allSeries,
        progressTrigger: ProgressTriggerType.none,
        restockPriorityEnabled: true,
        sortBy: SortCriteria.lowestVolumeNumber,
        isEnabled: true,
        priorityOrder: 0,
      ),
      RuleModel(
        id: UuidGenerator.generate(),
        name: 'Finish Near-Complete Series',
        scopeType: RuleScopeType.allSeries,
        progressTrigger: ProgressTriggerType.leastRemainingVolumes,
        volumeThresholdValue: 3,
        restockPriorityEnabled: false,
        sortBy: SortCriteria.closestToCompletion,
        isEnabled: true,
        priorityOrder: 1,
      ),
      RuleModel(
        id: UuidGenerator.generate(),
        name: 'Sequential Next Volume',
        scopeType: RuleScopeType.allSeries,
        progressTrigger: ProgressTriggerType.none,
        restockPriorityEnabled: false,
        sortBy: SortCriteria.lowestVolumeNumber,
        isEnabled: true,
        priorityOrder: 2,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _noBookPickerDate = _startDate;
    _bonusPickerDate = _startDate;
  }

  bool get _isPastStartDate {
    final now = DateTime.now();
    return _startDate.isBefore(DateTime(now.year, now.month, 1));
  }

  Future<void> _completeOnboarding() async {
    final config = RuleConfig(
      id: 'global_config',
      timelineStartDate: _startDate,
      defaultRegularPerMonth: _regularPerMonth,
      bonusMonths: _selectedBonusMonths.toList()..sort(),
      recurringNoBookMonths: _selectedRecurringNoBookMonths.toList()..sort(),
      noBookMonths: _selectedNoBookMonths.toList()..sort(),
      customBonusLedger: _customBonusLedger,
      manualBonusCount: 0,
      isOnboardingCompleted: true,
      currency: _currency,
    );

    await ref.read(ruleConfigNotifierProvider.notifier).updateConfig(config);

    if (_ruleSetupOption == 'default') {
      final currentRules = ref.read(rulesNotifierProvider);
      if (currentRules.isEmpty) {
        final defaults = _getDefaultRules();
        for (final r in defaults) {
          await ref.read(rulesNotifierProvider.notifier).saveRule(r);
        }
      }
    }

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainShellScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Your Quota Rules'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Indicator (4 Steps)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  _StepIndicator(
                    step: 1,
                    title: 'Cadence',
                    isActive: _currentStep == 0,
                    isDone: _currentStep > 0,
                  ),
                  Expanded(
                    child: Divider(
                      thickness: 2,
                      indent: 4,
                      endIndent: 4,
                      color: _currentStep > 0
                          ? AppColors.caramelizedAmber.withValues(alpha: 0.6)
                          : (isDark ? AppColors.darkPastryBorder : AppColors.pastryCrustBorder),
                    ),
                  ),
                  _StepIndicator(
                    step: 2,
                    title: 'Bonus',
                    isActive: _currentStep == 1,
                    isDone: _currentStep > 1,
                  ),
                  Expanded(
                    child: Divider(
                      thickness: 2,
                      indent: 4,
                      endIndent: 4,
                      color: _currentStep > 1
                          ? AppColors.caramelizedAmber.withValues(alpha: 0.6)
                          : (isDark ? AppColors.darkPastryBorder : AppColors.pastryCrustBorder),
                    ),
                  ),
                  _StepIndicator(
                    step: 3,
                    title: 'Catch-Up',
                    isActive: _currentStep == 2,
                    isDone: _currentStep > 2,
                  ),
                  Expanded(
                    child: Divider(
                      thickness: 2,
                      indent: 4,
                      endIndent: 4,
                      color: _currentStep > 2
                          ? AppColors.caramelizedAmber.withValues(alpha: 0.6)
                          : (isDark ? AppColors.darkPastryBorder : AppColors.pastryCrustBorder),
                    ),
                  ),
                  _StepIndicator(
                    step: 4,
                    title: 'Rules',
                    isActive: _currentStep == 3,
                    isDone: false,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Step Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _buildCurrentStep(theme, isDark),
              ),
            ),

            // Bottom Navigation Buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkPastryCard : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColors.darkPastryBorder : AppColors.pastryCrustBorder,
                  ),
                ),
              ),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          if (_currentStep == 3 && !_isPastStartDate) {
                            setState(() => _currentStep = 1);
                          } else {
                            setState(() => _currentStep--);
                          }
                        },
                        child: const Text('Back'),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentStep == 0) {
                          setState(() => _currentStep = 1);
                        } else if (_currentStep == 1) {
                          if (_isPastStartDate) {
                            setState(() => _currentStep = 2);
                          } else {
                            setState(() => _currentStep = 3);
                          }
                        } else if (_currentStep == 2) {
                          setState(() => _currentStep = 3);
                        } else {
                          _completeOnboarding();
                        }
                      },
                      child: Text(
                        _currentStep == 3
                            ? 'Finish & Start Tracking'
                            : 'Continue',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStep(ThemeData theme, bool isDark) {
    switch (_currentStep) {
      case 0:
        return _buildStep1StartAndCadence(theme, isDark);
      case 1:
        return _buildStep2RecurringBonus(theme, isDark);
      case 2:
        return _buildStep3HistoricalCatchUp(theme, isDark);
      case 3:
      default:
        return _buildStep4Rules(theme, isDark);
    }
  }

  // STEP 1: Start Month & Cadence
  Widget _buildStep1StartAndCadence(ThemeData theme, bool isDark) {
    final now = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'When does your acquisition timeline start?',
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          'Canelé computes transparent book quotas strictly from this start month onwards.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        CaneleCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Timeline Start Month', style: theme.textTheme.titleMedium),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _startDate = DateTime(now.year, now.month, 1);
                        _noBookPickerDate = _startDate;
                        _bonusPickerDate = _startDate;
                      });
                    },
                    icon: const Icon(Icons.today_rounded, size: 16),
                    label: const Text('Current Month'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              CaneleMonthYearSelector(
                selectedDate: _startDate,
                onChanged: (newDate) {
                  setState(() {
                    _startDate = newDate;
                    final currentYear = DateTime.now().year;
                    final clampedYear = newDate.year <= currentYear ? newDate.year : currentYear;
                    _noBookPickerDate = DateTime(clampedYear, newDate.month, 1);
                    _bonusPickerDate = DateTime(clampedYear, newDate.month, 1);
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        CaneleCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Regular Monthly Cadence', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text('Target books per active month', style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: _regularPerMonth > 1 ? () => setState(() => _regularPerMonth--) : null,
                  ),
                  Text(
                    '$_regularPerMonth / mo',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => setState(() => _regularPerMonth++),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        CaneleCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Preferred Currency', style: theme.textTheme.titleMedium),
              const SizedBox(height: 2),
              Text('Used for price tracking and spend analytics', style: theme.textTheme.bodySmall),
              const SizedBox(height: 12),
              Row(
                children: [
                  for (final opt in CurrencyHelper.supportedCurrencies) ...[
                    if (opt != CurrencyHelper.supportedCurrencies.first) const SizedBox(width: 6),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _currency = opt.code),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
                          decoration: BoxDecoration(
                            color: _currency == opt.code
                                ? AppColors.caramelizedAmber.withValues(alpha: isDark ? 0.25 : 0.15)
                                : (isDark ? AppColors.darkPastryCardElevated : AppColors.pastryCrustLight),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _currency == opt.code
                                  ? AppColors.caramelizedAmber
                                  : (isDark ? AppColors.darkPastryBorder : AppColors.pastryCrustBorder),
                              width: _currency == opt.code ? 1.5 : 1.0,
                            ),
                          ),
                          child: Column(
                            children: [
                              CurrencySymbolText(
                                currencyCode: opt.code,
                                baseFontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: _currency == opt.code
                                    ? (isDark ? AppColors.caramelizedAmberLight : AppColors.caramelizedAmber)
                                    : (isDark ? AppColors.darkTextPrimary : AppColors.deepCaramel),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                opt.code,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _currency == opt.code
                                      ? (isDark ? AppColors.caramelizedAmberLight : AppColors.caramelizedAmber)
                                      : (isDark ? AppColors.darkTextMuted : AppColors.deepCaramelMuted),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // STEP 2: Recurring Bonus Schedule (Optional)
  Widget _buildStep2RecurringBonus(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recurring Bonus Schedule (Optional)',
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          'Bonus books are completely optional. Select annual months where you budget extra book acquisitions (e.g. Birthday, Christmas/Holidays), or leave all unselected if not needed.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),

        CaneleCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Bonus Months', style: theme.textTheme.titleMedium),
                  if (_selectedBonusMonths.isNotEmpty)
                    TextButton(
                      onPressed: () => setState(() => _selectedBonusMonths.clear()),
                      child: const Text('Clear All'),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              Column(
                children: [
                  Row(
                    children: [
                      for (int i = 0; i < 6; i++) ...[
                        if (i > 0) const SizedBox(width: 6),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              final monthNum = i + 1;
                              setState(() {
                                if (_selectedBonusMonths.contains(monthNum)) {
                                  _selectedBonusMonths.remove(monthNum);
                                } else {
                                  _selectedBonusMonths.add(monthNum);
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _selectedBonusMonths.contains(i + 1)
                                    ? AppColors.caramelizedAmber.withValues(alpha: isDark ? 0.25 : 0.15)
                                    : (isDark ? AppColors.darkPastryCardElevated : AppColors.pastryCrustLight),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _selectedBonusMonths.contains(i + 1)
                                      ? AppColors.caramelizedAmber
                                      : (isDark ? AppColors.darkPastryBorder : AppColors.pastryCrustBorder),
                                  width: _selectedBonusMonths.contains(i + 1) ? 1.5 : 1.0,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                _monthNames[i],
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: _selectedBonusMonths.contains(i + 1) ? FontWeight.w800 : FontWeight.w600,
                                  color: _selectedBonusMonths.contains(i + 1)
                                      ? (isDark ? AppColors.caramelizedAmberLight : AppColors.caramelizedAmber)
                                      : (isDark ? AppColors.darkTextMuted : AppColors.deepCaramelMuted),
                                ),
                              ),
                            ),
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
                          child: InkWell(
                            onTap: () {
                              final monthNum = i + 1;
                              setState(() {
                                if (_selectedBonusMonths.contains(monthNum)) {
                                  _selectedBonusMonths.remove(monthNum);
                                } else {
                                  _selectedBonusMonths.add(monthNum);
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _selectedBonusMonths.contains(i + 1)
                                    ? AppColors.caramelizedAmber.withValues(alpha: isDark ? 0.25 : 0.15)
                                    : (isDark ? AppColors.darkPastryCardElevated : AppColors.pastryCrustLight),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _selectedBonusMonths.contains(i + 1)
                                      ? AppColors.caramelizedAmber
                                      : (isDark ? AppColors.darkPastryBorder : AppColors.pastryCrustBorder),
                                  width: _selectedBonusMonths.contains(i + 1) ? 1.5 : 1.0,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                _monthNames[i],
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: _selectedBonusMonths.contains(i + 1) ? FontWeight.w800 : FontWeight.w600,
                                  color: _selectedBonusMonths.contains(i + 1)
                                      ? (isDark ? AppColors.caramelizedAmberLight : AppColors.caramelizedAmber)
                                      : (isDark ? AppColors.darkTextMuted : AppColors.deepCaramelMuted),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),

              if (_selectedBonusMonths.isEmpty)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkPastryCardElevated : AppColors.pastryCrustLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.caramelizedAmber),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No recurring bonus months selected (optional). Quota will be strictly based on your regular monthly cadence.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        CaneleCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recurring No-Book Months', style: theme.textTheme.titleMedium),
                  if (_selectedRecurringNoBookMonths.isNotEmpty)
                    TextButton(
                      onPressed: () => setState(() => _selectedRecurringNoBookMonths.clear()),
                      child: const Text('Clear All'),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Select annual months where you pause regular acquisitions (0 regular books).',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 12),

              Column(
                children: [
                  Row(
                    children: [
                      for (int i = 0; i < 6; i++) ...[
                        if (i > 0) const SizedBox(width: 6),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              final monthNum = i + 1;
                              setState(() {
                                if (_selectedRecurringNoBookMonths.contains(monthNum)) {
                                  _selectedRecurringNoBookMonths.remove(monthNum);
                                } else {
                                  _selectedRecurringNoBookMonths.add(monthNum);
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _selectedRecurringNoBookMonths.contains(i + 1)
                                    ? AppColors.caramelizedAmber.withValues(alpha: isDark ? 0.25 : 0.15)
                                    : (isDark ? AppColors.darkPastryCardElevated : AppColors.pastryCrustLight),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _selectedRecurringNoBookMonths.contains(i + 1)
                                      ? AppColors.caramelizedAmber
                                      : (isDark ? AppColors.darkPastryBorder : AppColors.pastryCrustBorder),
                                  width: _selectedRecurringNoBookMonths.contains(i + 1) ? 1.5 : 1.0,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                _monthNames[i],
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: _selectedRecurringNoBookMonths.contains(i + 1) ? FontWeight.w800 : FontWeight.w600,
                                  color: _selectedRecurringNoBookMonths.contains(i + 1)
                                      ? (isDark ? AppColors.caramelizedAmberLight : AppColors.caramelizedAmber)
                                      : (isDark ? AppColors.darkTextMuted : AppColors.deepCaramelMuted),
                                ),
                              ),
                            ),
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
                          child: InkWell(
                            onTap: () {
                              final monthNum = i + 1;
                              setState(() {
                                if (_selectedRecurringNoBookMonths.contains(monthNum)) {
                                  _selectedRecurringNoBookMonths.remove(monthNum);
                                } else {
                                  _selectedRecurringNoBookMonths.add(monthNum);
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _selectedRecurringNoBookMonths.contains(i + 1)
                                    ? AppColors.caramelizedAmber.withValues(alpha: isDark ? 0.25 : 0.15)
                                    : (isDark ? AppColors.darkPastryCardElevated : AppColors.pastryCrustLight),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _selectedRecurringNoBookMonths.contains(i + 1)
                                      ? AppColors.caramelizedAmber
                                      : (isDark ? AppColors.darkPastryBorder : AppColors.pastryCrustBorder),
                                  width: _selectedRecurringNoBookMonths.contains(i + 1) ? 1.5 : 1.0,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                _monthNames[i],
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: _selectedRecurringNoBookMonths.contains(i + 1) ? FontWeight.w800 : FontWeight.w600,
                                  color: _selectedRecurringNoBookMonths.contains(i + 1)
                                      ? (isDark ? AppColors.caramelizedAmberLight : AppColors.caramelizedAmber)
                                      : (isDark ? AppColors.darkTextMuted : AppColors.deepCaramelMuted),
                                ),
                              ),
                            ),
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
      ],
    );
  }

  // STEP 3: Historical Catch-Up (Conditional for Past Start Dates)
  Widget _buildStep3HistoricalCatchUp(ThemeData theme, bool isDark) {
    final now = DateTime.now();
    final startYear = _startDate.year;
    final currentYear = now.year;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Historical Catch-Up',
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          'Because your start month is in the past, configure any past skipped months or one-off bonuses to align your ledger.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),

        // Past No-Book Months (Collapsible)
        CaneleCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    _isPastNoBookExpanded = !_isPastNoBookExpanded;
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
                              Text('Past "No-Book Months"', style: theme.textTheme.titleMedium),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkPastryCardElevated : AppColors.pastryCrustLight,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.pastryCrustBorder, width: 0.8),
                                ),
                                child: Text(
                                  '${_selectedNoBookMonths.length}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.caramelizedAmber,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Past months where 0 regular books were budgeted',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      _isPastNoBookExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                      color: isDark ? AppColors.darkTextMuted : AppColors.deepCaramelMuted,
                    ),
                  ],
                ),
              ),
              if (_isPastNoBookExpanded) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Text(
                  'Select a past month, then tap Add:',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 10),
                CaneleMonthYearSelector(
                  selectedDate: _noBookPickerDate,
                  startYear: startYear,
                  endYear: currentYear,
                  onChanged: (newDate) {
                    setState(() {
                      _noBookPickerDate = newDate;
                    });
                  },
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add No-Book Month'),
                    onPressed: () {
                      final mKey = DateFormatter.toMonthKey(_noBookPickerDate);
                      setState(() {
                        _selectedNoBookMonths.add(mKey);
                      });
                    },
                  ),
                ),
                const SizedBox(height: 14),
                if (_selectedNoBookMonths.isEmpty)
                  Text(
                    'No past no-book months added (optional).',
                    style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (_selectedNoBookMonths.toList()..sort((a, b) => b.compareTo(a))).map((mKey) {
                      final date = DateFormatter.fromMonthKey(mKey);
                      return Chip(
                        label: Text(DateFormatter.formatMonthYear(date)),
                        deleteIcon: const Icon(Icons.close_rounded, size: 16),
                        onDeleted: () {
                          setState(() {
                            _selectedNoBookMonths.remove(mKey);
                          });
                        },
                        backgroundColor: isDark ? AppColors.darkPastryCardElevated : AppColors.pastryCrustLight,
                        side: BorderSide(
                          color: isDark ? AppColors.darkPastryBorder : AppColors.pastryCrustBorder,
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Past One-Off Bonus Ledger (Collapsible)
        CaneleCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    _isPastBonusesExpanded = !_isPastBonusesExpanded;
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
                              Text('Past One-Off Bonuses', style: theme.textTheme.titleMedium),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkPastryCardElevated : AppColors.pastryCrustLight,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.pastryCrustBorder, width: 0.8),
                                ),
                                child: Text(
                                  '${_customBonusLedger.length}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.caramelizedAmber,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'One-off bonus quota added to past months',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      _isPastBonusesExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                      color: isDark ? AppColors.darkTextMuted : AppColors.deepCaramelMuted,
                    ),
                  ],
                ),
              ),
              if (_isPastBonusesExpanded) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Text(
                  'Select a past month and bonus count, then tap Add:',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 10),
                CaneleMonthYearSelector(
                  selectedDate: _bonusPickerDate,
                  startYear: startYear,
                  endYear: currentYear,
                  onChanged: (newDate) {
                    setState(() {
                      _bonusPickerDate = newDate;
                    });
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkPastryCardElevated : AppColors.pastryCrustLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark ? AppColors.darkPastryBorder : AppColors.pastryCrustBorder,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, size: 20),
                            onPressed: _bonusPickerCount > 1
                                ? () => setState(() => _bonusPickerCount--)
                                : null,
                          ),
                          Text(
                            '+$_bonusPickerCount Bonus',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, size: 20),
                            onPressed: () => setState(() => _bonusPickerCount++),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add Bonus'),
                        onPressed: () {
                          final mKey = DateFormatter.toMonthKey(_bonusPickerDate);
                          setState(() {
                            _customBonusLedger[mKey] =
                                (_customBonusLedger[mKey] ?? 0) + _bonusPickerCount;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (_customBonusLedger.isEmpty)
                  Text(
                    'No past one-off bonuses added (optional).',
                    style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                  )
                else
                  Column(
                    children: (_customBonusLedger.entries.toList()
                          ..sort((a, b) => b.key.compareTo(a.key)))
                        .map((entry) {
                      final date = DateFormatter.fromMonthKey(entry.key);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkPastryCardElevated : AppColors.pastryCrustLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark ? AppColors.darkPastryBorder : AppColors.pastryCrustBorder,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  DateFormatter.formatMonthYear(date),
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                                Text(
                                  '+${entry.value} Bonus book${entry.value > 1 ? 's' : ''}',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded,
                                  color: AppColors.statusDanger, size: 20),
                              onPressed: () {
                                setState(() {
                                  _customBonusLedger.remove(entry.key);
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // STEP 4: Recommendation Rules
  Widget _buildStep4Rules(ThemeData theme, bool isDark) {
    final rules = ref.watch(rulesNotifierProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configure Recommendation Rules',
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          'Canelé uses priority rules to automatically pick which books to recommend each month.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),

        // Radio options group
        RadioGroup<String>(
          groupValue: _ruleSetupOption,
          onChanged: (val) {
            if (val != null) setState(() => _ruleSetupOption = val);
          },
          child: Column(
            children: [
              // Option 1: Use Default Rules Card
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => setState(() => _ruleSetupOption = 'default'),
                child: CaneleCard(
                  borderColor: _ruleSetupOption == 'default'
                      ? AppColors.caramelizedAmber
                      : (isDark ? AppColors.darkPastryBorder : AppColors.pastryCrustBorder),
                  backgroundColor: _ruleSetupOption == 'default'
                      ? AppColors.caramelizedAmber.withValues(alpha: isDark ? 0.12 : 0.06)
                      : null,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.caramelizedAmber.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          color: AppColors.caramelizedAmber,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    'Use Default Rules',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.caramelizedAmber.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'RECOMMENDED',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.caramelizedAmber,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '3 balanced priority rules tailored for any collection.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark ? AppColors.darkTextMuted : AppColors.deepCaramelMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Radio<String>(
                        value: 'default',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Option 2: Create Custom Rules Card
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => setState(() => _ruleSetupOption = 'custom'),
                child: CaneleCard(
                  borderColor: _ruleSetupOption == 'custom'
                      ? AppColors.caramelizedAmber
                      : (isDark ? AppColors.darkPastryBorder : AppColors.pastryCrustBorder),
                  backgroundColor: _ruleSetupOption == 'custom'
                      ? AppColors.caramelizedAmber.withValues(alpha: isDark ? 0.12 : 0.06)
                      : null,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.caramelizedAmber.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.tune_rounded,
                          color: AppColors.caramelizedAmber,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Create Custom Rules',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Design rules from scratch for specific series, formats, or criteria.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark ? AppColors.darkTextMuted : AppColors.deepCaramelMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Radio<String>(
                        value: 'custom',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Content for selected option
        if (_ruleSetupOption == 'default') ...[
          if (rules.isEmpty) ...[
            CaneleCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Included Default Rules',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.caramelizedAmber.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '3 Standard Rules',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.caramelizedAmber,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildDefaultRuleItem(
                    theme,
                    isDark,
                    number: 1,
                    title: 'Prioritize Restocked Volumes',
                    desc: 'Bumps volumes marked on your restock watchlist to the top of your monthly recommendations.',
                    icon: Icons.notifications_active_outlined,
                  ),
                  const SizedBox(height: 10),
                  _buildDefaultRuleItem(
                    theme,
                    isDark,
                    number: 2,
                    title: 'Finish Near-Complete Series',
                    desc: 'Prioritizes series with 3 or fewer unowned volumes to help you complete them.',
                    icon: Icons.flag_outlined,
                  ),
                  const SizedBox(height: 10),
                  _buildDefaultRuleItem(
                    theme,
                    isDark,
                    number: 3,
                    title: 'Sequential Next Volume',
                    desc: 'Recommends the next unowned volume in sequential order for your active series.',
                    icon: Icons.format_list_numbered_rounded,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final defaults = _getDefaultRules();
                        for (final r in defaults) {
                          await ref.read(rulesNotifierProvider.notifier).saveRule(r);
                        }
                      },
                      icon: const Icon(Icons.playlist_add_check_rounded, size: 18),
                      label: const Text('Apply & Customize Rules Now'),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Active Rules (${rules.length})',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                TextButton.icon(
                  onPressed: () => EditRuleSheet.show(context),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add Rule'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...rules.asMap().entries.map((entry) {
              final idx = entry.key;
              final rule = entry.value;
              return RuleCard(
                rule: rule,
                displayIndex: idx,
                onTap: () => EditRuleSheet.show(context, rule: rule),
                onToggleEnabled: (val) {
                  ref.read(rulesNotifierProvider.notifier).toggleRule(rule.id, val);
                },
              );
            }),
          ],
        ] else ...[
          // Custom Rules Mode
          if (rules.isEmpty) ...[
            CaneleCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(
                    Icons.tune_rounded,
                    size: 44,
                    color: AppColors.caramelizedAmber,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No Custom Rules Yet',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Create your first custom rule to control which books are recommended each month.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => EditRuleSheet.show(context),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Create Custom Rule'),
                  ),
                ],
              ),
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Custom Rules (${rules.length})',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                TextButton.icon(
                  onPressed: () => EditRuleSheet.show(context),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add Rule'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...rules.asMap().entries.map((entry) {
              final idx = entry.key;
              final rule = entry.value;
              return RuleCard(
                rule: rule,
                displayIndex: idx,
                onTap: () => EditRuleSheet.show(context, rule: rule),
                onToggleEnabled: (val) {
                  ref.read(rulesNotifierProvider.notifier).toggleRule(rule.id, val);
                },
              );
            }),
          ],
        ],

        const SizedBox(height: 16),
        CaneleCard(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, size: 20, color: AppColors.caramelizedAmber),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'You can customize, reorder, and add more rules at any time in the Rule Studio.',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultRuleItem(
    ThemeData theme,
    bool isDark, {
    required int number,
    required String title,
    required String desc,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkPastryCardElevated : AppColors.pastryCrustLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppColors.darkPastryBorder : AppColors.pastryCrustBorder,
          width: 0.8,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.caramelizedAmber.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: AppColors.caramelizedAmber),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$number. $title',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int step;
  final String title;
  final bool isActive;
  final bool isDone;

  const _StepIndicator({
    required this.step,
    required this.title,
    required this.isActive,
    required this.isDone,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color bg;
    final Color fg;
    final Color textColor;

    if (isActive) {
      bg = AppColors.caramelizedAmber;
      fg = Colors.white;
      textColor = isDark ? AppColors.caramelizedAmberLight : AppColors.caramelizedAmber;
    } else if (isDone) {
      bg = isDark ? AppColors.caramelizedAmberLight : AppColors.caramelizedAmber;
      fg = Colors.white;
      textColor = isDark ? AppColors.darkTextPrimary : AppColors.deepCaramel;
    } else {
      bg = isDark ? AppColors.darkPastryBorder : AppColors.pastryCrustBorder;
      fg = isDark ? AppColors.darkTextMuted : AppColors.deepCaramelMuted;
      textColor = isDark ? AppColors.darkTextMuted : AppColors.deepCaramelMuted;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: isDone
              ? const Icon(Icons.check_rounded, size: 13, color: Colors.white)
              : Text(
                  '$step',
                  style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w700),
                ),
        ),
        const SizedBox(width: 4),
        Text(
          title,
          style: TextStyle(
            fontWeight: (isActive || isDone) ? FontWeight.w700 : FontWeight.w500,
            color: textColor,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
