import 'package:flutter_test/flutter_test.dart';
import 'package:canele/models/profile.dart';

void main() {
  group('Profile Model Tests', () {
    test('Serializes and deserializes Books profile correctly', () {
      final now = DateTime.now();
      final profile = Profile(
        id: 'p_books_1',
        name: 'Manga & Novels',
        type: ProfileType.books,
        icon: 'book',
        createdAt: now,
      );

      final map = profile.toMap();
      expect(map['id'], 'p_books_1');
      expect(map['name'], 'Manga & Novels');
      expect(map['type'], 'books');
      expect(map['icon'], 'book');
      expect(map['createdAt'], now.toIso8601String());

      final restored = Profile.fromMap(map);
      expect(restored.id, profile.id);
      expect(restored.name, profile.name);
      expect(restored.type, ProfileType.books);
      expect(restored.icon, 'book');
    });

    test('Serializes and deserializes Games profile with CustomSchema', () {
      final now = DateTime.now();
      const schema = CustomWorkspaceSchema(
        itemLabel: 'Game',
        groupLabel: 'Franchise',
        enabledFields: {
          'coverUrl': true,
          'platform': true,
          'edition': true,
        },
        customStatuses: ['backlog', 'playing', 'beaten', 'completed'],
      );

      final profile = Profile(
        id: 'p_games_1',
        name: 'My Backlog',
        type: ProfileType.games,
        icon: 'gamepad',
        createdAt: now,
        customSchema: schema,
      );

      final map = profile.toMap();
      expect(map['type'], 'games');
      expect(map['customSchema'], isNotNull);
      expect(map['customSchema']['itemLabel'], 'Game');
      expect(map['customSchema']['customStatuses'], contains('beaten'));

      final restored = Profile.fromMap(map);
      expect(restored.type, ProfileType.games);
      expect(restored.customSchema?.itemLabel, 'Game');
      expect(restored.customSchema?.customStatuses.length, 4);
    });

    test('copyWith works predictably and handles schema clearing', () {
      final profile = Profile(
        id: 'p_1',
        name: 'Test',
        type: ProfileType.custom,
        createdAt: DateTime.now(),
        customSchema: const CustomWorkspaceSchema(itemLabel: 'Item'),
      );

      final renamed = profile.copyWith(name: 'Updated Name');
      expect(renamed.name, 'Updated Name');
      expect(renamed.customSchema?.itemLabel, 'Item');

      final cleared = profile.copyWith(clearCustomSchema: true);
      expect(cleared.customSchema, isNull);
    });
  });
}
