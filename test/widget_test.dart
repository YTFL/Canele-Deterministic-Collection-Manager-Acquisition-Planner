import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:canele/models/rule_config.dart';
import 'package:canele/models/rule_model.dart';
import 'package:canele/providers/rule_provider.dart';
import 'package:canele/services/quota_engine.dart';
import 'package:canele/providers/quota_provider.dart';
import 'package:canele/models/series.dart';
import 'package:canele/models/volume.dart';
import 'package:canele/models/purchase_transaction.dart';
import 'package:canele/providers/series_provider.dart';
import 'package:canele/ui/widgets/add_series_sheet.dart';
import 'package:canele/ui/widgets/quota_status_card.dart';
import 'package:canele/ui/widgets/canele_month_year_picker.dart';
import 'package:canele/ui/screens/onboarding_screen.dart';
import 'package:canele/ui/screens/series_detail_screen.dart';

class MockRulesNotifier extends StateNotifier<List<RuleModel>> implements RulesNotifier {
  MockRulesNotifier(super.state);
  @override
  void load() {}
  @override
  Future<void> saveRule(RuleModel rule) async {
    state = [...state, rule];
  }
  @override
  Future<void> deleteRule(String id) async {
    state = state.where((r) => r.id != id).toList();
  }
  @override
  Future<void> toggleRule(String id, bool isEnabled) async {
    state = state.map((r) => r.id == id ? r.copyWith(isEnabled: isEnabled) : r).toList();
  }
  @override
  Future<void> reorderRules(int oldIndex, int newIndex) async {}
}

class MockSeriesNotifier extends StateNotifier<List<Series>> implements SeriesNotifier {
  MockSeriesNotifier(super.state);
  @override
  void load() {}
  @override
  Future<void> saveSeries(Series series) async {}
  @override
  Future<Series> createSeriesWithVolumes({
    required String title,
    required String type,
    String collectionStatus = 'active',
    String releaseStatus = 'ongoing',
    int totalReleasedVolumes = 1,
    int ownedCount = 0,
    bool markOwned = true,
    bool isGift = false,
    List<String> tags = const [],
    Map<String, dynamic> customMetadata = const {},
  }) async => state.first;
  @override
  Future<void> deleteSeries(String id) async {}
}

class MockVolumesNotifier extends StateNotifier<List<Volume>> implements VolumesNotifier {
  MockVolumesNotifier(super.state);
  @override
  void load() {}
  @override
  Future<void> saveVolume(Volume volume) async {}
  @override
  Future<void> saveBatch(List<Volume> volumes) async {}
  @override
  Future<void> deleteVolume(String id) async {}
  @override
  Future<void> toggleOwned(Volume volume, {bool? asGift}) async {}
}

class MockTransactionsNotifier extends StateNotifier<List<PurchaseTransaction>> implements TransactionsNotifier {
  MockTransactionsNotifier(super.state);
  @override
  void load() {}
  @override
  Future<void> saveTransaction(PurchaseTransaction transaction) async {}
  @override
  Future<void> deleteTransaction(String id) async {}
}

class MockRuleConfigNotifier extends StateNotifier<RuleConfig> implements RuleConfigNotifier {
  MockRuleConfigNotifier(super.state);

  @override
  void load() {}

  @override
  Future<void> updateConfig(RuleConfig config) async {
    state = config;
  }
}

