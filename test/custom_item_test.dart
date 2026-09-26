import 'package:flutter_test/flutter_test.dart';
import 'package:canele/models/custom_item.dart';
import 'package:canele/models/profile.dart';
import 'package:canele/core/utils/workspace_terminology.dart';

void main() {
  group('CustomItem Domain Model & Serialization Tests', () {
    test('CustomItem toSeries and fromSeries bidirectional fidelity', () {
      final item = CustomItem(
        id: 'vinyl_001',
        title: 'Random Access Memories',
        groupTitle: 'Daft Punk',
        status: 'completed',
        price: 39.99,
        currency: 'USD',
        releaseDate: DateTime(2013, 5, 17),
        rating: 9.8,
        edition: '10th Anniversary 180g Vinyl',
        platform: 'Vinyl',
        notes: 'Includes bonus track GLBTM Studio Outtakes',
        tags: ['Electronic', 'French House'],
        customFields: {'catalogNumber': '88883716861', 'color': 'Black'},
      );

      final series = item.toSeries();
      expect(series.id, 'vinyl_001');
      expect(series.title, 'Random Access Memories');
      expect(series.customMetadata['groupTitle'], 'Daft Punk');
      expect(series.type, 'custom');
      expect(series.collectionStatus, 'completed');
      expect(series.seriesPrice, 39.99);
      expect(series.customMetadata['isCustom'], true);
      expect(series.customMetadata['edition'], '10th Anniversary 180g Vinyl');
      expect(series.customMetadata['customFields']['catalogNumber'], '88883716861');

      final reconstructed = CustomItem.fromSeries(series);
      expect(reconstructed.id, item.id);
      expect(reconstructed.title, item.title);
      expect(reconstructed.groupTitle, 'Daft Punk');
      expect(reconstructed.status, 'completed');
      expect(reconstructed.price, 39.99);
      expect(reconstructed.currency, 'USD');
      expect(reconstructed.rating, 9.8);
      expect(reconstructed.edition, '10th Anniversary 180g Vinyl');
      expect(reconstructed.platform, 'Vinyl');
      expect(reconstructed.notes, item.notes);
      expect(reconstructed.tags, item.tags);
      expect(reconstructed.customFields['catalogNumber'], '88883716861');
    });

    test('CustomItem status mapping to collectionStatus', () {
      const wishlistRecord = CustomItem(
        id: 'w1',
        title: 'Wishlist Record',
        status: 'wishlist',
      );
      expect(wishlistRecord.toSeries().collectionStatus, 'wishlist');

      const completedRecord = CustomItem(
        id: 'c1',
        title: 'Finished Record',
        status: 'completed',
      );
      expect(completedRecord.toSeries().collectionStatus, 'completed');

      const backlogRecord = CustomItem(
        id: 'b1',
        title: 'Queued Record',
        status: 'backlog',
      );
      expect(backlogRecord.toSeries().collectionStatus, 'active');
    });
  });

  group('WorkspaceTerminology Resolver Tests', () {
    test('Default terminology for Books preset', () {
      final bookProfile = Profile(
        id: 'books',
        name: 'Books',
        type: ProfileType.books,
        createdAt: DateTime.now(),
      );

      expect(bookProfile.terms.groupLabel, 'Series');
      expect(bookProfile.terms.itemLabel, 'Volume');
      expect(bookProfile.terms.itemsLabel, 'Volumes');
      expect(bookProfile.terms.isFieldEnabled('platform'), isFalse);
      expect(bookProfile.terms.isFieldEnabled('price'), isTrue);
    });

    test('Default terminology for Games preset', () {
      final gameProfile = Profile(
        id: 'games',
        name: 'Games',
        type: ProfileType.games,
        createdAt: DateTime.now(),
      );

      expect(gameProfile.terms.groupLabel, 'Franchise');
      expect(gameProfile.terms.itemLabel, 'Game');
      expect(gameProfile.terms.itemsLabel, 'Games');
      expect(gameProfile.terms.isFieldEnabled('platform'), isTrue);
    });

    test('Custom workspace terminology and schema field toggles', () {
      final customProfile = Profile(
        id: 'vinyl_collection',
        name: 'Vinyl Collection',
        type: ProfileType.custom,
        createdAt: DateTime.now(),
        customSchema: const CustomWorkspaceSchema(
          itemLabel: 'Record',
          groupLabel: 'Artist',
          enabledFields: {
            'coverUrl': true,
            'price': true,
            'releaseDate': true,
            'edition': true,
            'rating': true,
            'platform': false, // No platform needed for vinyl
          },
          customStatuses: ['wanted', 'ordered', 'inCollection'],
        ),
      );

      expect(customProfile.terms.groupLabel, 'Artist');
      expect(customProfile.terms.itemLabel, 'Record');
      expect(customProfile.terms.itemsLabel, 'Records');

      // Schema field toggles
      expect(customProfile.terms.isFieldEnabled('edition'), isTrue);
      expect(customProfile.terms.isFieldEnabled('rating'), isTrue);
      expect(customProfile.terms.isFieldEnabled('platform'), isFalse);

      // Custom statuses
      final statuses = customProfile.terms.availableStatuses;
      expect(statuses.length, 3);
      expect(statuses[0].key, 'wanted');
      expect(statuses[1].key, 'ordered');
      expect(statuses[2].key, 'inCollection');
    });
  });
}
