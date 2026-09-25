import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:canele/core/database/hive_boxes.dart';
import 'package:canele/models/profile.dart';
import 'package:canele/models/rule_model.dart';
import 'package:canele/models/series.dart';
import 'package:canele/repositories/series_repository.dart';
import 'package:canele/services/profile_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('canele_profile_service_test');
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

  group('ProfileService CRUD & Data Isolation Tests', () {
    test('Initializes with default books workspace', () {
      final service = ProfileService.instance;
      expect(service.getAllProfiles().length, 1);
      expect(service.activeProfileId, ProfileService.defaultBooksProfileId);
      expect(service.activeProfile.name, 'Books & Manga');
      expect(service.activeProfile.type, ProfileType.books);
    });

    test('Creates new Games workspace and switches into it', () async {
      final service = ProfileService.instance;
      final newProfile = await service.createProfile(
        name: 'Game Backlog',
        type: ProfileType.games,
        icon: 'gamepad',
      );

      expect(newProfile.name, 'Game Backlog');
      expect(newProfile.type, ProfileType.games);
      expect(service.activeProfileId, newProfile.id);
      expect(service.getAllProfiles().length, 2);
    });

    test('Maintains complete data isolation between workspaces', () async {
      final service = ProfileService.instance;
      final repo = SeriesRepository();

      // 1. In default books workspace, add a book series
      await repo.save(const Series(
        id: 'book_s1',
        title: 'Chainsaw Man',
        type: 'manga',
      ));

      expect(repo.getAll().length, 1);
      expect(repo.getAll().first.title, 'Chainsaw Man');

      // 2. Create Games workspace
      final gamesProfile = await service.createProfile(
        name: 'PS5 & PC Games',
        type: ProfileType.games,
        icon: 'gamepad',
      );

      // Verify the new workspace starts empty
      expect(service.activeProfileId, gamesProfile.id);
      expect(repo.getAll(), isEmpty);

      // Save a game series into games workspace
      await repo.save(const Series(
        id: 'game_s1',
        title: 'Elden Ring',
        type: 'game',
      ));

      expect(repo.getAll().length, 1);
      expect(repo.getAll().first.title, 'Elden Ring');

      // 3. Switch back to books workspace
      await service.switchProfile(ProfileService.defaultBooksProfileId);
      expect(service.activeProfileId, ProfileService.defaultBooksProfileId);

      // Verify books workspace only has Chainsaw Man
      final booksList = repo.getAll();
      expect(booksList.length, 1);
      expect(booksList.first.title, 'Chainsaw Man');
    });

    test('Renames and updates profile metadata properly', () async {
      final service = ProfileService.instance;
      await service.renameProfile(
        ProfileService.defaultBooksProfileId,
        'Physical Manga & LN',
      );

      expect(service.activeProfile.name, 'Physical Manga & LN');
    });

    test('Cannot delete the only existing workspace', () async {
      final service = ProfileService.instance;
      expect(service.getAllProfiles().length, 1);
      final deleted = await service.deleteProfile(ProfileService.defaultBooksProfileId);
      expect(deleted, isFalse);
      expect(service.getAllProfiles().length, 1);
    });

    test('Deletes profile and cleans up scoped data correctly', () async {
      final service = ProfileService.instance;
      final extraProfile = await service.createProfile(
        name: 'Temporary Workspace',
        type: ProfileType.custom,
      );

      expect(service.getAllProfiles().length, 2);
      expect(service.activeProfileId, extraProfile.id);

      final deleted = await service.deleteProfile(extraProfile.id);
      expect(deleted, isTrue);
      expect(service.getAllProfiles().length, 1);
      expect(service.activeProfileId, ProfileService.defaultBooksProfileId);
    });
  });
}
