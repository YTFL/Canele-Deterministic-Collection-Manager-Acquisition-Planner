import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/series.dart';
import '../models/volume.dart';
import '../models/purchase_transaction.dart';
import 'database_provider.dart';
import 'quota_provider.dart';

import '../services/series_service.dart';

final seriesServiceProvider = Provider<SeriesService>((ref) {
  return SeriesService(
    seriesRepository: ref.read(seriesRepositoryProvider),
    volumeRepository: ref.read(volumeRepositoryProvider),
    transactionRepository: ref.read(transactionRepositoryProvider),
  );
});

// StateNotifier for Series
class SeriesNotifier extends StateNotifier<List<Series>> {
  final Ref _ref;
  SeriesNotifier(this._ref) : super([]) {
    load();
  }

  void load() {
    state = _ref.read(seriesRepositoryProvider).getAll();
  }

  Future<void> saveSeries(Series series) async {
    await _ref.read(seriesRepositoryProvider).save(series);
    load();
  }

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
    final service = _ref.read(seriesServiceProvider);
    final series = await service.createSeriesWithVolumes(
      title: title,
      type: type,
      collectionStatus: collectionStatus,
      releaseStatus: releaseStatus,
      totalReleasedVolumes: totalReleasedVolumes,
      ownedCount: ownedCount,
      markOwned: markOwned,
      isGift: isGift,
      tags: tags,
      customMetadata: customMetadata,
    );
    _ref.read(volumesNotifierProvider.notifier).load();
    _ref.read(transactionsNotifierProvider.notifier).load();
    load();
    return series;
  }

  Future<void> deleteSeries(String id) async {
    await _ref.read(seriesRepositoryProvider).delete(id);
    await _ref.read(volumeRepositoryProvider).deleteBySeriesId(id);
    _ref.read(volumesNotifierProvider.notifier).load();
    _ref.read(transactionsNotifierProvider.notifier).load();
    load();
  }
}

final seriesNotifierProvider = StateNotifierProvider<SeriesNotifier, List<Series>>((ref) {
  return SeriesNotifier(ref);
});

// StateNotifier for Volumes
class VolumesNotifier extends StateNotifier<List<Volume>> {
  final Ref _ref;
  VolumesNotifier(this._ref) : super([]) {
    load();
  }

  void load() {
    state = _ref.read(volumeRepositoryProvider).getAll();
  }

  Future<void> saveVolume(Volume volume) async {
    final now = DateTime.now();
    final isFuture = volume.releaseDate != null && volume.releaseDate!.isAfter(now);

    final effectiveAvailability = isFuture ? 'announced' : volume.availability;
    final effectiveWatchlist = (isFuture || effectiveAvailability == 'outOfStock' || effectiveAvailability == 'outOfPrint')
        ? true
        : volume.isRestockedWatchlist;

    final effectiveVolume = volume.copyWith(
      availability: effectiveAvailability,
      isRestockedWatchlist: effectiveWatchlist,
    );
    await _ref.read(volumeRepositoryProvider).save(effectiveVolume);
    load();
  }

  Future<void> saveBatch(List<Volume> volumes) async {
    final now = DateTime.now();
    final effectiveVolumes = volumes.map((v) {
      final isFuture = v.releaseDate != null && v.releaseDate!.isAfter(now);
      final effectiveAvailability = isFuture ? 'announced' : v.availability;
      final effectiveWatchlist = (isFuture || effectiveAvailability == 'outOfStock' || effectiveAvailability == 'outOfPrint')
          ? true
          : v.isRestockedWatchlist;

      return v.copyWith(
        availability: effectiveAvailability,
        isRestockedWatchlist: effectiveWatchlist,
      );
    }).toList();
    await _ref.read(volumeRepositoryProvider).saveBatch(effectiveVolumes);
    load();
  }

  Future<void> deleteVolume(String id) async {
    await _ref.read(volumeRepositoryProvider).delete(id);
    await _ref.read(transactionRepositoryProvider).deleteByVolumeId(id);
    _ref.read(transactionsNotifierProvider.notifier).load();
    load();
  }

  Future<void> toggleOwned(Volume volume, {bool? asGift}) async {
    final newOwned = !volume.isOwned;
    final newGift = asGift ?? volume.isGift;

    final updated = volume.copyWith(
      isOwned: newOwned,
      isGift: newOwned ? newGift : false,
    );

    await saveVolume(updated);

    if (newOwned) {
      // Check if transaction exists, if not create one
      final existingTx = _ref.read(transactionRepositoryProvider).getByVolumeId(volume.id);
      if (existingTx == null) {
        // Auto determine bucket
        final quotaSummary = _ref.read(quotaProvider);
        final bucket = newGift ? 'gift' : quotaSummary.suggestedAutoBucket;
        final tx = PurchaseTransaction(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          volumeId: volume.id,
          purchaseDate: DateTime.now(),
          quotaBucket: bucket,
          price: 0.0,
          notes: 'Quick toggled ownership',
        );
        await _ref.read(transactionRepositoryProvider).save(tx);
        _ref.read(transactionsNotifierProvider.notifier).load();
      }
    } else {
      // If unowning, remove transaction
      await _ref.read(transactionRepositoryProvider).deleteByVolumeId(volume.id);
      _ref.read(transactionsNotifierProvider.notifier).load();
    }
  }
}

