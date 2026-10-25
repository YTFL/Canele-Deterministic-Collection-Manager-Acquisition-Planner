import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:canele/features/games/models/game_item.dart';
import 'package:canele/features/games/models/game_rule.dart';
import 'package:canele/features/games/models/game_series.dart';
import 'package:canele/features/games/ui/sheets/add_game_sheet.dart';
import 'package:canele/features/games/ui/sheets/edit_game_item_sheet.dart';
import 'package:canele/features/games/ui/sheets/edit_game_rule_sheet.dart';
import 'package:canele/features/games/ui/sheets/log_game_acquisition_sheet.dart';
import 'package:canele/features/games/ui/widgets/game_card.dart';
import 'package:canele/features/games/ui/widgets/game_rule_card.dart';

void main() {
  group('Game UI Widget Tests', () {
    testWidgets('AddGameSheet renders with Standalone / Franchise toggles and full Acquisition Statuses', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AddGameSheet(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Header and Structure toggle
      expect(find.text('Add Game Franchise'), findsWidgets);
      expect(find.text('Game Franchise'), findsOneWidget);
      expect(find.text('Standalone Game'), findsOneWidget);

      // Verify Acquisition Status is present
      expect(find.text('Acquisition Status'), findsOneWidget);

      // Tap Standalone Game
      await tester.tap(find.text('Standalone Game'));
      await tester.pumpAndSettle();

      expect(find.text('Add Standalone Game'), findsWidgets);
      expect(find.text('Game Title'), findsOneWidget);
      expect(find.text('Already Owned / Acquired?'), findsOneWidget);
    });

    testWidgets('GameRuleCard renders with zero mentions of volumes or restock', (tester) async {
      final rule = GameRule(
        id: 'rule_1',
        name: 'Finish Near-Complete Franchises',
        scope: GameRuleScope.franchisesOnly,
        trigger: GameRuleTrigger.fewestRemaining,
        thresholdValue: 2,
        isPriorityTargetOnly: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameRuleCard(
              rule: rule,
              displayIndex: 0,
              onTap: () {},
              onToggleEnabled: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('#1'), findsOneWidget);
      expect(find.text('Finish Near-Complete Franchises'), findsOneWidget);

      // Verify Chips: MUST say "Games Left" and "Watchlist Priority Target", NOT "Vols" or "Restock"
      expect(find.text('<= 2 Games Left'), findsOneWidget);
      expect(find.text('Watchlist Priority Target'), findsOneWidget);
      expect(find.textContaining('vol', findRichText: true), findsNothing);
      expect(find.textContaining('restock', findRichText: true), findsNothing);
    });

    testWidgets('EditGameRuleSheet renders game scope and triggers with zero restock or volume wording', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: EditGameRuleSheet(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Create Game Rule'), findsOneWidget);
      expect(find.text('Game Scope'), findsOneWidget);
      expect(find.text('Watchlist Priority Target'), findsOneWidget);
      expect(find.text('Acquisition Trigger'), findsOneWidget);
      expect(find.textContaining('Restock Priority', findRichText: true), findsNothing);
    });

    testWidgets('GameCard renders parent UI matching books (title, badge, quick add, popup menu, progress)', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final series = GameSeries(
        id: 's_ds',
        title: 'Dark Souls',
        isStandalone: false,
        collectionStatus: 'active',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: GameCard(series: series),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Dark Souls'), findsOneWidget);
      expect(find.text('GAME SERIES'), findsOneWidget);
      expect(find.byIcon(Icons.add_circle_outline_rounded), findsOneWidget);
      expect(find.byIcon(Icons.more_vert_rounded), findsOneWidget);
      expect(find.text('0/0 Owned'), findsOneWidget);
    });

    testWidgets('EditGameItemSheet renders with Gift toggle and delete action', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final series = GameSeries(
        id: 's_ds',
        title: 'Dark Souls',
        isStandalone: false,
      );
      final item = GameItem(
        id: 'i_1',
        seriesId: 's_ds',
        title: 'Dark Souls 1',
        isOwned: true,
        isGift: true,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: EditGameItemSheet(item: item, series: series),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Edit Game'), findsOneWidget);
      expect(find.text('Already Acquired / Owned'), findsOneWidget);
      expect(find.text('Acquired as Gift / Free Claim'), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
    });

    testWidgets('LogGameAcquisitionSheet renders with Purchased vs Gift toggle and price field', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final series = GameSeries(
        id: 's_ds',
        title: 'Dark Souls',
        isStandalone: false,
      );
      final item = GameItem(
        id: 'i_1',
        seriesId: 's_ds',
        title: 'Dark Souls Remastered',
        price: 39.99,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: LogGameAcquisitionSheet(series: series, item: item),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Log Acquisition'), findsOneWidget);
      expect(find.text('Dark Souls Remastered'), findsOneWidget);
      expect(find.text('Purchased'), findsOneWidget);
      expect(find.text('Gift / Free Claim'), findsOneWidget);
      expect(find.text('Purchase Price'), findsOneWidget);
      expect(find.text('Confirm Purchase'), findsOneWidget);

      // Tap Gift / Free Claim
      await tester.tap(find.text('Gift / Free Claim'));
      await tester.pumpAndSettle();

      expect(find.text('Confirm Gift Claim'), findsOneWidget);
    });
  });
}
