import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:canele/core/database/hive_boxes.dart';
import 'package:canele/models/profile.dart';
import 'package:canele/models/rule_model.dart';
import 'package:canele/ui/widgets/add_workspace_dialog.dart';
import 'package:canele/ui/widgets/workspace_switcher_app_bar_title.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('canele_ui_test');
    Hive.init(tempDir.path);

    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(RuleScopeTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(ProgressTriggerTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(12)) {
      Hive.registerAdapter(SortCriteriaAdapter());
    }
    if (!Hive.isAdapterRegistered(13)) {
      Hive.registerAdapter(RuleModelAdapter());
    }

    await HiveBoxes.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    HiveBoxes.resetBoxCache();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  Widget buildTestApp(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            title: child,
          ),
          body: const Center(child: Text('Workspace Test')),
        ),
      ),
    );
  }

  testWidgets('WorkspaceSwitcherAppBarTitle displays active profile and opens modal on tap', (tester) async {
    await tester.pumpWidget(buildTestApp(const WorkspaceSwitcherAppBarTitle()));
    await tester.pumpAndSettle();

    // Verify default workspace name is shown
    expect(find.text('Books & Manga'), findsOneWidget);
    expect(find.byKey(const Key('workspace_switcher_header_button')), findsOneWidget);

    // Tap header to open WorkspaceSwitcherModal
    await tester.tap(find.byKey(const Key('workspace_switcher_header_button')));
    await tester.pumpAndSettle();

    // Verify modal header and active indicator
    expect(find.text('Workspaces'), findsOneWidget);
    expect(find.text('Books Preset'), findsOneWidget);
    expect(find.byKey(const Key('add_workspace_button')), findsOneWidget);
  });

  testWidgets('AddWorkspaceDialog completes 3-step creation flow for Games workspace', (tester) async {
    String? createdName;
    ProfileType? createdType;
    String? createdIcon;
    CustomWorkspaceSchema? createdSchema;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                key: const Key('open_dialog_btn'),
                onPressed: () {
                  AddWorkspaceDialog.show(
                    context: ctx,
                    onCreate: ({
                      required String name,
                      required ProfileType type,
                      String? icon,
                      CustomWorkspaceSchema? customSchema,
                    }) async {
                      createdName = name;
                      createdType = type;
                      createdIcon = icon;
                      createdSchema = customSchema;
                    },
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      ),
    );

    // Open Add Workspace Dialog
    await tester.tap(find.byKey(const Key('open_dialog_btn')));
    await tester.pumpAndSettle();

    expect(find.text('Create Workspace'), findsOneWidget);
    expect(find.text('Step 1 of 3'), findsOneWidget);

    // Select Video Games Preset Card
    await tester.tap(find.byKey(const Key('preset_card_games')));
    await tester.pumpAndSettle();

    // Step 2: Name Input
    expect(find.text('Step 2 of 3'), findsOneWidget);
    expect(find.text('Game Backlog'), findsOneWidget);

    // Tap Next
    await tester.tap(find.byKey(const Key('workspace_step_next_button')));
    await tester.pumpAndSettle();

    // Step 3: Icon Selection
    expect(find.text('Step 3 of 3'), findsOneWidget);
    expect(find.byKey(const Key('icon_choice_gamepad')), findsOneWidget);

    // Finish Creation
    await tester.tap(find.byKey(const Key('workspace_create_finish_button')));
    await tester.pumpAndSettle();

    // Verify callback arguments passed from the 3-step flow
    expect(createdName, 'Game Backlog');
    expect(createdType, ProfileType.games);
    expect(createdIcon, 'gamepad');
    expect(createdSchema, isNull);

    // Verify dialog dismissed
    expect(find.byType(AddWorkspaceDialog), findsNothing);
  });
}
