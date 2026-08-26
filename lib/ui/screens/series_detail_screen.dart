import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/type_helper.dart';
import '../../core/utils/uuid_generator.dart';
import '../../models/series.dart';
import '../../models/volume.dart';
import '../../models/purchase_transaction.dart';
import '../../providers/series_provider.dart';
import '../widgets/canele_card.dart';
import '../widgets/canele_progress_bar.dart';
import '../widgets/volume_checklist_tile.dart';
import '../widgets/log_transaction_sheet.dart';

class SeriesDetailScreen extends ConsumerStatefulWidget {
  final String seriesId;

  const SeriesDetailScreen({super.key, required this.seriesId});

  @override
  ConsumerState<SeriesDetailScreen> createState() => _SeriesDetailScreenState();
}

class _SeriesDetailScreenState extends ConsumerState<SeriesDetailScreen> {
  String _volumeFilter = 'all'; // all, missing, owned

  void _showAddVolumeDialog(BuildContext context, {Volume? existingVolume}) {
    final isEditing = existingVolume != null;
    String defaultVolNum = '1';
    if (!isEditing) {
      final currentVolumes = ref
          .read(volumesNotifierProvider)
          .where((v) => v.seriesId == widget.seriesId)
          .toList();
      if (currentVolumes.isNotEmpty) {
        final maxVol = currentVolumes
            .map((v) => v.volumeNumber)
            .reduce((a, b) => a > b ? a : b);
        final nextVol = maxVol + 1.0;
        defaultVolNum = DateFormatter.formatVolumeNumber(nextVol);
      }
    }

    final volNumController = TextEditingController(
      text: isEditing
          ? DateFormatter.formatVolumeNumber(existingVolume.volumeNumber)
          : defaultVolNum,
    );
    DateTime? releaseDate = isEditing ? existingVolume.releaseDate : null;
    String availability = isEditing ? existingVolume.availability : 'available';
    bool isWatchlist = isEditing ? existingVolume.isRestockedWatchlist : false;
    bool isOwned = isEditing ? existingVolume.isOwned : false;
    bool isGift = isEditing ? existingVolume.isGift : false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit Volume' : 'Add New Volume'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Volume Number (Decimal supported)
                    Text('Volume Number', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 4),
                    TextField(
                      controller: volNumController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        hintText: 'e.g. 12 or 11.5 for side stories',
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Availability Status
                    Text('Availability State', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      initialValue: availability,
                      items: const [
                        DropdownMenuItem(value: 'available', child: Text('Available')),
                        DropdownMenuItem(value: 'outOfStock', child: Text('Out of Stock')),
                        DropdownMenuItem(value: 'outOfPrint', child: Text('Out of Print')),
                        DropdownMenuItem(value: 'announced', child: Text('Announced / Unreleased')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            availability = val;
                            if (val == 'outOfStock' || val == 'outOfPrint' || val == 'announced') {
                              isWatchlist = true;
                            }
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // Upcoming Release Date (Optional)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Upcoming Release Date', style: Theme.of(context).textTheme.titleSmall),
                        Text(
                          releaseDate == null
                              ? '(Not Set / Released)'
                              : (releaseDate!.isAfter(DateTime.now()) ? '(Future / Announced)' : '(Released)'),
                          style: TextStyle(
                            fontSize: 11,
                            color: releaseDate != null && releaseDate!.isAfter(DateTime.now())
                                ? AppColors.caramelizedAmber
                                : AppColors.deepCaramelMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (releaseDate == null)
                      OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now().add(const Duration(days: 30)),
                            firstDate: DateTime(1970),
                            lastDate: DateTime.now().add(const Duration(days: 1825)),
                          );
                          if (picked != null) {
                            setDialogState(() {
                              releaseDate = picked;
                              if (picked.isAfter(DateTime.now())) {
                                availability = 'announced';
                                isWatchlist = true;
                              }
                            });
                          }
                        },
                        icon: const Icon(Icons.calendar_month_rounded, size: 16),
                        label: const Text('Set Upcoming Release Date'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.caramelizedAmber),
                          color: AppColors.caramelizedAmber.withValues(alpha: 0.08),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: releaseDate!,
                                  firstDate: DateTime(1970),
                                  lastDate: DateTime.now().add(const Duration(days: 1825)),
                                );
                                if (picked != null) {
                                  setDialogState(() {
                                    releaseDate = picked;
                                    if (picked.isAfter(DateTime.now())) {
                                      availability = 'announced';
                                      isWatchlist = true;
                                    }
                                  });
                                }
                              },
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.caramelizedAmber),
                                  const SizedBox(width: 8),
                                  Text(
                                    DateFormatter.formatDisplay(releaseDate!),
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.close_rounded, size: 18),
                              tooltip: 'Clear Release Date',
                              onPressed: () => setDialogState(() {
                                releaseDate = null;
                                if (availability == 'announced') {
                                  availability = 'available';
                                }
                              }),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),

                    // Restock Watchlist Checkbox
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Restock Watchlist Priority'),
                      subtitle: const Text('Track and prioritize on the dashboard'),
                      value: isWatchlist,
                      onChanged: (val) => setDialogState(() => isWatchlist = val),
                    ),

