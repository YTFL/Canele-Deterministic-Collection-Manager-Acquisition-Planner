import '../core/utils/uuid_generator.dart';
import '../models/series.dart';
import '../models/volume.dart';
import '../models/purchase_transaction.dart';
import '../repositories/series_repository.dart';
import '../repositories/transaction_repository.dart';
import '../repositories/volume_repository.dart';

class SeriesService {
  final SeriesRepository seriesRepository;
  final VolumeRepository volumeRepository;
  final TransactionRepository transactionRepository;

  SeriesService({
    required this.seriesRepository,
    required this.volumeRepository,
    required this.transactionRepository,
  });

  /// Creates a new Series along with auto-generated Volume records.
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
    final seriesId = UuidGenerator.generate();
    final series = Series(
      id: seriesId,
      title: title.trim(),
      type: type,
      collectionStatus: collectionStatus,
      releaseStatus: releaseStatus,
      totalVolumesReleased: totalReleasedVolumes,
      tags: tags,
      customMetadata: customMetadata,
    );

    await seriesRepository.save(series);

    final count = totalReleasedVolumes > 0 ? totalReleasedVolumes : 1;
    final volumes = <Volume>[];

    for (int i = 1; i <= count; i++) {
      final isThisOwned = markOwned && (i <= ownedCount);
      volumes.add(
        Volume(
          id: UuidGenerator.generate(),
          seriesId: seriesId,
          volumeNumber: i.toDouble(),
          isOwned: isThisOwned,
          availability: 'available',
          isRestockedWatchlist: false,
          isGift: isThisOwned && isGift,
        ),
      );
    }

    if (volumes.isNotEmpty) {
      await volumeRepository.saveBatch(volumes);
    }

    // Create purchase transactions for all owned volumes
    final ownedVolumes = volumes.where((v) => v.isOwned).toList();
    final now = DateTime.now();
    for (final v in ownedVolumes) {
      final tx = PurchaseTransaction(
        id: UuidGenerator.generate(),
        volumeId: v.id,
        purchaseDate: now,
        quotaBucket: isGift ? 'gift' : 'regular',
        price: 0.0,
        notes: isGift ? 'Received as gift' : 'Added during series creation',
      );
      await transactionRepository.save(tx);
    }

    return series;
  }
}
