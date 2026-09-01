import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:canele/core/database/hive_boxes.dart';
import 'package:canele/repositories/series_repository.dart';
import 'package:canele/repositories/transaction_repository.dart';
import 'package:canele/repositories/volume_repository.dart';
import 'package:canele/services/series_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late SeriesRepository seriesRepo;
  late VolumeRepository volumeRepo;
  late TransactionRepository txRepo;
  late SeriesService seriesService;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('canele_series_service_test_');
    await HiveBoxes.init(tempDir.path);
    seriesRepo = SeriesRepository();
    volumeRepo = VolumeRepository();
    txRepo = TransactionRepository();
    seriesService = SeriesService(
      seriesRepository: seriesRepo,
      volumeRepository: volumeRepo,
      transactionRepository: txRepo,
    );
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('SeriesService Auto-Generation Tests', () {
    test('Auto-generates 12 volumes and marks 1 to 8 as owned', () async {
      final series = await seriesService.createSeriesWithVolumes(
        title: '86 - Eighty-Six',
        type: 'lightNovel',
        totalReleasedVolumes: 12,
        ownedCount: 8,
        markOwned: true,
      );

      expect(series.title, '86 - Eighty-Six');
      expect(series.totalVolumesReleased, 12);

      final volumes = volumeRepo.getBySeriesId(series.id);
      expect(volumes.length, 12);

      // Verify numbers 1 to 12
      for (int i = 0; i < 12; i++) {
        expect(volumes[i].volumeNumber, (i + 1).toDouble());
        if (i < 8) {
          expect(volumes[i].isOwned, isTrue, reason: 'Vol ${i + 1} should be owned');
        } else {
          expect(volumes[i].isOwned, isFalse, reason: 'Vol ${i + 1} should not be owned');
          expect(volumes[i].availability, 'available');
        }
      }
    });

    test('Standalone / Single series generates exactly 1 volume', () async {
      final single = await seriesService.createSeriesWithVolumes(
        title: 'The Alchemist',
        type: 'book',
        totalReleasedVolumes: 1,
        ownedCount: 1,
        markOwned: true,
      );

      final volumes = volumeRepo.getBySeriesId(single.id);
      expect(volumes.length, 1);
      expect(volumes.first.volumeNumber, 1.0);
      expect(volumes.first.isOwned, isTrue);
      expect(volumes.first.availability, 'available');
    });

    test('Generates all unowned volumes when owned count is 0', () async {
      final series = await seriesService.createSeriesWithVolumes(
        title: 'Frieren: Beyond Journey\'s End',
        type: 'manga',
        totalReleasedVolumes: 10,
        ownedCount: 0,
        markOwned: false,
      );

      final volumes = volumeRepo.getBySeriesId(series.id);
      expect(volumes.length, 10);
      for (final v in volumes) {
        expect(v.isOwned, isFalse);
        expect(v.availability, 'available');
      }
    });

    test('Automatically marks 100% of volumes as purchased when series collectionStatus is completed', () async {
      final series = await seriesService.createSeriesWithVolumes(
        title: 'Fullmetal Alchemist',
        type: 'manga',
        collectionStatus: 'completed',
        totalReleasedVolumes: 27,
        ownedCount: 0,
        markOwned: false,
      );

      expect(series.collectionStatus, 'completed');
      expect(series.releaseStatus, 'completed');

      final volumes = volumeRepo.getBySeriesId(series.id);
      expect(volumes.length, 27);
      for (final v in volumes) {
        expect(v.isOwned, isTrue, reason: 'Vol ${v.volumeNumber} must be owned');
        expect(v.isGift, isFalse, reason: 'Vol ${v.volumeNumber} should default to purchased');
      }

      final txs = txRepo.getAll();
      expect(txs.length, 27);
      for (final t in txs) {
        expect(t.quotaBucket, 'regular');
      }
    });
  });
}
