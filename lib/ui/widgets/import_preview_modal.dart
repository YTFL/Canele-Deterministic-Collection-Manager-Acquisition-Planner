import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/uuid_generator.dart';
import '../../models/import_item.dart';
import '../../models/series.dart';
import '../../models/volume.dart';
import '../../models/purchase_transaction.dart';
import '../../providers/series_provider.dart';
import '../../providers/quota_provider.dart';
import '../../services/backup_service.dart';
import 'canele_card.dart';

class ImportPreviewModal extends ConsumerStatefulWidget {
  final List<ImportItem> items;
  final String sourceName;

  const ImportPreviewModal({
    super.key,
    required this.items,
    required this.sourceName,
  });

  @override
  ConsumerState<ImportPreviewModal> createState() => _ImportPreviewModalState();
}

class _ImportPreviewModalState extends ConsumerState<ImportPreviewModal> {
  late List<ImportItem> _items;
  bool _isCommitting = false;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.items);
  }

  Map<String, List<ImportItem>> get _groupedItems {
    final map = <String, List<ImportItem>>{};
    for (final item in _items) {
      map.putIfAbsent(item.seriesTitle, () => []).add(item);
    }
    return map;
  }

  int get _selectedCount => _items.where((i) => i.isSelected).length;

  Future<void> _commitImport() async {
    final selected = _items.where((i) => i.isSelected).toList();
    if (selected.isEmpty) return;

    setState(() => _isCommitting = true);

    // Pause backup service during batch commit
    BackupService.instance.pauseListening();

    try {
      final existingSeries = ref.read(seriesNotifierProvider);
      final existingVolumes = ref.read(volumesNotifierProvider);
      final quotaSummary = ref.read(quotaProvider);

      int seriesCreated = 0;
      int volumesCreated = 0;

      final grouped = <String, List<ImportItem>>{};
      for (final item in selected) {
        grouped.putIfAbsent(item.seriesTitle, () => []).add(item);
      }

      for (final entry in grouped.entries) {
        final sTitle = entry.key;
        final vItems = entry.value;

        // Find existing series by title
        Series? targetSeries;
        for (final s in existingSeries) {
          if (s.title.toLowerCase() == sTitle.toLowerCase()) {
            targetSeries = s;
            break;
          }
        }

        if (targetSeries == null) {
          targetSeries = Series(
            id: UuidGenerator.generate(),
            title: sTitle,
            type: vItems.first.type,
            status: vItems.first.status,
            tags: vItems.first.tags,
          );
          await ref.read(seriesNotifierProvider.notifier).saveSeries(targetSeries);
          seriesCreated++;
        }

        // Add volumes
        final newVolumes = <Volume>[];
        for (final vItem in vItems) {
          // Check if volume already exists in this series
          final alreadyExists = existingVolumes.any(
            (v) => v.seriesId == targetSeries!.id && v.volumeNumber == vItem.volumeNumber,
          );

          if (alreadyExists) continue;

          final volId = UuidGenerator.generate();
          final vol = Volume(
            id: volId,
            seriesId: targetSeries.id,
            volumeNumber: vItem.volumeNumber,
            releaseDate: vItem.releaseOrPurchaseDate ?? DateTime.now(),
            isOwned: vItem.isOwned,
            isGift: vItem.isGift,
            availability: vItem.availability,
          );
          newVolumes.add(vol);
          volumesCreated++;

          if (vItem.isOwned) {
            final tx = PurchaseTransaction(
              id: UuidGenerator.generate(),
              volumeId: volId,
              purchaseDate: vItem.releaseOrPurchaseDate ?? DateTime.now(),
              quotaBucket: vItem.isGift ? 'gift' : quotaSummary.suggestedAutoBucket,
              price: vItem.price,
              notes: 'Imported from ${widget.sourceName}',
            );
            await ref.read(transactionsNotifierProvider.notifier).saveTransaction(tx);
          }
        }

        if (newVolumes.isNotEmpty) {
          await ref.read(volumesNotifierProvider.notifier).saveBatch(newVolumes);
        }
      }

      ref.read(seriesNotifierProvider.notifier).load();
      ref.read(volumesNotifierProvider.notifier).load();
      ref.read(transactionsNotifierProvider.notifier).load();

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
          SnackBar(
            content: Text(
              'Imported $volumesCreated volumes across $seriesCreated new series successfully!',
            ),
            backgroundColor: AppColors.statusSuccess,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: AppColors.statusDanger,
          ),
        );
      }
    } finally {
      BackupService.instance.resumeListening();
      if (mounted) setState(() => _isCommitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final grouped = _groupedItems;
    final existingSeries = ref.watch(seriesNotifierProvider);
    final existingTitles = existingSeries.map((s) => s.title.toLowerCase()).toSet();

    return Scaffold(
      appBar: AppBar(
        title: Text('Import Preview (${widget.sourceName})'),
        actions: [
          TextButton(
            onPressed: () {
              final allSelected = _selectedCount == _items.length;
              setState(() {
                for (final item in _items) {
                  item.isSelected = !allSelected;
                }
              });
            },
            child: Text(
              _selectedCount == _items.length ? 'Deselect All' : 'Select All',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: isDark ? AppColors.darkPastryCardElevated : AppColors.pastryCrustLight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$_selectedCount of ${_items.length} volumes selected',
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  '${grouped.length} series detected',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),

          // Series / Volume List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: grouped.length,
              itemBuilder: (context, index) {
                final sTitle = grouped.keys.elementAt(index);
                final sItems = grouped[sTitle]!;
                final isExisting = existingTitles.contains(sTitle.toLowerCase());

                return CaneleCard(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              sTitle,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isExisting
                                  ? (isDark ? AppColors.darkPastryCardElevated : AppColors.pastryCrustLight)
                                  : (isDark ? AppColors.caramelizedAmber.withValues(alpha: 0.2) : AppColors.warmPastryCrust.withValues(alpha: 0.6)),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: isExisting
                                    ? (isDark ? AppColors.darkPastryBorder : AppColors.pastryCrustBorder)
                                    : (isDark ? AppColors.caramelizedAmberLight.withValues(alpha: 0.4) : AppColors.pastryCrustBorder),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              isExisting ? 'MATCHED EXISTING' : 'NEW SERIES',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: isExisting
                                    ? (isDark ? AppColors.darkTextMuted : AppColors.deepCaramelMuted)
                                    : (isDark ? AppColors.caramelizedAmberLight : AppColors.caramelizedAmber),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: sItems.map((item) {
                          return FilterChip(
                            label: Text(
                              'Vol. ${DateFormatter.formatVolumeNumber(item.volumeNumber)} (${item.isOwned ? 'Owned' : 'Wishlist'})',
                            ),
                            selected: item.isSelected,
                            showCheckmark: false,
                            selectedColor: AppColors.caramelizedAmber.withValues(alpha: 0.2),
                            onSelected: (val) {
                              setState(() {
                                item.isSelected = val;
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Bottom Commit Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkPastryCard : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.darkPastryBorder : AppColors.pastryCrustBorder,
                ),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (_selectedCount > 0 && !_isCommitting) ? _commitImport : null,
                icon: _isCommitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.library_add_check_rounded, size: 20),
                label: Text(
                  _isCommitting
                      ? 'Importing...'
                      : 'Import $_selectedCount Volumes into Library',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
