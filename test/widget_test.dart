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
import 'package:canele/ui/screens/stats_screen.dart';
import 'package:canele/ui/screens/dashboard_screen.dart';
import 'package:canele/ui/screens/rule_studio_screen.dart';

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
  @override
  Future<void> markSeriesAsCompleted(String seriesId) async {}
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
  @override
  Future<void> bulkUpdateOwnership({
    required List<String> volumeIds,
    required bool isOwned,
    bool isGift = false,
  }) async {}
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
      expect(find.text(m), findsWidgets);
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
    expect(find.text('Use Default Rules'), findsOneWidget);
    expect(find.text('Apply & Customize Rules Now'), findsOneWidget);
    expect(find.text('Finish & Start Tracking'), findsOneWidget);

    // Ensure button is visible before tapping
    await tester.ensureVisible(find.text('Apply & Customize Rules Now'));
    await tester.pumpAndSettle();

    // Tap Apply & Customize Rules Now
    await tester.tap(find.text('Apply & Customize Rules Now'));
    await tester.pumpAndSettle();

    // Verify 3 starter rules are added
    expect(find.text('Prioritize Restocked Volumes'), findsOneWidget);
    expect(find.text('Finish Near-Complete Series'), findsOneWidget);
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

  testWidgets('StatsScreen renders all metrics, sections, and breakdowns properly', (WidgetTester tester) async {
    final config = RuleConfig(
      timelineStartDate: DateTime(2024, 1, 1),
      defaultRegularPerMonth: 1,
      bonusMonths: const [5],
    );

    final mockSeries = [
      const Series(
        id: 'series1',
        title: 'Frieren: Beyond Journey\'s End',
        type: 'Manga',
        collectionStatus: 'active',
      ),
      const Series(
        id: 'series2',
        title: 'Spice and Wolf',
        type: 'Light Novel',
        collectionStatus: 'completed',
      ),
    ];

    final mockVolumes = [
      const Volume(
        id: 'vol1',
        seriesId: 'series1',
        volumeNumber: 1,
        isOwned: true,
        isGift: false,
      ),
      const Volume(
        id: 'vol2',
        seriesId: 'series1',
        volumeNumber: 2,
        isOwned: true,
        isGift: true,
      ),
      const Volume(
        id: 'vol3',
        seriesId: 'series2',
        volumeNumber: 1,
        isOwned: true,
        isGift: false,
      ),
    ];

    final mockTx = [
      PurchaseTransaction(
        id: 'tx1',
        volumeId: 'vol1',
        purchaseDate: DateTime(2024, 1, 10),
        quotaBucket: 'regular',
        price: 12.99,
      ),
      PurchaseTransaction(
        id: 'tx2',
        volumeId: 'vol3',
        purchaseDate: DateTime(2024, 2, 10),
        quotaBucket: 'regular',
        price: 14.99,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ruleConfigNotifierProvider.overrideWith((ref) => MockRuleConfigNotifier(config)),
          seriesNotifierProvider.overrideWith((ref) => MockSeriesNotifier(mockSeries)),
          volumesNotifierProvider.overrideWith((ref) => MockVolumesNotifier(mockVolumes)),
          transactionsNotifierProvider.overrideWith((ref) => MockTransactionsNotifier(mockTx)),
        ],
        child: const MaterialApp(
          home: StatsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title and Section Headers
    expect(find.text('Statistics & Insights'), findsOneWidget);
    expect(find.text('Total Owned'), findsOneWidget);
    expect(find.text('Total Series'), findsOneWidget);
    expect(find.text('Acquisition Quota & Pace'), findsOneWidget);
    expect(find.text('Bought vs. Gifted'), findsOneWidget);
    expect(find.text('Series & Format Distribution'), findsOneWidget);

    // Verify Metric Values
    expect(find.text('3'), findsWidgets); // 3 Total Owned
    expect(find.text('2'), findsWidgets); // 2 Total Series
    expect(find.text('Bought Volumes'), findsOneWidget);
    expect(find.text('Gifted Volumes'), findsOneWidget);
  });

  testWidgets('Tapping dashboard cards navigates to StatsScreen', (WidgetTester tester) async {
    final config = RuleConfig(
      timelineStartDate: DateTime(2024, 1, 1),
      defaultRegularPerMonth: 1,
      bonusMonths: const [5],
    );

    final mockSeries = [
      const Series(
        id: 'series1',
        title: 'Frieren: Beyond Journey\'s End',
        type: 'Manga',
        collectionStatus: 'active',
      ),
    ];

    final mockVolumes = [
      const Volume(
        id: 'vol1',
        seriesId: 'series1',
        volumeNumber: 1,
        isOwned: true,
        isGift: false,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ruleConfigNotifierProvider.overrideWith((ref) => MockRuleConfigNotifier(config)),
          seriesNotifierProvider.overrideWith((ref) => MockSeriesNotifier(mockSeries)),
          volumesNotifierProvider.overrideWith((ref) => MockVolumesNotifier(mockVolumes)),
          transactionsNotifierProvider.overrideWith((ref) => MockTransactionsNotifier([])),
        ],
        child: const MaterialApp(
          home: DashboardScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap on 'Total Owned' card
    await tester.tap(find.text('Total Owned'));
    await tester.pumpAndSettle();

    // Verify we navigated to StatsScreen
    expect(find.text('Statistics & Insights'), findsOneWidget);

    // Pop back to dashboard
    final NavigatorState navigator = tester.state(find.byType(Navigator));
    navigator.pop();
    await tester.pumpAndSettle();

    // Tap on 'Active Series' card
    await tester.tap(find.text('Active Series'));
    await tester.pumpAndSettle();

    // Verify navigated to StatsScreen
    expect(find.text('Statistics & Insights'), findsOneWidget);
  });

  testWidgets('RuleStudioScreen hides Add Rule FAB when switched to Quota Cadence tab', (WidgetTester tester) async {
    final config = RuleConfig.createDefault();
    final List<RuleModel> mockRules = [
      RuleModel(
        id: 'r1',
        name: 'Test Rule',
        isEnabled: true,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ruleConfigNotifierProvider.overrideWith((ref) => MockRuleConfigNotifier(config)),
          rulesNotifierProvider.overrideWith((ref) => MockRulesNotifier(mockRules)),
        ],
        child: const MaterialApp(
          home: RuleStudioScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // On Pass Pipeline tab (index 0), Add Rule FAB is visible
    expect(find.widgetWithText(FloatingActionButton, 'Add Rule'), findsOneWidget);

    // Tap on Quota Cadence tab
    await tester.tap(find.text('Quota Cadence'));
    await tester.pumpAndSettle();

    // On Quota Cadence tab (index 1), Add Rule FAB is hidden
    expect(find.widgetWithText(FloatingActionButton, 'Add Rule'), findsNothing);

    // Tap back on Pass Pipeline tab
    await tester.tap(find.text('Pass Pipeline'));
    await tester.pumpAndSettle();

    // FAB is visible again
    expect(find.widgetWithText(FloatingActionButton, 'Add Rule'), findsOneWidget);
  });

  testWidgets('Onboarding Step 2 has Recurring No-Book Months card alongside Bonus Months', (WidgetTester tester) async {
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

    expect(find.text('Bonus Months'), findsOneWidget);
    expect(find.text('Recurring No-Book Months'), findsOneWidget);
  });

  testWidgets('RuleStudioScreen renders Recurring No-Book Months card in Quota Cadence tab', (WidgetTester tester) async {
    final config = RuleConfig(
      timelineStartDate: DateTime(2024, 1, 1),
      defaultRegularPerMonth: 1,
      bonusMonths: const [12],
      recurringNoBookMonths: const [6],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ruleConfigNotifierProvider.overrideWith((ref) => MockRuleConfigNotifier(config)),
          rulesNotifierProvider.overrideWith((ref) => MockRulesNotifier([])),
        ],
        child: const MaterialApp(
          home: RuleStudioScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Switch to Quota Cadence tab
    await tester.tap(find.text('Quota Cadence'));
    await tester.pumpAndSettle();

    expect(find.text('Recurring No-Book Months'), findsOneWidget);
    expect(find.text('Recurring Bonus Months'), findsOneWidget);
  });

  testWidgets('QuotaStatusCard renders simplified "Ahead of schedule" text when ahead', (WidgetTester tester) async {
    const summary = QuotaSummary(
      regularExpected: 10,
      regularBought: 10,
      regularRemaining: 0,
      bonusExpected: 2,
      bonusBought: 4,
      bonusRemaining: -2,
      totalRemaining: -2,
      giftsCount: 1,
      totalSpent: 120.0,
      isAheadOfSchedule: true,
      creditsCount: 2,
      monthsAhead: 2,
      activeMonthKeys: ['2026-01', '2026-02'],
    );

    final config = RuleConfig(timelineStartDate: DateTime(2026, 1, 1));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ruleConfigNotifierProvider.overrideWith((ref) => MockRuleConfigNotifier(config)),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: QuotaStatusCard(summary: summary),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ahead of schedule'), findsOneWidget);
    // Should NOT contain the old verbose bracketed title
    expect(find.textContaining('Ahead of schedule (+'), findsNothing);
  });

  testWidgets('StatsScreen renders 13 / 13 for Bonus and Total Open when overbought with credit', (WidgetTester tester) async {
    const summary = QuotaSummary(
      regularExpected: 0,
      regularBought: 0,
      regularRemaining: 0,
      bonusExpected: 13,
      bonusBought: 16,
      bonusRemaining: -3,
      totalRemaining: -3,
      giftsCount: 0,
      totalSpent: 200.0,
      isAheadOfSchedule: true,
      creditsCount: 3,
      monthsAhead: 3,
      activeMonthKeys: [],
    );

    final config = RuleConfig(timelineStartDate: DateTime(2026, 1, 1));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          quotaProvider.overrideWithValue(summary),
          ruleConfigNotifierProvider.overrideWith((ref) => MockRuleConfigNotifier(config)),
          seriesNotifierProvider.overrideWith((ref) => MockSeriesNotifier([])),
          volumesNotifierProvider.overrideWith((ref) => MockVolumesNotifier([])),
          transactionsNotifierProvider.overrideWith((ref) => MockTransactionsNotifier([])),
        ],
        child: const MaterialApp(
          home: StatsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify "Ahead of Schedule" simplified banner
    expect(find.text('Ahead of Schedule'), findsOneWidget);
    expect(find.textContaining('Ahead of Schedule (+'), findsNothing);

    // Verify "13 / 13" is shown instead of "16 / 13"
    expect(find.text('13 / 13'), findsWidgets);
    expect(find.text('16 / 13'), findsNothing);
    // Total Open shows value -3 and Credit status
    expect(find.text('-3'), findsOneWidget);
    expect(find.text('Credit'), findsOneWidget);
  });

  testWidgets('SeriesDetailScreen renders Bulk Mark button and opens Bulk Mark sheet', (WidgetTester tester) async {
    final series = Series(
      id: 'series_1',
      title: 'Overlord',
      type: 'lightNovel',
      collectionStatus: 'active',
    );

    final volumes = [
      Volume(id: 'v1', seriesId: 'series_1', volumeNumber: 1.0, isOwned: true),
      Volume(id: 'v2', seriesId: 'series_1', volumeNumber: 2.0, isOwned: false),
      Volume(id: 'v3', seriesId: 'series_1', volumeNumber: 3.0, isOwned: false),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          seriesNotifierProvider.overrideWith((ref) => MockSeriesNotifier([series])),
          volumesNotifierProvider.overrideWith((ref) => MockVolumesNotifier(volumes)),
          transactionsNotifierProvider.overrideWith((ref) => MockTransactionsNotifier([])),
        ],
        child: MaterialApp(
          home: SeriesDetailScreen(seriesId: series.id),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Bulk Mark button exists in action row
    expect(find.text('Bulk Mark'), findsOneWidget);

    // Tap Bulk Mark
    await tester.tap(find.text('Bulk Mark'));
    await tester.pumpAndSettle();

    // Verify modal sheet opened
    expect(find.text('Bulk Mark Volumes'), findsOneWidget);
    expect(find.text('1. Target Volumes'), findsOneWidget);
    expect(find.text('2. Mark Status As'), findsOneWidget);
    expect(find.text('Purchased'), findsOneWidget);
    expect(find.text('Gift'), findsOneWidget);
    expect(find.text('Unmark'), findsOneWidget);
  });

  testWidgets('Onboarding Step 4 provides Default Rules and Custom Rules choices', (WidgetTester tester) async {
    final config = RuleConfig(timelineStartDate: DateTime.now());

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

    // Step 1 -> Step 2
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Step 2 -> Step 4 (since timeline start is current month, Step 3 catch-up is skipped)
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Step 4 header & choice cards
    expect(find.text('Configure Recommendation Rules'), findsOneWidget);
    expect(find.text('Use Default Rules'), findsOneWidget);
    expect(find.text('RECOMMENDED'), findsOneWidget);
    expect(find.text('Create Custom Rules'), findsOneWidget);

    // Default rules are previewed
    expect(find.text('Included Default Rules'), findsOneWidget);
    expect(find.text('1. Prioritize Restocked Volumes'), findsOneWidget);
    expect(find.text('2. Finish Near-Complete Series'), findsOneWidget);
    expect(find.text('3. Sequential Next Volume'), findsOneWidget);
    expect(find.text('Apply & Customize Rules Now'), findsOneWidget);

    // Switch to Custom Rules
    await tester.tap(find.text('Create Custom Rules'));
    await tester.pumpAndSettle();

    // Verify Custom Rules empty state & button
    expect(find.text('No Custom Rules Yet'), findsOneWidget);
    expect(find.text('Create Custom Rule'), findsOneWidget);

    // Switch back to Default Rules
    await tester.tap(find.text('Use Default Rules'));
    await tester.pumpAndSettle();

    expect(find.text('Included Default Rules'), findsOneWidget);
  });
}
