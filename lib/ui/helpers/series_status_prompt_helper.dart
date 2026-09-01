import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../models/series.dart';
import '../../providers/series_provider.dart';

class SeriesStatusPromptHelper {
  /// Checks whether a series qualifies for status transitions and prompts the user:
  /// 1. Wishlist -> Active: when any volume in a wishlist series is obtained.
  /// 2. Active -> Completed: when a series has releaseStatus == 'completed' and all volumes are owned.
  static Future<void> checkAndPrompt(
    BuildContext context, {
    required String seriesId,
    WidgetRef? ref,
  }) async {
    if (!context.mounted) return;

    final container = ref == null ? ProviderScope.containerOf(context, listen: false) : null;
    final allSeries = ref != null
        ? ref.read(seriesNotifierProvider)
        : container!.read(seriesNotifierProvider);

    var series = allSeries.cast<Series?>().firstWhere(
          (s) => s?.id == seriesId,
          orElse: () => null,
        );
    if (series == null) return;

    final allVolumes = ref != null
        ? ref.read(volumesNotifierProvider)
        : container!.read(volumesNotifierProvider);

    final seriesVolumes = allVolumes.where((v) => v.seriesId == seriesId).toList();

    // 1. Wishlist -> Active prompt
    if (series.collectionStatus == 'wishlist') {
      final hasOwnedVolume = seriesVolumes.any((v) => v.isOwned);
      if (hasOwnedVolume) {
        final shouldMoveToActive = await showMoveToActiveDialog(context, series: series);
        if (shouldMoveToActive == true && context.mounted) {
          series = series.copyWith(collectionStatus: 'active');
          if (ref != null) {
            await ref.read(seriesNotifierProvider.notifier).saveSeries(series);
          } else {
            await container!.read(seriesNotifierProvider.notifier).saveSeries(series);
          }
          if (context.mounted) {
            ScaffoldMessenger.of(context)
              ..clearSnackBars()
              ..showSnackBar(
              SnackBar(
                content: Text('Moved "${series.title}" to Active collection!'),
                backgroundColor: AppColors.caramelizedAmber,
              ),
            );
          }
        }
      }
    }

    // 2. Active -> Completed prompt
    if (series.collectionStatus == 'active' && series.releaseStatus == 'completed') {
      final allOwned = seriesVolumes.isNotEmpty && seriesVolumes.every((v) => v.isOwned);
      if (allOwned && context.mounted) {
        final shouldMoveToCompleted = await showMoveToCompletedDialog(context, series: series);
        if (shouldMoveToCompleted == true && context.mounted) {
          series = series.copyWith(collectionStatus: 'completed');
          if (ref != null) {
            await ref.read(seriesNotifierProvider.notifier).saveSeries(series);
          } else {
            await container!.read(seriesNotifierProvider.notifier).saveSeries(series);
          }
          if (context.mounted) {
            ScaffoldMessenger.of(context)
              ..clearSnackBars()
              ..showSnackBar(
              SnackBar(
                content: Text('Moved "${series.title}" to Completed!'),
                backgroundColor: AppColors.caramelizedAmber,
              ),
            );
          }
        }
      }
    }
  }

  /// Dialog asking if user wants to move a Wishlist series to Active
  static Future<bool?> showMoveToActiveDialog(
    BuildContext context, {
    required Series series,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.collections_bookmark_rounded,
              color: isDark ? AppColors.caramelizedAmberLight : AppColors.caramelizedAmber,
              size: 24,
            ),
            const SizedBox(width: 10),
            const Expanded(child: Text('Move to Active?')),
          ],
        ),
        content: Text(
          'You marked a book in "${series.title}" as obtained. Would you like to move this series from Wishlist to Active?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep in Wishlist'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Move to Active'),
          ),
        ],
      ),
    );
  }

  /// Dialog asking if user wants to move an Active completed-release series to Completed
  static Future<bool?> showMoveToCompletedDialog(
    BuildContext context, {
    required Series series,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.check_circle_rounded,
              color: isDark ? AppColors.caramelizedAmberLight : AppColors.caramelizedAmber,
              size: 24,
            ),
            const SizedBox(width: 10),
            const Expanded(child: Text('Move to Completed?')),
          ],
        ),
        content: Text(
          'You have obtained all releases for "${series.title}" and the series is marked as completed in releases. Would you like to move this series from Active to Completed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep Active'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Move to Completed'),
          ),
        ],
      ),
    );
  }
}
