import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class CaneleMonthYearSelector extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onChanged;
  final int minYear;
  final int maxYear;

  static const List<String> monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  CaneleMonthYearSelector({
    super.key,
    required this.selectedDate,
    required this.onChanged,
    int? minYear,
    int? maxYear,
    int? startYear, // Backwards compatibility
    int? endYear,   // Backwards compatibility
  })  : minYear = minYear ?? startYear ?? 1970,
        maxYear = maxYear ?? endYear ?? DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final effectiveMax = maxYear;
    final effectiveMin = minYear <= effectiveMax ? minYear : effectiveMax;

    return Row(
      children: [
        // Month Dropdown
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkPastryCardElevated : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? AppColors.darkPastryBorder : AppColors.pastryCrustBorder,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: selectedDate.month,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: AppColors.caramelizedAmber),
                dropdownColor: isDark ? AppColors.darkPastryCard : Colors.white,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.deepCaramel,
                ),
                items: List.generate(12, (index) {
                  final monthNum = index + 1;
                  return DropdownMenuItem<int>(
                    value: monthNum,
                    child: Text(monthNames[index]),
                  );
                }),
                onChanged: (newMonth) {
                  if (newMonth != null) {
                    onChanged(DateTime(selectedDate.year, newMonth, 1));
                  }
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Year Selector (Taps to open 3x3 Grid Picker)
        Expanded(
          flex: 2,
          child: InkWell(
            key: const Key('canele_year_selector_button'),
            onTap: () async {
              final pickedYear = await showCaneleYearGridPicker(
                context,
                initialYear: selectedDate.year,
                minYear: effectiveMin,
                maxYear: effectiveMax,
              );
              if (pickedYear != null) {
                onChanged(DateTime(pickedYear, selectedDate.month, 1));
              }
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkPastryCardElevated : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? AppColors.darkPastryBorder : AppColors.pastryCrustBorder,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${selectedDate.year}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.deepCaramel,
                    ),
                  ),
                  const Icon(
                    Icons.calendar_month_rounded,
                    size: 18,
                    color: AppColors.caramelizedAmber,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 3x3 Grid Year Picker Dialog with Page Arrows (< and >)
Future<int?> showCaneleYearGridPicker(
  BuildContext context, {
  required int initialYear,
  int minYear = 1970,
  int? maxYear,
}) async {
  final finalYear = maxYear ?? DateTime.now().year;
  final startYear = minYear <= finalYear ? minYear : finalYear;

  return showDialog<int>(
    context: context,
    builder: (ctx) => _YearGridPickerDialog(
      initialYear: initialYear.clamp(startYear, finalYear),
      minYear: startYear,
      maxYear: finalYear,
    ),
  );
}

class _YearGridPickerDialog extends StatefulWidget {
  final int initialYear;
  final int minYear;
  final int maxYear;

  const _YearGridPickerDialog({
    required this.initialYear,
    required this.minYear,
    required this.maxYear,
  });

  @override
  State<_YearGridPickerDialog> createState() => _YearGridPickerDialogState();
}

class _YearGridPickerDialogState extends State<_YearGridPickerDialog> {
  static const int _pageSize = 9; // 3x3 Grid
  late List<List<int>> _pages;
  late int _currentPageIndex;

  @override
  void initState() {
    super.initState();
    _buildPages();
  }

  void _buildPages() {
    _pages = [];
    // Build pages from maxYear backwards so the latest page ends at maxYear (e.g. 2018 - 2026)
    int currentUpper = widget.maxYear;
    while (currentUpper >= widget.minYear) {
      int lower = currentUpper - _pageSize + 1;
      if (lower < widget.minYear) lower = widget.minYear;
      final pageYears = <int>[];
      for (int y = lower; y <= currentUpper; y++) {
        pageYears.add(y);
      }
      _pages.add(pageYears);
      currentUpper = lower - 1;
    }

    // Find which page contains the initialYear
    _currentPageIndex = _pages.indexWhere((p) => p.contains(widget.initialYear));
    if (_currentPageIndex == -1) _currentPageIndex = 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentPage = _pages[_currentPageIndex];
    final bool hasNewerPage = _currentPageIndex > 0;
    final bool hasOlderPage = _currentPageIndex < _pages.length - 1;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? AppColors.darkPastryCard : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            // Page Header with < range >
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  tooltip: 'Older Years',
                  color: hasOlderPage
                      ? (isDark ? AppColors.caramelizedAmberLight : AppColors.caramelizedAmber)
                      : (isDark ? AppColors.darkTextMuted : AppColors.pastryCrustBorder),
                  onPressed: hasOlderPage
                      ? () => setState(() => _currentPageIndex++)
                      : null,
                ),
                Text(
                  '${currentPage.first} – ${currentPage.last}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.deepCaramel,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  tooltip: 'Newer Years',
                  color: hasNewerPage
                      ? (isDark ? AppColors.caramelizedAmberLight : AppColors.caramelizedAmber)
                      : (isDark ? AppColors.darkTextMuted : AppColors.pastryCrustBorder),
                  onPressed: hasNewerPage
                      ? () => setState(() => _currentPageIndex--)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 3x3 Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.6,
              ),
              itemCount: currentPage.length,
              itemBuilder: (context, index) {
                final year = currentPage[index];
                final isSelected = year == widget.initialYear;

                return InkWell(
                  onTap: () => Navigator.pop(context, year),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.caramelizedAmber
                          : (isDark ? AppColors.darkPastryCardElevated : AppColors.pastryCrustLight),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.caramelizedAmber
                            : (isDark ? AppColors.darkPastryBorder : AppColors.pastryCrustBorder),
                        width: isSelected ? 1.5 : 0.8,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$year',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? AppColors.darkTextPrimary : AppColors.deepCaramel),
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            // Cancel Button
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Show a reusable Month/Year dialog anywhere in the app
Future<DateTime?> showCaneleMonthYearDialog(
  BuildContext context, {
  required DateTime initialDate,
  int minYear = 1970,
  int? maxYear,
}) async {
  DateTime tempDate = DateTime(initialDate.year, initialDate.month, 1);

  return showDialog<DateTime>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Select Month & Year'),
            content: CaneleMonthYearSelector(
              selectedDate: tempDate,
              minYear: minYear,
              maxYear: maxYear,
              onChanged: (d) {
                setDialogState(() => tempDate = d);
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, null),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, tempDate),
                child: const Text('Select'),
              ),
            ],
          );
        },
      );
    },
  );
}
