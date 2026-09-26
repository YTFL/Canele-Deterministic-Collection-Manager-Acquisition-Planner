import 'package:flutter_test/flutter_test.dart';
import 'package:canele/models/game_item.dart';

void main() {
  group('GameItem Domain Model & Enums Tests', () {
    test('GameBacklogStatus labels, colors, and status cycle progression', () {
      expect(GameBacklogStatus.backlog.label, 'Backlog');
      expect(GameBacklogStatus.playing.label, 'Playing');
      expect(GameBacklogStatus.beaten.label, 'Beaten');
      expect(GameBacklogStatus.completed.label, 'Completed');

      // Test one-tap cycling progression
      expect(GameBacklogStatus.backlog.cycleNext(), GameBacklogStatus.playing);
      expect(GameBacklogStatus.playing.cycleNext(), GameBacklogStatus.beaten);
      expect(GameBacklogStatus.beaten.cycleNext(), GameBacklogStatus.completed);
      expect(GameBacklogStatus.completed.cycleNext(), GameBacklogStatus.backlog);
      expect(GameBacklogStatus.wishlist.cycleNext(), GameBacklogStatus.backlog);
    });

    test('GamePlatform presets and fallback lookup', () {
      final ps5 = GamePlatform.fromString('ps5');
      expect(ps5.displayName, 'PlayStation 5');

      final switchPlatform = GamePlatform.fromString('Nintendo Switch');
      expect(switchPlatform.key, 'switch');

      final customPlatform = GamePlatform.fromString('Atari 2600');
      expect(customPlatform.displayName, 'Atari 2600');
    });

    test('GameItem toSeries and fromSeries bidirectional serialization fidelity', () {
      final game = GameItem(
        id: 'game_elden_ring',
        title: 'Elden Ring',
        platform: 'ps5',
        edition: 'Collector\'s Edition',
        format: GameFormat.physical,
        backlogStatus: GameBacklogStatus.playing,
        price: 89.99,
        currency: 'USD',
        coverUrl: 'https://example.com/elden_ring.jpg',
        rating: 9.5,
        playtimeHours: 65.5,
        notes: 'Defeated Malenia!',
        tags: ['FromSoftware', 'Soulslike'],
        releaseDate: DateTime(2022, 2, 25),
      );

      final series = game.toSeries();
      expect(series.id, 'game_elden_ring');
      expect(series.title, 'Elden Ring');
      expect(series.type, 'game');
      expect(series.collectionStatus, 'active');
      expect(series.seriesPrice, 89.99);
      expect(series.currency, 'USD');
      expect(series.customMetadata['isGame'], true);
      expect(series.customMetadata['backlogStatus'], 'playing');
      expect(series.customMetadata['edition'], 'Collector\'s Edition');
      expect(series.customMetadata['playtimeHours'], 65.5);

      // Reconstruct GameItem from Series
      final reconstructed = GameItem.fromSeries(series);
      expect(reconstructed.id, game.id);
      expect(reconstructed.title, game.title);
      expect(reconstructed.platform, 'ps5');
      expect(reconstructed.edition, 'Collector\'s Edition');
      expect(reconstructed.format, GameFormat.physical);
      expect(reconstructed.backlogStatus, GameBacklogStatus.playing);
      expect(reconstructed.price, 89.99);
      expect(reconstructed.currency, 'USD');
      expect(reconstructed.rating, 9.5);
      expect(reconstructed.playtimeHours, 65.5);
      expect(reconstructed.notes, 'Defeated Malenia!');
      expect(reconstructed.releaseDate?.year, 2022);
    });

    test('GameItem collectionStatus mapping for completed and wishlist', () {
      const wishlistGame = GameItem(
        id: 'g1',
        title: 'Metroid Prime 4',
        backlogStatus: GameBacklogStatus.wishlist,
      );
      expect(wishlistGame.toSeries().collectionStatus, 'wishlist');

      const beatenGame = GameItem(
        id: 'g2',
        title: 'God of War Ragnarok',
        backlogStatus: GameBacklogStatus.beaten,
      );
      expect(beatenGame.toSeries().collectionStatus, 'completed');
    });
  });
}
