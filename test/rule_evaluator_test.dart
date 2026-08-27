import 'package:flutter_test/flutter_test.dart';
import 'package:canele/models/rule_model.dart';
import 'package:canele/models/series.dart';
import 'package:canele/models/volume.dart';
import 'package:canele/services/rule_evaluator.dart';

void main() {
  group('RuleEvaluator Dynamic Pipeline & Priority Tests', () {
    final s1 = Series(id: 's1', title: '86 - Eighty-Six', type: 'lightNovel', tags: ['special_priority']);
    final s2 = Series(id: 's2', title: 'Frieren: Beyond Journey\'s End', type: 'manga', tags: ['fantasy']);
    final s3 = Series(id: 's3', title: 'Spy x Family', type: 'manga', tags: ['comedy', 'action']);
    final s4 = Series(id: 's4', title: 'Dungeon Meshi', type: 'manga', tags: ['fantasy']);
    final s5 = Series(id: 's5', title: 'The Apothecary Diaries', type: 'lightNovel', tags: ['mystery']);

    final now = DateTime(2026, 1, 1);

    // s1: has 11 volumes, vols 1..10 owned, vol 11 & 11.5 missing released (11.5 marked restocked)
    final vS1_10 = Volume(id: 'v1_10', seriesId: 's1', volumeNumber: 10.0, releaseDate: DateTime(2023, 1, 1), isOwned: true);
    final vS1_11 = Volume(id: 'v1_11', seriesId: 's1', volumeNumber: 11.0, releaseDate: DateTime(2023, 6, 1), isOwned: false);
    final vS1_11_5 = Volume(id: 'v1_11_5', seriesId: 's1', volumeNumber: 11.5, releaseDate: DateTime(2023, 12, 1), isOwned: false, isRestockedWatchlist: true);

    // s2: has 1 volume left to complete (vol 1 owned, vol 2 missing)
    final vS2_1 = Volume(id: 'v2_1', seriesId: 's2', volumeNumber: 1.0, releaseDate: DateTime(2022, 1, 1), isOwned: true);
    final vS2_2 = Volume(id: 'v2_2', seriesId: 's2', volumeNumber: 2.0, releaseDate: DateTime(2022, 6, 1), isOwned: false);

    // s3: has gap filling and action tag (vols 1 & 3 owned, vols 2 & 4 missing)
    final vS3_1 = Volume(id: 'v3_1', seriesId: 's3', volumeNumber: 1.0, releaseDate: DateTime(2021, 1, 1), isOwned: true);
    final vS3_2 = Volume(id: 'v3_2', seriesId: 's3', volumeNumber: 2.0, releaseDate: DateTime(2021, 6, 1), isOwned: false);
    final vS3_3 = Volume(id: 'v3_3', seriesId: 's3', volumeNumber: 3.0, releaseDate: DateTime(2021, 12, 1), isOwned: true);
    final vS3_4 = Volume(id: 'v3_4', seriesId: 's3', volumeNumber: 4.0, releaseDate: DateTime(2022, 6, 1), isOwned: false);

    // s4: has 2 volumes missing (vol 1 owned, vols 2 & 3 missing)
    final vS4_1 = Volume(id: 'v4_1', seriesId: 's4', volumeNumber: 1.0, releaseDate: DateTime(2020, 1, 1), isOwned: true);
    final vS4_2 = Volume(id: 'v4_2', seriesId: 's4', volumeNumber: 2.0, releaseDate: DateTime(2020, 6, 1), isOwned: false);
    final vS4_3 = Volume(id: 'v4_3', seriesId: 's4', volumeNumber: 3.0, releaseDate: DateTime(2020, 12, 1), isOwned: false);

    // s5: unowned vols 1 & 2
    final vS5_1 = Volume(id: 'v5_1', seriesId: 's5', volumeNumber: 1.0, releaseDate: DateTime(2020, 1, 1), isOwned: false);
    final vS5_2 = Volume(id: 'v5_2', seriesId: 's5', volumeNumber: 2.0, releaseDate: DateTime(2020, 6, 1), isOwned: false);

    final allVolumes = [
      vS1_10, vS1_11, vS1_11_5,
      vS2_1, vS2_2,
      vS3_1, vS3_2, vS3_3, vS3_4,
      vS4_1, vS4_2, vS4_3,
      vS5_1, vS5_2,
    ];

    test('Evaluates dynamic rules pipeline with restock priority and progress triggers', () {
      final rules = [
        RuleModel(
          id: 'r1',
          name: 'Restock Watchlist Priority',
          priorityOrder: 0,
          restockPriorityEnabled: true,
          sortBy: SortCriteria.earliestReleaseDate,
        ),
        RuleModel(
          id: 'r2',
          name: 'Rush to Complete (1 Vol Left)',
          priorityOrder: 1,
          progressTrigger: ProgressTriggerType.exactVolumesLeft,
          volumeThresholdValue: 1,
          sortBy: SortCriteria.lowestVolumeNumber,
        ),
        RuleModel(
          id: 'r3',
          name: 'Tag Priority (Action)',
          priorityOrder: 2,
          scopeType: RuleScopeType.tagBased,
          targetTags: ['action'],
          sortBy: SortCriteria.lowestVolumeNumber,
        ),
      ];

      final slots = RuleEvaluator.evaluate(
        rules: rules,
        seriesList: [s1, s2, s3, s4, s5],
        volumesList: allVolumes,
        asOfDate: now,
      );

      expect(slots.length, 4);

      // Slot 0: Should be Restocked Vol 11.5 from s1
      expect(slots[0].series.id, 's1');
      expect(slots[0].volume.volumeNumber, 11.5);
      expect(slots[0].ruleId, 'r1');

      // Slot 1: Should be s2 (1 volume left to complete)
      expect(slots[1].series.id, 's2');
      expect(slots[1].volume.volumeNumber, 2.0);
      expect(slots[1].ruleId, 'r2');

      // Slot 2: Should be s3 (Action tag)
      expect(slots[2].series.id, 's3');
      expect(slots[2].volume.volumeNumber, 2.0);
      expect(slots[2].ruleId, 'r3');

      // Slot 3: Fallback should fill with next active series with lowest volume number (s5, Vol 1.0)
      expect(slots[3].series.id, 's5');
      expect(slots[3].volume.volumeNumber, 1.0);
      expect(slots[3].ruleId, 'fallback');
    });

    test('Priority order shifts alter recommendation slots', () {
      // Rule 1: Format Manga
      // Rule 2: Format Light Novel
      final rulesA = [
        RuleModel(
          id: 'r_manga',
          name: 'Manga First',
          priorityOrder: 0,
          scopeType: RuleScopeType.formatType,
          targetFormat: 'manga',
          sortBy: SortCriteria.alphabetical,
        ),
        RuleModel(
          id: 'r_ln',
          name: 'Light Novel Second',
          priorityOrder: 1,
          scopeType: RuleScopeType.formatType,
          targetFormat: 'lightNovel',
          sortBy: SortCriteria.alphabetical,
        ),
      ];

      final slotsA = RuleEvaluator.evaluate(
        rules: rulesA,
        seriesList: [s1, s2, s3, s4, s5],
        volumesList: allVolumes,
        asOfDate: now,
      );

      // First 3 slots should be manga (Dungeon Meshi, Frieren, Spy x Family), 4th light novel
      expect(slotsA[0].series.type, 'manga');
      expect(slotsA[1].series.type, 'manga');
      expect(slotsA[2].series.type, 'manga');
      expect(slotsA[3].series.type, 'lightNovel');

      // Now reverse priorities
      final rulesB = [
        rulesA[0].copyWith(priorityOrder: 1),
        rulesA[1].copyWith(priorityOrder: 0),
      ];

      final slotsB = RuleEvaluator.evaluate(
        rules: rulesB,
        seriesList: [s1, s2, s3, s4, s5],
        volumesList: allVolumes,
        asOfDate: now,
      );

      // First 2 slots should be light novel (86 and Apothecary Diaries)
      expect(slotsB[0].series.type, 'lightNovel');
      expect(slotsB[1].series.type, 'lightNovel');
    });

    test('Enforces cross-pass 1-volume per series deduplication when total candidate series >= 4', () {
      final rules = [
        RuleModel(id: 'r1', name: 'Rule 1', priorityOrder: 0, scopeType: RuleScopeType.allSeries),
        RuleModel(id: 'r2', name: 'Rule 2', priorityOrder: 1, scopeType: RuleScopeType.allSeries),
      ];

      final slots = RuleEvaluator.evaluate(
        rules: rules,
        seriesList: [s1, s2, s3, s4, s5],
        volumesList: allVolumes,
        asOfDate: now,
      );

      // All 4 slots should belong to 4 distinct series
      final distinctSeriesIds = slots.map((s) => s.series.id).toSet();
      expect(distinctSeriesIds.length, 4);
    });

    test('Fallback resolves gracefully when total available series < 4', () {
      final singleSeries = s1;
      final singleSeriesVolumes = [vS1_10, vS1_11, vS1_11_5];

      final slots = RuleEvaluator.evaluate(
        rules: [
          RuleModel(id: 'r1', name: 'All', priorityOrder: 0),
        ],
        seriesList: [singleSeries],
        volumesList: singleSeriesVolumes,
        asOfDate: now,
      );

      // Only 2 unowned volumes exist in the entire database, should return 2 slots without crashing
      expect(slots.length, 2);
      expect(slots[0].volume.volumeNumber, 11.0);
      expect(slots[1].volume.volumeNumber, 11.5);
    });

    test('Evaluates custom user-defined format types dynamically', () {
      final sManhwa = Series(id: 'sm1', title: 'Solo Leveling', type: 'Manhwa', tags: ['action']);
      final vM1 = Volume(id: 'vm1', seriesId: 'sm1', volumeNumber: 1.0, releaseDate: DateTime(2023, 1, 1), isOwned: false);

      final slots = RuleEvaluator.evaluate(
        rules: [
          RuleModel(
            id: 'r_manhwa',
            name: 'Manhwa Rule',
            priorityOrder: 0,
            scopeType: RuleScopeType.formatType,
            targetFormat: 'manhwa',
          ),
        ],
        seriesList: [sManhwa, s1, s2, s3],
        volumesList: [vM1, vS1_11, vS2_2, vS3_2],
        asOfDate: now,
      );

      expect(slots.first.series.title, 'Solo Leveling');
      expect(slots.first.ruleName, 'Manhwa Rule');
    });

    test('Evaluates and sorts volumes with releaseDate: null as already released', () {
      final sBacklog = Series(id: 's_backlog', title: 'Classic Novel', type: 'Book');
      final v1 = Volume(id: 'vb1', seriesId: 's_backlog', volumeNumber: 1.0, releaseDate: null, isOwned: false);
      final v2 = Volume(id: 'vb2', seriesId: 's_backlog', volumeNumber: 2.0, releaseDate: null, isOwned: false);

      final slots = RuleEvaluator.evaluate(
        rules: [
          RuleModel(id: 'r_all', name: 'All Books', priorityOrder: 0, sortBy: SortCriteria.earliestReleaseDate),
        ],
        seriesList: [sBacklog],
        volumesList: [v1, v2],
        asOfDate: now,
      );

      expect(slots.length, 2);
      expect(slots[0].volume.volumeNumber, 1.0);
      expect(slots[1].volume.volumeNumber, 2.0);
    });

    test('Strictly excludes outOfStock and outOfPrint volumes from monthly acquisition targets', () {
      final sOos = Series(id: 's_oos', title: 'Rare Novel', type: 'Book');
      final vOos = Volume(id: 'voos', seriesId: 's_oos', volumeNumber: 1.0, isOwned: false, availability: 'outOfStock');
      final vOop = Volume(id: 'voop', seriesId: 's_oos', volumeNumber: 2.0, isOwned: false, availability: 'outOfPrint');
      final vAvail = Volume(id: 'vavail', seriesId: 's_oos', volumeNumber: 3.0, isOwned: false, availability: 'available');

      final slots = RuleEvaluator.evaluate(
        rules: [
          RuleModel(id: 'r_all', name: 'All Books', priorityOrder: 0),
        ],
        seriesList: [sOos],
        volumesList: [vOos, vOop, vAvail],
        asOfDate: now,
      );

      // Only Vol. 3 (available) should be recommended; Vol 1 (OOS) and Vol 2 (OOP) must be excluded
      expect(slots.length, 1);
      expect(slots.first.volume.volumeNumber, 3.0);
      expect(slots.first.volume.id, 'vavail');
    });

    test('Strictly excludes announced / unreleased volumes with future release dates', () {
      final sFuture = Series(id: 's_fut', title: 'Upcoming Series', type: 'Manga');
      final vFuture = Volume(
        id: 'vfut',
        seriesId: 's_fut',
        volumeNumber: 1.0,
        releaseDate: now.add(const Duration(days: 60)),
        availability: 'announced',
        isRestockedWatchlist: true,
        isOwned: false,
      );
      final vReleased = Volume(
        id: 'vrel',
        seriesId: 's_fut',
        volumeNumber: 2.0,
        releaseDate: now.subtract(const Duration(days: 30)),
        availability: 'available',
        isOwned: false,
      );
      final slots = RuleEvaluator.evaluate(
        rules: [
          RuleModel(id: 'r_all', name: 'All Books', priorityOrder: 0),
        ],
        seriesList: [sFuture],
        volumesList: [vFuture, vReleased],
        asOfDate: now,
      );

      expect(slots.length, 1);
      expect(slots.first.volume.id, 'vrel');
    });

    test('Strictly excludes wishlist, completed, and dropped series from recommendation slots', () {
      final sWishlist = Series(id: 's_wish', title: 'Wishlist Series', type: 'Manga', collectionStatus: 'wishlist');
      final sCompleted = Series(id: 's_comp', title: 'Completed Series', type: 'Manga', collectionStatus: 'completed');
      final sDropped = Series(id: 's_drop', title: 'Dropped Series', type: 'Manga', collectionStatus: 'dropped');
      final sActive = Series(id: 's_act', title: 'Active Series', type: 'Manga', collectionStatus: 'active');

      final vWish = Volume(id: 'vw1', seriesId: 's_wish', volumeNumber: 1.0, isOwned: false, availability: 'available');
      final vComp = Volume(id: 'vc1', seriesId: 's_comp', volumeNumber: 1.0, isOwned: false, availability: 'available');
      final vDrop = Volume(id: 'vd1', seriesId: 's_drop', volumeNumber: 1.0, isOwned: false, availability: 'available');
      final vAct = Volume(id: 'va1', seriesId: 's_act', volumeNumber: 1.0, isOwned: false, availability: 'available');

      final slots = RuleEvaluator.evaluate(
        rules: [
          RuleModel(id: 'r_all', name: 'All Books', priorityOrder: 0),
        ],
        seriesList: [sWishlist, sCompleted, sDropped, sActive],
        volumesList: [vWish, vComp, vDrop, vAct],
        asOfDate: now,
      );

      // Only the active series volume should be recommended
      expect(slots.length, 1);
      expect(slots.first.series.id, 's_act');
      expect(slots.first.volume.id, 'va1');
    });
  });
}