void main() {
  testWidgets('Renders QuotaStatusCard correctly with 3 balance tiles', (WidgetTester tester) async {
    final config = RuleConfig(
      timelineStartDate: DateTime(2024, 1, 1),
      defaultRegularPerMonth: 1,
      bonusMonths: const [5, 12],
    );

    final summary = QuotaEngine.calculate(
      config: config,
      transactions: const [],
      asOfDate: DateTime(2024, 3, 1),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ruleConfigNotifierProvider.overrideWith((ref) => MockRuleConfigNotifier(config)),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: QuotaStatusCard(summary: summary),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Acquisition Quota & Ledger'), findsOneWidget);
    expect(find.text('Regular'), findsOneWidget);
    expect(find.text('Bonus'), findsOneWidget);
    expect(find.text('Total Open'), findsOneWidget);
    expect(find.text('+1 Bonus'), findsOneWidget);
    expect(find.text('Skip Month'), findsOneWidget);
  });

  testWidgets('Onboarding Step 2 has no bonus months checked by default', (WidgetTester tester) async {
    final config = RuleConfig.createDefault();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ruleConfigNotifierProvider.overrideWith((ref) => MockRuleConfigNotifier(config)),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: OnboardingScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Click continue to go to Step 2
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Recurring Bonus Schedule (Optional)'), findsOneWidget);

    // Verify all 12 month buttons are rendered
    for (final m in ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']) {
      expect(find.text(m), findsOneWidget);
    }
  });

  testWidgets('Onboarding Step 3 has Year & Month picker with Add buttons for No-Book Months and Bonuses', (WidgetTester tester) async {
    final config = RuleConfig.createDefault();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ruleConfigNotifierProvider.overrideWith((ref) => MockRuleConfigNotifier(config)),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: OnboardingScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // In Step 1, tap the year button to open the 3x3 grid picker
    await tester.tap(find.byKey(const Key('canele_year_selector_button')).first);
    await tester.pumpAndSettle();

    // In the 3x3 grid picker, select '2024'
    await tester.tap(find.text('2024'));
    await tester.pumpAndSettle();

    // Go to Step 2
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Go to Step 3 (Historical Catch-Up)
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Historical Catch-Up'), findsOneWidget);

    // Tap to expand Past "No-Book Months"
    await tester.tap(find.text('Past "No-Book Months"'));
    await tester.pumpAndSettle();

    expect(find.text('Add No-Book Month'), findsOneWidget);

    // Tap Add No-Book Month
    await tester.tap(find.text('Add No-Book Month'));
    await tester.pumpAndSettle();

    // Verify chip was added with delete icon
    expect(find.byType(Chip), findsOneWidget);

    // Tap to expand Past One-Off Bonuses
    await tester.ensureVisible(find.text('Past One-Off Bonuses'));
    await tester.tap(find.text('Past One-Off Bonuses'));
    await tester.pumpAndSettle();

    expect(find.text('Add Bonus'), findsOneWidget);

    // Tap Add Bonus
    await tester.ensureVisible(find.text('Add Bonus'));
    await tester.tap(find.text('Add Bonus'));
    await tester.pumpAndSettle();

    // Verify bonus entry was added
    expect(find.text('+1 Bonus book'), findsOneWidget);
  });

  testWidgets('CaneleMonthYearSelector opens 3x3 Year Grid Picker with pagination arrows', (tester) async {
    DateTime selected = DateTime(2026, 1, 1);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return CaneleMonthYearSelector(
                selectedDate: selected,
                minYear: 1970,
                maxYear: 2026,
                onChanged: (d) => setState(() => selected = d),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap the year button
    await tester.tap(find.byKey(const Key('canele_year_selector_button')));
    await tester.pumpAndSettle();

    // Dialog should be open displaying the 3x3 grid range (2018 - 2026)
    expect(find.text('2018 – 2026'), findsOneWidget);
    expect(find.text('2018'), findsOneWidget);

    // Tap older years arrow (<)
    await tester.tap(find.byTooltip('Older Years'));
    await tester.pumpAndSettle();

    // Page 2 should be 2009 - 2017
    expect(find.text('2009 – 2017'), findsOneWidget);
    expect(find.text('2015'), findsOneWidget);

    // Select 2015 from the grid
    await tester.tap(find.text('2015'));
    await tester.pumpAndSettle();

    // Dialog should close and main selector should now show 2015
    expect(find.text('2015'), findsOneWidget);
    expect(selected.year, 2015);
  });

  testWidgets('Add Volume dialog automatically fills next volume number (e.g. 11 if 10 volumes exist)', (tester) async {
    final testSeries = Series(id: 's1', title: '86 - Eighty-Six', type: 'lightNovel');
    final testVolumes = List.generate(10, (i) => Volume(
      id: 'v${i + 1}',
      seriesId: 's1',
      volumeNumber: (i + 1).toDouble(),
      isOwned: true,
    ));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          seriesNotifierProvider.overrideWith((ref) => MockSeriesNotifier([testSeries])),
          volumesNotifierProvider.overrideWith((ref) => MockVolumesNotifier(testVolumes)),
          transactionsNotifierProvider.overrideWith((ref) => MockTransactionsNotifier([])),
        ],
        child: const MaterialApp(
          home: SeriesDetailScreen(seriesId: 's1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap Add Volume button
    await tester.ensureVisible(find.text('Add Volume'));
    await tester.tap(find.text('Add Volume'));
    await tester.pumpAndSettle();

    // Check that Volume Number text field has '11'
    expect(find.widgetWithText(TextField, '11'), findsOneWidget);
  });

  testWidgets('Onboarding Step 4 allows setting recommendation rules and adding starter rules', (WidgetTester tester) async {
    final config = RuleConfig.createDefault();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ruleConfigNotifierProvider.overrideWith((ref) => MockRuleConfigNotifier(config)),
          rulesNotifierProvider.overrideWith((ref) => MockRulesNotifier([])),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: OnboardingScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // In Step 1, click Continue
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // In Step 2, click Continue (since start date is current month, goes to Step 4)
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Configure Recommendation Rules'), findsOneWidget);
    expect(find.text('Add Recommended Starter Rules'), findsOneWidget);
    expect(find.text('Finish & Start Tracking'), findsOneWidget);

    // Tap Add Recommended Starter Rules
    await tester.tap(find.text('Add Recommended Starter Rules'));
    await tester.pumpAndSettle();

    // Verify 3 starter rules are added
    expect(find.text('Prioritize Restocked Volumes'), findsOneWidget);
    expect(find.text('Series Closer to Completion'), findsOneWidget);
    expect(find.text('Sequential Next Volume'), findsOneWidget);
  });

  testWidgets('AddSeriesSheet shows "Series" and "Single" labels and resets owned count when switching back to Series', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          seriesNotifierProvider.overrideWith((ref) => MockSeriesNotifier([])),
          volumesNotifierProvider.overrideWith((ref) => MockVolumesNotifier([])),
          transactionsNotifierProvider.overrideWith((ref) => MockTransactionsNotifier([])),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: AddSeriesSheet(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify segmented button labels are 'Series' and 'Single'
    expect(find.text('Series'), findsOneWidget);
    expect(find.text('Single'), findsOneWidget);

    // Initially in Series mode with 0 owned volumes, so the "Mark Volumes" checkbox is not shown
    expect(find.textContaining('Mark Volumes 1 to'), findsNothing);

    // Switch to Single mode
    await tester.tap(find.text('Single'));
    await tester.pumpAndSettle();

    // In Single mode, it shows 'Mark this book as Owned'
    expect(find.text('Mark this book as Owned'), findsOneWidget);

    // Switch back to Series mode
    await tester.tap(find.text('Series'));
    await tester.pumpAndSettle();

    // After switching back to Series, owned count should be reset to 0, so "Mark Volumes 1 to 1 as Owned" should NOT exist
    expect(find.textContaining('Mark Volumes 1 to'), findsNothing);
  });
}
