import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:canele/models/backup_manifest.dart';
import 'package:canele/models/profile.dart';
import 'package:canele/services/backup_service.dart';
import 'package:canele/ui/widgets/multi_space_restore_dialog.dart';

void main() {
  group('Multi-Space Backup Structure Tests', () {
    test('sanitizeFolderName cleans illegal characters', () {
      expect(BackupService.sanitizeFolderName('Books/Manga?*:|"<>'), 'Books_Manga_______');
      expect(BackupService.sanitizeFolderName('   Steam Games   '), 'Steam Games');
      expect(BackupService.sanitizeFolderName(''), 'Space');
    });

    test('resolveSpaceFolderName preserves clean names and disambiguates duplicates', () {
      final p1 = Profile(
        id: 'profile_books_123456',
        name: 'Books & Manga',
        type: ProfileType.books,
        createdAt: DateTime(2026, 1, 1),
      );
      final p2 = Profile(
        id: 'profile_games_789012',
        name: 'Steam Games',
        type: ProfileType.games,
        createdAt: DateTime(2026, 2, 1),
      );
      final p3 = Profile(
        id: 'profile_games_dup999',
        name: 'Steam Games',
        type: ProfileType.games,
        createdAt: DateTime(2026, 3, 1),
      );

      final all = [p1, p2, p3];

      expect(BackupService.resolveSpaceFolderName(p1, all), 'Books & Manga');
      // Duplicate Steam Games should append short ID
      expect(BackupService.resolveSpaceFolderName(p2, all), 'Steam Games_789012');
      expect(BackupService.resolveSpaceFolderName(p3, all), 'Steam Games_dup999');
    });

    test('BackupManifest serializes and deserializes accurately', () {
      final manifest = BackupManifest(
        version: '2.1.0',
        exportedAt: DateTime(2026, 3, 15, 12, 0, 0),
        spaces: [
          const SpaceBackupEntry(
            profileId: 'p_books',
            name: 'Books & Manga',
            type: ProfileType.books,
            folderName: 'Books & Manga',
            backupFileName: 'canele_backup.json',
            itemCount: 42,
            transactionCount: 15,
          ),
          const SpaceBackupEntry(
            profileId: 'p_games',
            name: 'Games',
            type: ProfileType.games,
            folderName: 'Games',
            backupFileName: 'canele_backup.json',
            itemCount: 20,
            transactionCount: 5,
          ),
        ],
      );

      final jsonStr = manifest.toJson(indent: true);
      expect(jsonStr, contains('"version": "2.1.0"'));
      expect(jsonStr, contains('Books & Manga'));
      expect(jsonStr, contains('"type": "games"'));

      final restored = BackupManifest.fromJson(jsonStr);
      expect(restored.version, '2.1.0');
      expect(restored.spaces.length, 2);
      expect(restored.spaces[0].name, 'Books & Manga');
      expect(restored.spaces[0].type, ProfileType.books);
      expect(restored.spaces[0].itemCount, 42);
      expect(restored.spaces[1].name, 'Games');
      expect(restored.spaces[1].type, ProfileType.games);
      expect(restored.spaces[1].itemCount, 20);
    });

    test('MultiSpaceRestoreDialog.discoverSpaces detects manifest and subfolder backups', () async {
      final tempDir = await Directory.systemTemp.createTemp('canele_backup_test_');

      try {
        // Create Books space folder
        final booksDir = Directory('${tempDir.path}/Books & Manga');
        await booksDir.create(recursive: true);
        final booksFile = File('${booksDir.path}/canele_backup.json');
        await booksFile.writeAsString('''{
          "version": "2.1.0",
          "profile": {"id": "p_b", "name": "Books & Manga", "type": "books"},
          "series": [{"id": "s1", "title": "86"}],
          "volumes": []
        }''');

        // Create Games space folder
        final gamesDir = Directory('${tempDir.path}/Games');
        await gamesDir.create(recursive: true);
        final gamesFile = File('${gamesDir.path}/canele_backup.json');
        await gamesFile.writeAsString('''{
          "version": "2.1.0",
          "spaceType": "games",
          "profile": {"id": "p_g", "name": "Games", "type": "games"},
          "franchises": [{"id": "f1", "title": "Dark Souls"}],
          "games": [{"id": "g1", "title": "Dark Souls Remastered", "itemType": "game"}]
        }''');

        // Create manifest
        final manifestFile = File('${tempDir.path}/canele_manifest.json');
        await manifestFile.writeAsString('''{
          "version": "2.1.0",
          "exportedAt": "2026-03-15T12:00:00.000Z",
          "spaces": [
            {
              "profileId": "p_b",
              "name": "Books & Manga",
              "type": "books",
              "folderName": "Books & Manga",
              "backupFileName": "canele_backup.json",
              "itemCount": 1
            },
            {
              "profileId": "p_g",
              "name": "Games",
              "type": "games",
              "folderName": "Games",
              "backupFileName": "canele_backup.json",
              "itemCount": 1
            }
          ]
        }''');

        final discovered = await MultiSpaceRestoreDialog.discoverSpaces(tempDir);
        expect(discovered.length, 2);

        final booksSpace = discovered.firstWhere((s) => s.type == ProfileType.books);
        expect(booksSpace.name, 'Books & Manga');
        expect(booksSpace.folderName, 'Books & Manga');
        expect(booksSpace.itemCount, 1);

        final gamesSpace = discovered.firstWhere((s) => s.type == ProfileType.games);
        expect(gamesSpace.name, 'Games');
        expect(gamesSpace.folderName, 'Games');
        expect(gamesSpace.itemCount, 1);
      } finally {
        await tempDir.delete(recursive: true);
      }
    });
  });
}
