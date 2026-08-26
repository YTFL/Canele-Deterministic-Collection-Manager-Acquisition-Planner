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
import '../widgets/canele_card.dart';

class ImportReviewScreen extends ConsumerStatefulWidget {
  final List<ImportItem> initialItems;
  final String sourceName;

  const ImportReviewScreen({
    super.key,
    required this.initialItems,
    required this.sourceName,
  });

  @override
  ConsumerState<ImportReviewScreen> createState() => _ImportReviewScreenState();
}

class _ImportReviewScreenState extends ConsumerState<ImportReviewScreen> {
  late List<ImportItem> _items;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.initialItems);
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
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No items selected for import.')),
      );
      return;
    }

    final existingSeries = ref.read(seriesNotifierProvider);
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

      // Check if series already exists
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

      // Add Volumes
      final newVolumes = <Volume>[];
      for (final vItem in vItems) {
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

        // If owned, record a transaction
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

      await ref.read(volumesNotifierProvider.notifier).saveBatch(newVolumes);
    }

    ref.read(seriesNotifierProvider.notifier).load();
    ref.read(volumesNotifierProvider.notifier).load();
    ref.read(transactionsNotifierProvider.notifier).load();

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Import complete: $volumesCreated volumes across $seriesCreated new series!',
          ),
        ),
      );
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
        title: Text('Review Import (${widget.sourceName})'),
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
            child: Text(_selectedCount == _items.length ? 'Deselect All' : 'Select All'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header summary banner
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

          // Series and volumes list
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
                      // Series Title Header
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
                          if (isExisting)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkPastryCardElevated : AppColors.pastryCrustLight,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: isDark ? AppColors.darkPastryBorder : AppColors.pastryCrustBorder,
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                'EXISTING SERIES',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? AppColors.darkTextMuted : AppColors.deepCaramelMuted,
                                ),
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkPastryCardElevated : AppColors.warmPastryCrust.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: isDark ? AppColors.caramelizedAmberLight.withValues(alpha: 0.4) : AppColors.pastryCrustBorder,
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                'NEW SERIES',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? AppColors.caramelizedAmberLight : AppColors.caramelizedAmber,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Volume chips list
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

          // Bottom Commit Button
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
              child: ElevatedButton(
                onPressed: _selectedCount > 0 ? _commitImport : null,
                child: Text('Import $_selectedCount Volumes into Library'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