                    if (isEditing) ...[
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Owned'),
                        value: isOwned,
                        onChanged: (val) => setDialogState(() => isOwned = val),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final numVal = double.tryParse(volNumController.text.trim());
                    if (numVal == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a valid volume number')),
                      );
                      return;
                    }

                    final volume = Volume(
                      id: isEditing ? existingVolume.id : UuidGenerator.generate(),
                      seriesId: widget.seriesId,
                      volumeNumber: numVal,
                      releaseDate: releaseDate,
                      availability: availability,
                      isRestockedWatchlist: isWatchlist,
                      isOwned: isOwned,
                      isGift: isGift,
                    );

                    await ref.read(volumesNotifierProvider.notifier).saveVolume(volume);
                    if (ctx.mounted) Navigator.of(ctx).pop();
                  },
                  child: Text(isEditing ? 'Save' : 'Add Volume'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showBatchAddDialog(BuildContext context) {
    final currentVolumes = ref
        .read(volumesNotifierProvider)
        .where((v) => v.seriesId == widget.seriesId)
        .toList();
    int defaultStart = 1;
    if (currentVolumes.isNotEmpty) {
      final maxVol = currentVolumes
          .map((v) => v.volumeNumber)
          .reduce((a, b) => a > b ? a : b);
      defaultStart = (maxVol + 1.0).toInt();
    }
    final defaultEnd = defaultStart + 9;

    final startController = TextEditingController(text: '$defaultStart');
    final endController = TextEditingController(text: '$defaultEnd');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Batch Add Volumes'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: startController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Start Volume Number'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: endController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'End Volume Number'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final start = int.tryParse(startController.text) ?? 1;
                final end = int.tryParse(endController.text) ?? 1;
                if (start <= end) {
                  final newVolumes = <Volume>[];
                  for (int i = start; i <= end; i++) {
                    newVolumes.add(Volume(
                      id: UuidGenerator.generate(),
                      seriesId: widget.seriesId,
                      volumeNumber: i.toDouble(),
                      releaseDate: null,
                      availability: 'available',
                      isOwned: false,
                    ));
                  }
                  await ref.read(volumesNotifierProvider.notifier).saveBatch(newVolumes);
                }
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: const Text('Create Volumes'),
            ),
          ],
        );
      },
    );
  }

  Future<String?> _showAddCustomTypeDialog(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Custom Book Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter custom book format / type name:'),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'e.g. Manhwa, Webtoon, Artbook',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                Navigator.pop(ctx, TypeHelper.formatTypeLabel(text));
              }
            },
            child: const Text('Add Type'),
          ),
        ],
      ),
    );
  }

  void _showEditSeriesDialog(BuildContext context, Series series) {
    final titleController = TextEditingController(text: series.title);
    final allSeries = ref.read(seriesNotifierProvider);
    final availableTypes = TypeHelper.getAllAvailableTypes(allSeries.map((s) => s.type));
    String type = TypeHelper.formatTypeLabel(series.type);
    String status = series.collectionStatus;
    String releaseStatus = series.releaseStatus;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            if (!availableTypes.contains(type)) {
              availableTypes.add(type);
            }

            return AlertDialog(
              title: const Text('Edit Series'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Title', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 4),
                    TextField(controller: titleController),
                    const SizedBox(height: 12),

                    Text('Type', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      initialValue: type,
                      items: [
                        ...availableTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))),
                        const DropdownMenuItem(
                          value: '__ADD_NEW__',
                          child: Row(
                            children: [
                              Icon(Icons.add_rounded, size: 16, color: AppColors.caramelizedAmber),
                              SizedBox(width: 4),
                              Text('+ Add New Type...', style: TextStyle(color: AppColors.caramelizedAmber, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (val) async {
                        if (val == '__ADD_NEW__') {
                          final custom = await _showAddCustomTypeDialog(context);
                          if (custom != null && custom.isNotEmpty) {
                            setDialogState(() {
                              if (!availableTypes.contains(custom)) {
                                availableTypes.add(custom);
                              }
                              type = custom;
                            });
                          }
                        } else if (val != null) {
                          setDialogState(() => type = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    Text('Collection Status', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      initialValue: status,
                      items: const [
                        DropdownMenuItem(value: 'active', child: Text('Active')),
                        DropdownMenuItem(value: 'wishlist', child: Text('Wishlist')),
                        DropdownMenuItem(value: 'completed', child: Text('Completed')),
                        DropdownMenuItem(value: 'dropped', child: Text('Dropped')),
                      ],
                      onChanged: (val) => setDialogState(() => status = val!),
                    ),
                    const SizedBox(height: 12),

                    Text('Release Status', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      initialValue: releaseStatus,
                      items: const [
                        DropdownMenuItem(value: 'ongoing', child: Text('Ongoing')),
                        DropdownMenuItem(value: 'completed', child: Text('Completed')),
                      ],
                      onChanged: (val) => setDialogState(() => releaseStatus = val!),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final updated = series.copyWith(
                      title: titleController.text.trim(),
                      type: TypeHelper.normalizeKey(type),
                      collectionStatus: status,
                      releaseStatus: releaseStatus,
                    );

                    await ref.read(seriesNotifierProvider.notifier).saveSeries(updated);
                    if (ctx.mounted) Navigator.of(ctx).pop();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final allSeries = ref.watch(seriesNotifierProvider);
    final series = allSeries.cast<Series?>().firstWhere(
          (s) => s?.id == widget.seriesId,
          orElse: () => null,
        );

    if (series == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Series Details')),
        body: const Center(child: Text('Series not found')),
      );
    }

    final stats = ref.watch(seriesStatsProvider(series.id));
    final allVolumes = ref.watch(volumesNotifierProvider).where((v) => v.seriesId == series.id).toList()
      ..sort((a, b) => a.volumeNumber.compareTo(b.volumeNumber));
    final allTransactions = ref.watch(transactionsNotifierProvider);

    // Apply Filter
    final filteredVolumes = allVolumes.where((v) {
      if (_volumeFilter == 'missing') return !v.isOwned;
      if (_volumeFilter == 'owned') return v.isOwned;
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(series.title),
        actions: [
          IconButton(
            onPressed: () => _showEditSeriesDialog(context, series),
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Series',
          ),
          PopupMenuButton<String>(
            onSelected: (val) async {
              if (val == 'delete') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Series?'),
                    content: Text('Are you sure you want to delete "${series.title}" and all its volumes?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusDanger),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await ref.read(seriesNotifierProvider.notifier).deleteSeries(series.id);
                  if (context.mounted) Navigator.of(context).pop();
                }
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: AppColors.statusDanger),
                    SizedBox(width: 8),
                    Text('Delete Series', style: TextStyle(color: AppColors.statusDanger)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Series Summary Card
            CaneleCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.caramelizedAmber.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          series.type.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.caramelizedAmber,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: series.status == 'active'
                              ? (isDark ? AppColors.darkPastryCardElevated : AppColors.warmPastryCrust.withValues(alpha: 0.6))
                              : (isDark ? AppColors.darkPastryCardElevated : AppColors.pastryCrustLight),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: series.status == 'active'
                                ? (isDark ? AppColors.caramelizedAmberLight.withValues(alpha: 0.4) : AppColors.pastryCrustBorder)
                                : (isDark ? AppColors.darkPastryBorder : AppColors.pastryCrustBorder),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          series.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: series.status == 'active'
                                ? (isDark ? AppColors.caramelizedAmberLight : AppColors.caramelizedAmber)
                                : (isDark ? AppColors.darkTextMuted : AppColors.deepCaramelMuted),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Progress Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Collection Progress', style: theme.textTheme.bodySmall),
                      Text(
                        '${stats.totalOwned} of ${stats.totalReleased} Released Owned',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.caramelizedAmber,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  CaneleProgressBar(
                    value: stats.completionPercentage,
                    height: 10,
                    showPercentage: true,
                  ),

                  if (stats.totalAnnounced > 0) ...[
                    const SizedBox(height: 6),
                    Text(
                      '+${stats.totalAnnounced} announced future volumes',
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Action Buttons (Add Volume & Batch Add)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showAddVolumeDialog(context),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add Volume'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showBatchAddDialog(context),
                    icon: const Icon(Icons.playlist_add_rounded, size: 18),
                    label: const Text('Batch Add'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Volume Checklist Header & Filter
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Volumes (${filteredVolumes.length})',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                SegmentedButton<String>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: 'all', label: Text('All')),
                    ButtonSegment(value: 'missing', label: Text('Missing')),
                    ButtonSegment(value: 'owned', label: Text('Owned')),
                  ],
                  selected: {_volumeFilter},
                  onSelectionChanged: (set) => setState(() => _volumeFilter = set.first),
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Volume List
            if (filteredVolumes.isEmpty)
              CaneleCard(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'No volumes match this filter.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              )
            else
              ...filteredVolumes.map((vol) {
                final tx = allTransactions.cast<PurchaseTransaction?>().firstWhere(
                      (t) => t?.volumeId == vol.id,
                      orElse: () => null,
                    );
                return VolumeChecklistTile(
                  volume: vol,
                  transaction: tx,
                  onToggleOwned: (val) {
                    if (val) {
                      LogTransactionSheet.show(context, series: series, volume: vol);
                    } else {
                      ref.read(volumesNotifierProvider.notifier).toggleOwned(vol);
                    }
                  },
                  onToggleWatchlist: (val) {
                    final updated = vol.copyWith(isRestockedWatchlist: val);
                    ref.read(volumesNotifierProvider.notifier).saveVolume(updated);
                  },
                  onEdit: () => _showAddVolumeDialog(context, existingVolume: vol),
                  onDelete: () async {
                    await ref.read(volumesNotifierProvider.notifier).deleteVolume(vol.id);
                  },
                );
              }),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
