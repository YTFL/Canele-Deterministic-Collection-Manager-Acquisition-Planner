import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:canele/models/series.dart';
import 'package:canele/models/volume.dart';
import 'package:canele/models/purchase_transaction.dart';
import 'package:canele/providers/series_provider.dart';
import 'package:canele/ui/helpers/series_status_prompt_helper.dart';
import 'package:canele/ui/screens/series_detail_screen.dart';
import 'package:canele/ui/widgets/log_transaction_sheet.dart';

class TestSeriesNotifier extends StateNotifier<List<Series>> implements SeriesNotifier {
  TestSeriesNotifier(super.state);

  @override
  void load() {}

  @override
  Future<void> saveSeries(Series series) async {
    state = state.map((s) => s.id == series.id ? series : s).toList();
    if (!state.any((s) => s.id == series.id)) {
      state = [...state, series];
    }
  }

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
  }) async {
    final s = Series(
      id: 's_new',
      title: title,
      type: type,
      collectionStatus: collectionStatus,
      releaseStatus: releaseStatus,
    );
    await saveSeries(s);
    return s;
  }

  @override
  Future<void> deleteSeries(String id) async {
    state = state.where((s) => s.id != id).toList();
  }

  @override
  Future<void> markSeriesAsCompleted(String seriesId) async {
    state = state.map((s) => s.id == seriesId ? s.copyWith(collectionStatus: 'completed', releaseStatus: 'completed') : s).toList();
  }
}

class TestVolumesNotifier extends StateNotifier<List<Volume>> implements VolumesNotifier {
  TestVolumesNotifier(super.state);

  @override
  void load() {}

  @override
  Future<void> saveVolume(Volume volume) async {
    state = state.map((v) => v.id == volume.id ? volume : v).toList();
    if (!state.any((v) => v.id == volume.id)) {
      state = [...state, volume];
    }
  }

  @override
  Future<void> saveBatch(List<Volume> volumes) async {
    for (final v in volumes) {
      await saveVolume(v);
    }
  }

  @override
  Future<void> deleteVolume(String id) async {
    state = state.where((v) => v.id != id).toList();
  }

  @override
  Future<void> toggleOwned(Volume volume, {bool? asGift}) async {
    final updated = volume.copyWith(
      isOwned: !volume.isOwned,
      isGift: asGift ?? volume.isGift,
    );
    await saveVolume(updated);
  }

  @override
  Future<void> bulkUpdateOwnership({
    required List<String> volumeIds,
    required bool isOwned,
    bool isGift = false,
  }) async {
    final targetSet = volumeIds.toSet();
    state = state.map((v) {
      if (targetSet.contains(v.id)) {
        return v.copyWith(isOwned: isOwned, isGift: isGift);
      }
      return v;
    }).toList();
  }
}

class TestTransactionsNotifier extends StateNotifier<List<PurchaseTransaction>> implements TransactionsNotifier {
  TestTransactionsNotifier(super.state);

  @override
  void load() {}

  @override
  Future<void> saveTransaction(PurchaseTransaction transaction) async {
    state = [...state, transaction];
  }

  @override
  Future<void> deleteTransaction(String id) async {
    state = state.where((t) => t.id != id).toList();
  }
}