final volumesNotifierProvider = StateNotifierProvider<VolumesNotifier, List<Volume>>((ref) {
  return VolumesNotifier(ref);
});

// StateNotifier for Transactions
class TransactionsNotifier extends StateNotifier<List<PurchaseTransaction>> {
  final Ref _ref;
  TransactionsNotifier(this._ref) : super([]) {
    load();
  }

  void load() {
    state = _ref.read(transactionRepositoryProvider).getAll();
  }

  Future<void> saveTransaction(PurchaseTransaction tx) async {
    await _ref.read(transactionRepositoryProvider).save(tx);
    load();
  }

  Future<void> deleteTransaction(String id) async {
    await _ref.read(transactionRepositoryProvider).delete(id);
    load();
  }
}

final transactionsNotifierProvider = StateNotifierProvider<TransactionsNotifier, List<PurchaseTransaction>>((ref) {
  return TransactionsNotifier(ref);
});

// Derived Providers
final activeSeriesProvider = Provider<List<Series>>((ref) {
  final all = ref.watch(seriesNotifierProvider);
  return all.where((s) => s.status == 'active').toList();
});

final wishlistSeriesProvider = Provider<List<Series>>((ref) {
  final all = ref.watch(seriesNotifierProvider);
  return all.where((s) => s.status == 'wishlist').toList();
});

final completedSeriesProvider = Provider<List<Series>>((ref) {
  final all = ref.watch(seriesNotifierProvider);
  return all.where((s) => s.status == 'completed').toList();
});

class SeriesStats {
  final int totalReleased;
  final int totalOwned;
  final int totalAnnounced;
  final double completionPercentage;
  final Volume? nextMissingVolume;

  SeriesStats({
    required this.totalReleased,
    required this.totalOwned,
    required this.totalAnnounced,
    required this.completionPercentage,
    this.nextMissingVolume,
  });
}

final seriesStatsProvider = Provider.family<SeriesStats, String>((ref, seriesId) {
  final allVolumes = ref.watch(volumesNotifierProvider).where((v) => v.seriesId == seriesId).toList()
    ..sort((a, b) => a.volumeNumber.compareTo(b.volumeNumber));

  final now = DateTime.now();
  final released = allVolumes.where((v) => v.isReleased(now)).toList();
  final owned = allVolumes.where((v) => v.isOwned).toList();
  final announced = allVolumes.where((v) => v.isUpcoming(now)).toList();
  final missing = released.where((v) => !v.isOwned && v.availability == 'available').toList();

  final completion = released.isEmpty ? (owned.isNotEmpty ? 1.0 : 0.0) : (owned.length / released.length);

  return SeriesStats(
    totalReleased: released.length,
    totalOwned: owned.length,
    totalAnnounced: announced.length,
    completionPercentage: completion,
    nextMissingVolume: missing.isNotEmpty ? missing.first : null,
  );
});

class DashboardHeaderMetrics {
  final int totalOwned;
  final int totalBought;
  final int totalGifted;
  final int activeSeriesCount;
  final int totalSeriesCount;
  final double totalSpent;

  DashboardHeaderMetrics({
    required this.totalOwned,
    required this.totalBought,
    required this.totalGifted,
    required this.activeSeriesCount,
    required this.totalSeriesCount,
    required this.totalSpent,
  });
}

final dashboardMetricsProvider = Provider<DashboardHeaderMetrics>((ref) {
  final volumes = ref.watch(volumesNotifierProvider);
  final series = ref.watch(seriesNotifierProvider);
  final transactions = ref.watch(transactionsNotifierProvider);

  final totalOwned = volumes.where((v) => v.isOwned).length;
  final totalGifted = volumes.where((v) => v.isOwned && v.isGift).length;
  final totalBought = totalOwned - totalGifted;
  final activeSeriesCount = series.where((s) => s.status == 'active').length;
  final totalSeriesCount = series.length;
  final totalSpent = transactions.fold<double>(0.0, (acc, t) => acc + t.price);

  return DashboardHeaderMetrics(
    totalOwned: totalOwned,
    totalBought: totalBought,
    totalGifted: totalGifted,
    activeSeriesCount: activeSeriesCount,
    totalSeriesCount: totalSeriesCount,
    totalSpent: totalSpent,
  );
});
