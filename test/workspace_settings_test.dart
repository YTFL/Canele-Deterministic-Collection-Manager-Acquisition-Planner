import 'package:flutter_test/flutter_test.dart';
import 'package:canele/models/profile.dart';
import 'package:canele/core/utils/workspace_terminology.dart';

void main() {
  group('Profile & Workspace Settings Unit Tests', () {
    test('ProfileType displayName returns expected titles', () {
      expect(ProfileType.books.displayName, equals('Books & Manga'));
      expect(ProfileType.games.displayName, equals('Games'));
      expect(ProfileType.custom.displayName, equals('Custom'));
    });

    test('Profile isDefault returns true for default books profile and false otherwise', () {
      final defaultProfile = Profile(
        id: 'profile_default_books',
        name: 'Books & Manga',
        type: ProfileType.books,
        createdAt: DateTime(2026, 1, 1),
      );

      final customProfile = Profile(
        id: 'profile_12345678',
        name: 'Vinyl Collection',
        type: ProfileType.custom,
        createdAt: DateTime(2026, 1, 2),
      );

      expect(defaultProfile.isDefault, isTrue);
      expect(customProfile.isDefault, isFalse);
    });

    test('WorkspaceTerminology resolves labels and pluralization accurately', () {
      final booksProfile = Profile(
        id: 'p_books',
        name: 'Books',
        type: ProfileType.books,
        createdAt: DateTime(2026, 1, 1),
      );
      final booksTerm = WorkspaceTerminology(booksProfile);
      expect(booksTerm.groupLabel, equals('Series'));
      expect(booksTerm.itemLabel, equals('Volume'));
      expect(booksTerm.itemsLabel, equals('Volumes'));

      final gamesProfile = Profile(
        id: 'p_games',
        name: 'Games',
        type: ProfileType.games,
        createdAt: DateTime(2026, 1, 1),
      );
      final gamesTerm = WorkspaceTerminology(gamesProfile);
      expect(gamesTerm.groupLabel, equals('Franchise'));
      expect(gamesTerm.itemLabel, equals('Game'));
      expect(gamesTerm.itemsLabel, equals('Games'));

      final customProfile = Profile(
        id: 'p_custom',
        name: 'My Vinyls',
        type: ProfileType.custom,
        createdAt: DateTime(2026, 1, 1),
        customSchema: const CustomWorkspaceSchema(
          itemLabel: 'Vinyl',
          groupLabel: 'Artist',
        ),
      );
      final customTerm = WorkspaceTerminology(customProfile);
      expect(customTerm.groupLabel, equals('Artist'));
      expect(customTerm.itemLabel, equals('Vinyl'));
      expect(customTerm.itemsLabel, equals('Vinyls'));
    });

    test('WorkspaceTerminology pluralizes irregular endings properly', () {
      final categoryProfile = Profile(
        id: 'p_cat',
        name: 'Categories',
        type: ProfileType.custom,
        createdAt: DateTime(2026, 1, 1),
        customSchema: const CustomWorkspaceSchema(
          itemLabel: 'Category',
          groupLabel: 'Department',
        ),
      );
      final catTerm = WorkspaceTerminology(categoryProfile);
      expect(catTerm.itemsLabel, equals('Categories'));

      final seriesProfile = Profile(
        id: 'p_ser',
        name: 'Series Collection',
        type: ProfileType.custom,
        createdAt: DateTime(2026, 1, 1),
        customSchema: const CustomWorkspaceSchema(
          itemLabel: 'Series',
          groupLabel: 'Franchise',
        ),
      );
      final serTerm = WorkspaceTerminology(seriesProfile);
      expect(serTerm.itemsLabel, equals('Series'));
    });

    test('CustomWorkspaceSchema serialization and copyWith works seamlessly', () {
      const schema = CustomWorkspaceSchema(
        itemLabel: 'Watch',
        groupLabel: 'Brand',
        enabledFields: {'price': true, 'rating': true, 'platform': false},
        customStatuses: ['wishlist', 'owned', 'sold'],
      );

      final map = schema.toMap();
      final revived = CustomWorkspaceSchema.fromMap(map);

      expect(revived.itemLabel, equals('Watch'));
      expect(revived.groupLabel, equals('Brand'));
      expect(revived.enabledFields['rating'], isTrue);
      expect(revived.enabledFields['platform'], isFalse);
      expect(revived.customStatuses, containsAll(['wishlist', 'owned', 'sold']));

      final modified = revived.copyWith(itemLabel: 'Timepiece');
      expect(modified.itemLabel, equals('Timepiece'));
      expect(modified.groupLabel, equals('Brand'));
    });

    test('Profile copyWith preserves or clears custom schema safely', () {
      final profile = Profile(
        id: 'p1',
        name: 'Original',
        type: ProfileType.custom,
        createdAt: DateTime(2026, 1, 1),
        customSchema: const CustomWorkspaceSchema(itemLabel: 'Item'),
      );

      final renamed = profile.copyWith(name: 'Renamed');
      expect(renamed.name, equals('Renamed'));
      expect(renamed.customSchema?.itemLabel, equals('Item'));

      final cleared = profile.copyWith(clearCustomSchema: true);
      expect(cleared.customSchema, isNull);
    });
  });
}
