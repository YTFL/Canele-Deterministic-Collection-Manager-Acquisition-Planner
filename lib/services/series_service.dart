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
    double? seriesPrice,
    String? currency,
    double? defaultVolumePrice,
    String? defaultVolumeCurrency,
    List<String> tags = const [],
    Map<String, dynamic> customMetadata = const {},
  }) async {
    final isCompletedStatus = collectionStatus == 'completed';
    final effectiveReleaseStatus = isCompletedStatus ? 'completed' : releaseStatus;
    final seriesId = UuidGenerator.generate();
    final series = Series(
      id: seriesId,
      title: title.trim(),
      type: type,
      collectionStatus: collectionStatus,
      releaseStatus: effectiveReleaseStatus,
      totalVolumesReleased: totalReleasedVolumes,
      seriesPrice: seriesPrice,
      currency: currency,
      defaultVolumePrice: defaultVolumePrice,
      defaultVolumeCurrency: defaultVolumeCurrency,
      tags: tags,
      customMetadata: customMetadata,
    );

    await seriesRepository.save(series);

    final count = totalReleasedVolumes > 0 ? totalReleasedVolumes : 1;
    final effectiveOwnedCount = isCompletedStatus ? count : ownedCount;
    final effectiveMarkOwned = isCompletedStatus ? true : markOwned;
    final effectiveIsGift = isCompletedStatus && !isGift ? false : isGift;
    final volumes = <Volume>[];

    final isGame = type == 'game' || customMetadata['isGame'] == true;
    for (int i = 1; i <= count; i++) {
      final isThisOwned = effectiveMarkOwned && (i <= effectiveOwnedCount);
      final volMetadata = <String, dynamic>{};
      if (isGame) {
        volMetadata['isGame'] = true;
        volMetadata['itemType'] = 'game';
        volMetadata['title'] = count == 1 ? title.trim() : '${title.trim()} $i';
        if (customMetadata.containsKey('platform')) {
          volMetadata['platform'] = customMetadata['platform'];
        }
      }
      volumes.add(
        Volume(
          id: UuidGenerator.generate(),
          seriesId: seriesId,
          volumeNumber: i.toDouble(),
          isOwned: isThisOwned,
          availability: 'available',
          isRestockedWatchlist: false,
          isGift: isThisOwned && effectiveIsGift,
          price: defaultVolumePrice,
          currency: defaultVolumeCurrency,
          customMetadata: volMetadata,
        ),
      );
    }

    if (volumes.isNotEmpty) {
      await volumeRepository.saveBatch(volumes);
    }

    // Create purchase transactions for all owned volumes
    final ownedVolumes = volumes.where((v) => v.isOwned).toList();
    final now = DateTime.now();
    final txs = <PurchaseTransaction>[];
    for (final v in ownedVolumes) {
      txs.add(
        PurchaseTransaction(
          id: UuidGenerator.generate(),
          volumeId: v.id,
          purchaseDate: now,
          quotaBucket: effectiveIsGift ? 'gift' : 'regular',
          price: v.price ?? 0.0,
          currency: v.currency,
          notes: effectiveIsGift ? 'Received as gift' : 'Added during creation',
        ),
      );
    }
    if (txs.isNotEmpty) {
      await transactionRepository.saveBatch(txs);
    }

    return series;
  }
}
