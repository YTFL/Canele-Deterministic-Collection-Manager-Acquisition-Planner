import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:canele/models/profile.dart';
import 'package:canele/models/series.dart';
import 'package:canele/models/volume.dart';
import 'package:canele/models/game_item.dart';
import 'package:canele/models/custom_item.dart';
import 'package:canele/services/universal_exporter.dart';

void main() {
  group('Universal Exporter Tests', () {
    test('generateCollectionRows generates book columns for Books profile', () {
      final booksProfile = Profile(
        id: 'p_books',
        name: 'My Books',
        type: ProfileType.books,
        createdAt: DateTime(2026, 1, 1),
      );

      final seriesList = [
        Series(
          id: 's1',
          title: 'Frieren: Beyond Journey\'s End',
          type: 'manga',
          collectionStatus: 'active',
          totalVolumesReleased: 12,
          customMetadata: {'author': 'Kanehito Yamada'},
          tags: ['Fantasy', 'Adventure'],
        ),
      ];

      final volumesList = [
        Volume(
          id: 'v1',
          seriesId: 's1',
          volumeNumber: 1,
          isOwned: true,
          price: 9.99,
          currency: 'USD',
        ),
        Volume(
          id: 'v2',
          seriesId: 's1',
          volumeNumber: 2,
          isOwned: true,
          price: 9.99,
          currency: 'USD',
        ),
      ];

      final rows = UniversalExporter.generateCollectionRows(
        profile: booksProfile,
        seriesList: seriesList,
        volumesList: volumesList,
      );

      expect(rows.length, 2); // 1 header + 1 series
      final header = rows[0];
      expect(header, contains('Title'));
      expect(header, contains('Author'));
      expect(header, contains('Total Volumes'));
      expect(header, contains('Owned Volumes'));
      expect(header, contains('Total Spent (USD)'));

      final dataRow = rows[1];
      expect(dataRow[0], 'Frieren: Beyond Journey\'s End');
      expect(dataRow[1], 'Kanehito Yamada');
      expect(dataRow[4], 12); // total
      expect(dataRow[5], 2); // owned
    });

    test('generateCollectionRows generates gaming columns for Games profile', () {
      final gamesProfile = Profile(
        id: 'p_games',
        name: 'Game Backlog',
        type: ProfileType.games,
        createdAt: DateTime(2026, 1, 1),
      );

      final game = const GameItem(
        id: 'g1',
        title: 'Elden Ring',
        platform: 'pc',
        backlogStatus: GameBacklogStatus.playing,
        playtimeHours: 72.5,
        price: 59.99,
        currency: 'USD',
        notes: 'Masterpiece open world RPG',
        tags: ['Soulsborne', 'Action RPG'],
      );

      final rows = UniversalExporter.generateCollectionRows(
        profile: gamesProfile,
        seriesList: [game.toSeries()],
      );

      expect(rows.length, 2);
      final header = rows[0];
      expect(header, [
        'Title',
        'Platform',
        'Status',
        'Playtime (Hours)',
        'Price (USD)',
        'Currency',
        'Release Date',
        'Notes',
        'Tags',
      ]);

      final dataRow = rows[1];
      expect(dataRow[0], 'Elden Ring');
      expect(dataRow[1], 'PC / Steam');
      expect(dataRow[2], 'Playing');
      expect(dataRow[3], '72.5');
      expect(dataRow[4], '59.99');
      expect(dataRow[7], 'Masterpiece open world RPG');
      expect(dataRow[8], contains('Soulsborne'));
    });

    test('generateCollectionRows generates dynamic columns for Custom profile', () {
      final vinylProfile = Profile(
        id: 'p_vinyl',
        name: 'Vinyl Collection',
        type: ProfileType.custom,
        createdAt: DateTime(2026, 1, 1),
        customSchema: const CustomWorkspaceSchema(
          itemLabel: 'Record',
          groupLabel: 'Artist',
          enabledFields: {
            'coverUrl': true,
            'price': true,
            'releaseDate': true,
            'rating': true,
            'edition': true,
            'platform': false, // Format disabled
            'notes': true,
          },
        ),
      );

      final record = const CustomItem(
        id: 'v1',
        title: 'Abbey Road',
        groupTitle: 'The Beatles',
        status: 'completed',
        price: 34.99,
        currency: 'USD',
        edition: '50th Anniversary Remaster',
        rating: 10.0,
        notes: 'Mint condition',
        tags: ['Rock', 'Classics'],
      );

      final rows = UniversalExporter.generateCollectionRows(
        profile: vinylProfile,
        seriesList: [record.toSeries()],
      );

      final header = rows[0];
      expect(header[0], 'Title');
      expect(header[1], 'Artist'); // Custom group label
      expect(header, contains('Edition'));
      expect(header, contains('Price (USD)'));
      expect(header, contains('Rating'));
      expect(header, contains('Notes'));
      expect(header, contains('Tags'));
      expect(header, isNot(contains('Category'))); // Disabled in schema

      final dataRow = rows[1];
      expect(dataRow[0], 'Abbey Road');
      expect(dataRow[1], 'The Beatles');
      expect(dataRow, contains('50th Anniversary Remaster'));
      expect(dataRow, contains('34.99'));
      expect(dataRow, contains('10.0'));
      expect(dataRow, contains('Mint condition'));
    });

    test('exportCollectionToCsv generates compliant CSV string', () {
      final gamesProfile = Profile(
        id: 'p_games',
        name: 'Games',
        type: ProfileType.games,
        createdAt: DateTime(2026, 1, 1),
      );

      final game = const GameItem(
        id: 'g2',
        title: 'Hollow Knight: Silksong',
        platform: 'switch',
        backlogStatus: GameBacklogStatus.wishlist,
      );

      final csv = UniversalExporter.exportCollectionToCsv(
        profile: gamesProfile,
        seriesList: [game.toSeries()],
      );

      expect(csv, contains('Title,Platform,Status,Playtime (Hours)'));
      expect(csv, contains('Hollow Knight: Silksong,Nintendo Switch,Wishlist'));
    });
  });

  group('Multi-Workspace Backup JSON Contract Tests', () {
    test('JSON serialization validates multi-profile structure', () {
      final profiles = [
        Profile(
          id: 'books_01',
          name: 'Books',
          type: ProfileType.books,
          createdAt: DateTime(2026, 1, 1),
        ),
        Profile(
          id: 'games_02',
          name: 'Games',
          type: ProfileType.games,
          createdAt: DateTime(2026, 2, 1),
        ),
      ];

      final mockBackup = {
        'version': '2.0.0',
        'schemaVersion': 2,
        'exportedAt': '2026-09-26T10:00:00.000Z',
        'activeProfileId': 'books_01',
        'profiles': profiles.map((p) => p.toMap()).toList(),
        'workspaces': {
          'books_01': {
            'profile': profiles[0].toMap(),
            'series': [
              {
                'id': 'b1',
                'title': 'Dune',
                'type': 'novel',
                'collectionStatus': 'completed',
              }
            ],
            'volumes': [],
            'transactions': [],
            'ruleConfig': {'id': 'global_config', 'monthlyQuota': 4},
            'rules': [],
          },
          'games_02': {
            'profile': profiles[1].toMap(),
            'series': [
              {
                'id': 'g1',
                'title': 'Zelda: Tears of the Kingdom',
                'type': 'game',
                'collectionStatus': 'completed',
                'customMetadata': {
                  'isGame': true,
                  'platform': 'switch',
                  'backlogStatus': 'beaten',
                },
              }
            ],
            'volumes': [],
            'transactions': [],
            'ruleConfig': {'id': 'global_config', 'monthlyQuota': 2},
            'rules': [],
          },
        },
      };

      final jsonStr = jsonEncode(mockBackup);
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;

      expect(decoded['version'], '2.0.0');
      expect(decoded['profiles'], hasLength(2));
      expect(decoded['workspaces'], contains('books_01'));
      expect(decoded['workspaces'], contains('games_02'));

      final gamesWorkspace = decoded['workspaces']['games_02'] as Map<String, dynamic>;
      final gameSeries = (gamesWorkspace['series'] as List).first as Map<String, dynamic>;
      expect(gameSeries['title'], 'Zelda: Tears of the Kingdom');
      expect(gameSeries['customMetadata']['platform'], 'switch');
    });

    test('Legacy v1 backup payload remains parseable', () {
      final legacyV1Payload = {
        'version': '1.0.0',
        'exportedAt': '2025-01-01T00:00:00.000Z',
        'series': [
          {
            'id': 'legacy_1',
            'title': 'Berserk',
            'type': 'manga',
            'collectionStatus': 'active',
          }
        ],
        'volumes': [
          {
            'id': 'v_legacy_1',
            'seriesId': 'legacy_1',
            'volumeNumber': 1,
            'isOwned': true,
          }
        ],
      };

      final jsonStr = jsonEncode(legacyV1Payload);
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;

      // Detects as legacy format
      expect(decoded.containsKey('workspaces'), false);
      expect(decoded['series'], hasLength(1));
      expect(decoded['volumes'], hasLength(1));
      expect(decoded['series'][0]['title'], 'Berserk');
    });
  });
}