void main() {
  group('SeriesStatusPromptHelper Tests', () {
    testWidgets('Prompts and moves Wishlist series to Active when book is obtained', (tester) async {
      final initialSeries = [
        const Series(
          id: 's1',
          title: 'Frieren: Beyond Journey\'s End',
          type: 'manga',
          collectionStatus: 'wishlist',
          releaseStatus: 'ongoing',
        ),
      ];
      final initialVolumes = [
        const Volume(
          id: 'v1',
          seriesId: 's1',
          volumeNumber: 1,
          isOwned: false,
        ),
      ];

      late WidgetRef capturedRef;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            seriesNotifierProvider.overrideWith((ref) => TestSeriesNotifier(initialSeries)),
            volumesNotifierProvider.overrideWith((ref) => TestVolumesNotifier(initialVolumes)),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  capturedRef = ref;
                  return ElevatedButton(
                    onPressed: () async {
                      // Mark volume as owned
                      await ref.read(volumesNotifierProvider.notifier).saveVolume(
                            initialVolumes.first.copyWith(isOwned: true),
                          );
                      await SeriesStatusPromptHelper.checkAndPrompt(context, seriesId: 's1', ref: ref);
                    },
                    child: const Text('Acquire Book'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Trigger acquire book
      await tester.tap(find.text('Acquire Book'));
      await tester.pumpAndSettle();

      // Verify dialog is shown
      expect(find.text('Move to Active?'), findsOneWidget);
      expect(find.textContaining('You marked a book in "Frieren: Beyond Journey\'s End" as obtained'), findsOneWidget);
      expect(find.text('Keep in Wishlist'), findsOneWidget);
      expect(find.text('Move to Active'), findsOneWidget);

      // Tap Move to Active
      await tester.tap(find.text('Move to Active'));
      await tester.pumpAndSettle();

      // Verify series status updated
      final updatedSeries = capturedRef.read(seriesNotifierProvider).firstWhere((s) => s.id == 's1');
      expect(updatedSeries.collectionStatus, 'active');
      expect(find.text('Moved "Frieren: Beyond Journey\'s End" to Active collection!'), findsOneWidget);
    });

    testWidgets('Declining Wishlist to Active prompt keeps series in Wishlist', (tester) async {
      final initialSeries = [
        const Series(
          id: 's1',
          title: 'Witch Hat Atelier',
          type: 'manga',
          collectionStatus: 'wishlist',
          releaseStatus: 'ongoing',
        ),
      ];
      final initialVolumes = [
        const Volume(
          id: 'v1',
          seriesId: 's1',
          volumeNumber: 1,
          isOwned: false,
        ),
      ];

      late WidgetRef capturedRef;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            seriesNotifierProvider.overrideWith((ref) => TestSeriesNotifier(initialSeries)),
            volumesNotifierProvider.overrideWith((ref) => TestVolumesNotifier(initialVolumes)),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  capturedRef = ref;
                  return ElevatedButton(
                    onPressed: () async {
                      await ref.read(volumesNotifierProvider.notifier).saveVolume(
                            initialVolumes.first.copyWith(isOwned: true, isGift: true),
                          );
                      await SeriesStatusPromptHelper.checkAndPrompt(context, seriesId: 's1', ref: ref);
                    },
                    child: const Text('Receive Gift'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Receive Gift'));
      await tester.pumpAndSettle();

      expect(find.text('Move to Active?'), findsOneWidget);

      // Tap Keep in Wishlist
      await tester.tap(find.text('Keep in Wishlist'));
      await tester.pumpAndSettle();

      // Verify series remains wishlist
      final updatedSeries = capturedRef.read(seriesNotifierProvider).firstWhere((s) => s.id == 's1');
      expect(updatedSeries.collectionStatus, 'wishlist');
    });

    testWidgets('Prompts and moves Active completed-release series to Completed when all books obtained', (tester) async {
      final initialSeries = [
        const Series(
          id: 's2',
          title: 'Fullmetal Alchemist',
          type: 'manga',
          collectionStatus: 'active',
          releaseStatus: 'completed',
        ),
      ];
      final initialVolumes = [
        const Volume(id: 'v1', seriesId: 's2', volumeNumber: 1, isOwned: true),
        const Volume(id: 'v2', seriesId: 's2', volumeNumber: 2, isOwned: false),
      ];

      late WidgetRef capturedRef;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            seriesNotifierProvider.overrideWith((ref) => TestSeriesNotifier(initialSeries)),
            volumesNotifierProvider.overrideWith((ref) => TestVolumesNotifier(initialVolumes)),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  capturedRef = ref;
                  return ElevatedButton(
                    onPressed: () async {
                      await ref.read(volumesNotifierProvider.notifier).saveVolume(
                            initialVolumes[1].copyWith(isOwned: true),
                          );
                      await SeriesStatusPromptHelper.checkAndPrompt(context, seriesId: 's2', ref: ref);
                    },
                    child: const Text('Obtain Final Book'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Obtain Final Book'));
      await tester.pumpAndSettle();

      // Verify Move to Completed prompt is shown
      expect(find.text('Move to Completed?'), findsOneWidget);
      expect(find.textContaining('You have obtained all releases for "Fullmetal Alchemist"'), findsOneWidget);
      expect(find.text('Keep Active'), findsOneWidget);
      expect(find.text('Move to Completed'), findsOneWidget);

      // Confirm
      await tester.tap(find.text('Move to Completed'));
      await tester.pumpAndSettle();

      final updated = capturedRef.read(seriesNotifierProvider).firstWhere((s) => s.id == 's2');
      expect(updated.collectionStatus, 'completed');
      expect(find.text('Moved "Fullmetal Alchemist" to Completed!'), findsOneWidget);
    });

    testWidgets('Declining Active to Completed prompt keeps series in Active', (tester) async {
      final initialSeries = [
        const Series(
          id: 's2',
          title: 'Monster',
          type: 'manga',
          collectionStatus: 'active',
          releaseStatus: 'completed',
        ),
      ];
      final initialVolumes = [
        const Volume(id: 'v1', seriesId: 's2', volumeNumber: 1, isOwned: true),
      ];

      late WidgetRef capturedRef;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            seriesNotifierProvider.overrideWith((ref) => TestSeriesNotifier(initialSeries)),
            volumesNotifierProvider.overrideWith((ref) => TestVolumesNotifier(initialVolumes)),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  capturedRef = ref;
                  return ElevatedButton(
                    onPressed: () async {
                      await SeriesStatusPromptHelper.checkAndPrompt(context, seriesId: 's2', ref: ref);
                    },
                    child: const Text('Check Status'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Check Status'));
      await tester.pumpAndSettle();

      expect(find.text('Move to Completed?'), findsOneWidget);
      await tester.tap(find.text('Keep Active'));
      await tester.pumpAndSettle();

      final updated = capturedRef.read(seriesNotifierProvider).firstWhere((s) => s.id == 's2');
      expect(updated.collectionStatus, 'active');
    });

    testWidgets('Edit Series Dialog prompts Move to Completed when changing releaseStatus to completed', (tester) async {
      final initialSeries = [
        const Series(
          id: 's3',
          title: 'Chainsaw Man Part 1',
          type: 'manga',
          collectionStatus: 'active',
          releaseStatus: 'ongoing',
        ),
      ];
      final initialVolumes = [
        const Volume(id: 'v1', seriesId: 's3', volumeNumber: 1, isOwned: true),
        const Volume(id: 'v2', seriesId: 's3', volumeNumber: 2, isOwned: true),
      ];

      late WidgetRef capturedRef;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            seriesNotifierProvider.overrideWith((ref) => TestSeriesNotifier(initialSeries)),
            volumesNotifierProvider.overrideWith((ref) => TestVolumesNotifier(initialVolumes)),
            transactionsNotifierProvider.overrideWith((ref) => TestTransactionsNotifier([])),
          ],
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) {
                capturedRef = ref;
                return const SeriesDetailScreen(seriesId: 's3');
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Edit button
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      // Scroll Release Status dropdown into view
      final releaseStatusDropdown = find.byWidgetPredicate(
        (widget) => widget is DropdownButtonFormField<String> && widget.initialValue == 'ongoing',
      );
      await tester.ensureVisible(releaseStatusDropdown);
      await tester.pumpAndSettle();

      await tester.tap(releaseStatusDropdown);
      await tester.pumpAndSettle();

      // Tap 'Completed' menu item in the opened popup
      await tester.tap(find.text('Completed').last);
      await tester.pumpAndSettle();

      // Tap Save in Edit dialog
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Move to Completed prompt should appear!
      expect(find.text('Move to Completed?'), findsOneWidget);

      await tester.tap(find.text('Move to Completed'));
      await tester.pumpAndSettle();

      final updated = capturedRef.read(seriesNotifierProvider).firstWhere((s) => s.id == 's3');
      expect(updated.collectionStatus, 'completed');
      expect(updated.releaseStatus, 'completed');
    });

    testWidgets('LogTransactionSheet triggers Move to Active prompt when recording acquisition for Wishlist series', (tester) async {
      final initialSeries = [
        const Series(
          id: 's_wish',
          title: 'Vinland Saga',
          type: 'manga',
          collectionStatus: 'wishlist',
          releaseStatus: 'ongoing',
        ),
      ];
      final initialVolumes = [
        const Volume(id: 'v_wish_1', seriesId: 's_wish', volumeNumber: 1, isOwned: false),
      ];

      late WidgetRef capturedRef;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            seriesNotifierProvider.overrideWith((ref) => TestSeriesNotifier(initialSeries)),
            volumesNotifierProvider.overrideWith((ref) => TestVolumesNotifier(initialVolumes)),
            transactionsNotifierProvider.overrideWith((ref) => TestTransactionsNotifier([])),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  capturedRef = ref;
                  return ElevatedButton(
                    onPressed: () {
                      LogTransactionSheet.show(
                        context,
                        series: initialSeries.first,
                        volume: initialVolumes.first,
                      );
                    },
                    child: const Text('Open Sheet'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open sheet
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Tap Record Acquisition
      await tester.tap(find.text('Record Acquisition'));
      await tester.pumpAndSettle();

      // Move to Active prompt should be displayed
      expect(find.text('Move to Active?'), findsOneWidget);

      await tester.tap(find.text('Move to Active'));
      await tester.pumpAndSettle();

      final updated = capturedRef.read(seriesNotifierProvider).firstWhere((s) => s.id == 's_wish');
      expect(updated.collectionStatus, 'active');
    });

    testWidgets('Chained transition prompts Wishlist -> Active then Active -> Completed for completed release single volume', (tester) async {
      final initialSeries = [
        const Series(
          id: 's_chained',
          title: 'Goodbye, Eri',
          type: 'manga',
          collectionStatus: 'wishlist',
          releaseStatus: 'completed',
        ),
      ];
      final initialVolumes = [
        const Volume(id: 'v_single', seriesId: 's_chained', volumeNumber: 1, isOwned: false),
      ];

      late WidgetRef capturedRef;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            seriesNotifierProvider.overrideWith((ref) => TestSeriesNotifier(initialSeries)),
            volumesNotifierProvider.overrideWith((ref) => TestVolumesNotifier(initialVolumes)),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  capturedRef = ref;
                  return ElevatedButton(
                    onPressed: () async {
                      await ref.read(volumesNotifierProvider.notifier).saveVolume(
                            initialVolumes.first.copyWith(isOwned: true),
                          );
                      await SeriesStatusPromptHelper.checkAndPrompt(context, seriesId: 's_chained', ref: ref);
                    },
                    child: const Text('Acquire Single Volume'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Acquire Single Volume'));
      await tester.pumpAndSettle();

      // First prompt: Move to Active?
      expect(find.text('Move to Active?'), findsOneWidget);
      await tester.tap(find.text('Move to Active'));
      await tester.pumpAndSettle();

      // Second prompt: Move to Completed?
      expect(find.text('Move to Completed?'), findsOneWidget);
      await tester.tap(find.text('Move to Completed'));
      await tester.pumpAndSettle();

      final updated = capturedRef.read(seriesNotifierProvider).firstWhere((s) => s.id == 's_chained');
      expect(updated.collectionStatus, 'completed');
    });

    testWidgets('Edit Volume dialog in SeriesDetailScreen triggers Move to Completed when marking final volume as owned', (tester) async {
      final initialSeries = [
        const Series(
          id: 's_detail_vol',
          title: 'Pluto',
          type: 'manga',
          collectionStatus: 'active',
          releaseStatus: 'completed',
        ),
      ];
      final initialVolumes = [
        const Volume(id: 'v1', seriesId: 's_detail_vol', volumeNumber: 1, isOwned: true),
        const Volume(id: 'v2', seriesId: 's_detail_vol', volumeNumber: 2, isOwned: false),
      ];

      late WidgetRef capturedRef;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            seriesNotifierProvider.overrideWith((ref) => TestSeriesNotifier(initialSeries)),
            volumesNotifierProvider.overrideWith((ref) => TestVolumesNotifier(initialVolumes)),
            transactionsNotifierProvider.overrideWith((ref) => TestTransactionsNotifier([])),
          ],
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) {
                capturedRef = ref;
                return const SeriesDetailScreen(seriesId: 's_detail_vol');
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap more_vert icon on the second volume tile to open menu
      final moreVertIcons = find.byIcon(Icons.more_vert_rounded);
      await tester.tap(moreVertIcons.last);
      await tester.pumpAndSettle();

      // Tap Edit Volume
      await tester.tap(find.text('Edit Volume'));
      await tester.pumpAndSettle();

      // Switch Owned to true
      final ownedSwitch = find.widgetWithText(SwitchListTile, 'Owned');
      await tester.tap(ownedSwitch);
      await tester.pumpAndSettle();

      // Tap Save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Prompt should appear
      expect(find.text('Move to Completed?'), findsOneWidget);

      await tester.tap(find.text('Move to Completed'));
      await tester.pumpAndSettle();

      final updated = capturedRef.read(seriesNotifierProvider).firstWhere((s) => s.id == 's_detail_vol');
      expect(updated.collectionStatus, 'completed');
    });
  });
}
