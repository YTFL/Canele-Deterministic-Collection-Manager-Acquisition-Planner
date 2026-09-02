import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_helper.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/type_helper.dart';
import '../../core/utils/uuid_generator.dart';
import '../../models/series.dart';
import '../../models/volume.dart';
import '../../models/purchase_transaction.dart';
import '../../providers/database_provider.dart';
import '../../providers/quota_provider.dart';
import '../../providers/series_provider.dart';
import '../widgets/canele_card.dart';
import '../widgets/canele_progress_bar.dart';
import '../widgets/volume_checklist_tile.dart';
import '../widgets/log_transaction_sheet.dart';
import '../helpers/series_status_prompt_helper.dart';

class SeriesDetailScreen extends ConsumerStatefulWidget {
  final String seriesId;

  const SeriesDetailScreen({super.key, required this.seriesId});

  @override
  ConsumerState<SeriesDetailScreen> createState() => _SeriesDetailScreenState();
}

class _SeriesDetailScreenState extends ConsumerState<SeriesDetailScreen> {
  String _volumeFilter = 'all'; // all, missing, owned

  void _showAddVolumeDialog({Volume? existingVolume}) async {
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
    final priceController = TextEditingController(
      text: (isEditing && existingVolume.price != null && existingVolume.price! > 0)
          ? existingVolume.price!.toStringAsFixed(
              existingVolume.price! == existingVolume.price!.roundToDouble() ? 0 : 2,
            )
          : '',
    );
    final allSeriesList = ref.read(seriesNotifierProvider);
    final currentSeries = allSeriesList.cast<Series?>().firstWhere(
          (s) => s?.id == widget.seriesId,
          orElse: () => null,
        );

    final defPrice = currentSeries?.defaultVolumePrice ?? CurrencyHelper.defaultVolumePrice;
    final defCurrency = currentSeries?.defaultVolumeCurrency ?? currentSeries?.currency ?? CurrencyHelper.defaultVolumeCurrency;
    final formattedDefaultPrice = CurrencyHelper.format(defPrice, currencyCode: defCurrency);

    String selectedCurrency = (isEditing && existingVolume.currency != null)
        ? existingVolume.currency!
        : defCurrency;
    DateTime? releaseDate = isEditing ? existingVolume.releaseDate : null;
    String availability = isEditing ? existingVolume.availability : 'available';
    bool isWatchlist = isEditing ? existingVolume.isRestockedWatchlist : false;
    bool isOwned = isEditing ? existingVolume.isOwned : false;
    bool isGift = isEditing ? existingVolume.isGift : false;

    final saved = await showDialog<bool>(
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

                    // Price / Cost (Optional)
                    Text('Price (Optional)', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: priceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              hintText: '0.00 ($formattedDefaultPrice)',
                              prefixIcon: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                child: CurrencySymbolText(
                                  currencyCode: selectedCurrency,
                                  baseFontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: CurrencyDropdownField(
                            value: selectedCurrency,
                            onChanged: (val) {
                              if (val != null) {
                                setDialogState(() => selectedCurrency = val);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Series default ($formattedDefaultPrice) will apply if left blank',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
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
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final numVal = double.tryParse(volNumController.text.trim());
                    if (numVal == null) {
                      ScaffoldMessenger.of(context)
                        ..clearSnackBars()
                        ..showSnackBar(
                        const SnackBar(content: Text('Please enter a valid volume number')),
                      );
                      return;
                    }

                    final priceVal = CurrencyHelper.parsePrice(priceController.text.trim());

                    final volume = Volume(
                      id: isEditing ? existingVolume.id : UuidGenerator.generate(),
                      seriesId: widget.seriesId,
                      volumeNumber: numVal,
                      releaseDate: releaseDate,
                      availability: availability,
                      isRestockedWatchlist: isWatchlist,
                      isOwned: isOwned,
                      isGift: isGift,
                      price: priceVal > 0 ? priceVal : null,
                      currency: priceVal > 0 ? selectedCurrency : (isEditing ? existingVolume.currency : selectedCurrency),
                    );

                    await ref.read(volumesNotifierProvider.notifier).saveVolume(volume);

                    if (isEditing && isOwned && priceVal > 0) {
                      final existingTx = ref.read(transactionRepositoryProvider).getByVolumeId(existingVolume.id);
                      if (existingTx != null) {
                        await ref.read(transactionsNotifierProvider.notifier).saveTransaction(
                          existingTx.copyWith(
                            price: priceVal,
                            currency: selectedCurrency,
                          ),
                        );
                      }
                    }

                    if (ctx.mounted) Navigator.of(ctx).pop(true);
                  },
                  child: Text(isEditing ? 'Save' : 'Add Volume'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved == true && mounted) {
      await SeriesStatusPromptHelper.checkAndPrompt(context, seriesId: widget.seriesId, ref: ref);
    }
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

  void _showBulkMarkSheet(BuildContext context, Series series, List<Volume> allVolumes) {
    if (allVolumes.isEmpty) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text('No volumes to mark.')),
        );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _BulkMarkVolumesSheet(
          series: series,
          allVolumes: allVolumes,
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

  void _showEditSeriesDialog(Series series) async {
    final titleController = TextEditingController(text: series.title);
    final priceController = TextEditingController(
      text: series.seriesPrice != null && series.seriesPrice! > 0
          ? (series.seriesPrice == series.seriesPrice!.roundToDouble()
              ? series.seriesPrice!.toInt().toString()
              : series.seriesPrice!.toString())
          : '',
    );
    final defaultVolPriceController = TextEditingController(
      text: (series.defaultVolumePrice ?? CurrencyHelper.defaultVolumePrice).toStringAsFixed(
        (series.defaultVolumePrice ?? CurrencyHelper.defaultVolumePrice) == (series.defaultVolumePrice ?? CurrencyHelper.defaultVolumePrice).roundToDouble() ? 0 : 2,
      ),
    );
    final allSeries = ref.read(seriesNotifierProvider);
    final availableTypes = TypeHelper.getAllAvailableTypes(allSeries.map((s) => s.type));
    String type = TypeHelper.formatTypeLabel(series.type);
    String status = series.collectionStatus;
    String releaseStatus = series.releaseStatus;
    String selectedCurrency = series.currency ?? ref.read(ruleConfigNotifierProvider).currency;
    String selectedDefaultVolCurrency = series.defaultVolumeCurrency ?? CurrencyHelper.defaultVolumeCurrency;

    final saved = await showDialog<bool>(
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
                    const SizedBox(height: 12),

                    // Default Volume Price
                    Text('Default Price Per Volume (Optional)', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      'Used for all volumes in this series unless an explicit price is entered for a volume',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: defaultVolPriceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              hintText: '14.99',
                              prefixIcon: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                child: CurrencySymbolText(
                                  currencyCode: selectedDefaultVolCurrency,
                                  baseFontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: CurrencyDropdownField(
                            value: selectedDefaultVolCurrency,
                            onChanged: (val) {
                              if (val != null) {
                                setDialogState(() => selectedDefaultVolCurrency = val);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Combined Series Price
                    Text('Combined Series Price (Optional)', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      'Total bundle price for the series instead of individual volume pricing',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: priceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              hintText: '0.00',
                              prefixIcon: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                child: CurrencySymbolText(
                                  currencyCode: selectedCurrency,
                                  baseFontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: CurrencyDropdownField(
                            value: selectedCurrency,
                            onChanged: (val) {
                              if (val != null) {
                                setDialogState(() => selectedCurrency = val);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final parsedPrice = CurrencyHelper.parsePrice(priceController.text);
                    final parsedDefaultVolPrice = CurrencyHelper.parsePrice(defaultVolPriceController.text);
                    final updated = series.copyWith(
                      title: titleController.text.trim(),
                      type: TypeHelper.normalizeKey(type),
                      collectionStatus: status,
                      releaseStatus: releaseStatus,
                      seriesPrice: parsedPrice > 0 ? parsedPrice : null,
                      clearSeriesPrice: parsedPrice <= 0,
                      currency: parsedPrice > 0 ? selectedCurrency : null,
                      clearCurrency: parsedPrice <= 0,
                      defaultVolumePrice: parsedDefaultVolPrice > 0 ? parsedDefaultVolPrice : CurrencyHelper.defaultVolumePrice,
                      defaultVolumeCurrency: parsedDefaultVolPrice > 0 ? selectedDefaultVolCurrency : CurrencyHelper.defaultVolumeCurrency,
                    );

                    await ref.read(seriesNotifierProvider.notifier).saveSeries(updated);
                    if (ctx.mounted) Navigator.of(ctx).pop(true);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved == true && mounted) {
      await SeriesStatusPromptHelper.checkAndPrompt(context, seriesId: widget.seriesId, ref: ref);
    }
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
    final ruleConfig = ref.watch(ruleConfigNotifierProvider);
    final exchangeRates = ref.watch(exchangeRatesNotifierProvider);
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
            onPressed: () => _showEditSeriesDialog(series),
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Series',
          ),
          PopupMenuButton<String>(
            key: const Key('series_detail_appbar_menu'),
            onSelected: (val) async {
              if (val == 'complete') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Mark Series as Completed?'),
                    content: Text(
                      'Are you sure you want to mark "${series.title}" as completed?\n\n'
                      'This will mark all ${allVolumes.length} volume(s) as purchased and move the series to Completed collection.',
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.caramelizedAmber),
                        child: const Text('Mark Completed'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await ref.read(seriesNotifierProvider.notifier).markSeriesAsCompleted(series.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context)
                      ..clearSnackBars()
                      ..showSnackBar(
                        SnackBar(
                          content: Text('Marked "${series.title}" as Completed and all volumes as purchased!'),
                          backgroundColor: AppColors.statusSuccess,
                        ),
                      );
                  }
                }
              } else if (val == 'bulk_mark') {
                _showBulkMarkSheet(context, series, allVolumes);
              } else if (val == 'delete') {
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
              if (series.status != 'completed')
                const PopupMenuItem(
                  value: 'complete',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_outline_rounded, color: AppColors.caramelizedAmber),
                      SizedBox(width: 8),
                      Flexible(child: Text('Mark as Completed')),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'bulk_mark',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.checklist_rounded, color: AppColors.caramelizedAmber),
                    SizedBox(width: 8),
                    Flexible(child: Text('Bulk Mark Volumes')),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.delete_outline, color: AppColors.statusDanger),
                    SizedBox(width: 8),
                    Flexible(child: Text('Delete Series', style: TextStyle(color: AppColors.statusDanger))),
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

                  if ((series.defaultVolumePrice ?? CurrencyHelper.defaultVolumePrice) > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Default Price / Vol', style: theme.textTheme.bodySmall),
                        Text(
                          '${CurrencyHelper.format(series.defaultVolumePrice ?? CurrencyHelper.defaultVolumePrice, currencyCode: series.defaultVolumeCurrency ?? CurrencyHelper.defaultVolumeCurrency)}${(series.defaultVolumeCurrency ?? CurrencyHelper.defaultVolumeCurrency) != ruleConfig.currency ? " (${CurrencyHelper.format(CurrencyHelper.convert(amount: series.defaultVolumePrice ?? CurrencyHelper.defaultVolumePrice, fromCurrency: series.defaultVolumeCurrency ?? CurrencyHelper.defaultVolumeCurrency, toCurrency: ruleConfig.currency, rates: exchangeRates), currencyCode: ruleConfig.currency)})" : ""}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.deepCaramel,
                          ),
                        ),
                      ],
                    ),
                  ],

                  if (series.seriesPrice != null && series.seriesPrice! > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text('Combined Series Price', style: theme.textTheme.bodySmall),
                            const SizedBox(width: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.caramelizedAmber.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Bundle',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppColors.caramelizedAmberLight : AppColors.caramelizedAmber,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${CurrencyHelper.format(series.seriesPrice!, currencyCode: series.currency ?? ruleConfig.currency)}${series.currency != null && series.currency != ruleConfig.currency ? " (${CurrencyHelper.format(stats.totalSpent, currencyCode: ruleConfig.currency)})" : ""}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.caramelizedAmberLight : AppColors.caramelizedAmber,
                          ),
                        ),
                      ],
                    ),
                  ] else if (stats.totalSpent > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Series Spend', style: theme.textTheme.bodySmall),
                        Text(
                          CurrencyHelper.format(stats.totalSpent, currencyCode: ruleConfig.currency),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.caramelizedAmberLight : AppColors.caramelizedAmber,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Action Buttons (Add Volume, Batch Add)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showAddVolumeDialog(),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add Volume'),
                  ),
                ),
                const SizedBox(width: 8),
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
                  currency: ruleConfig.currency,
                  defaultVolumePrice: series.defaultVolumePrice,
                  defaultVolumeCurrency: series.defaultVolumeCurrency ?? series.currency ?? ruleConfig.currency,
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
                  onEdit: () => _showAddVolumeDialog(existingVolume: vol),
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

class _BulkMarkVolumesSheet extends ConsumerStatefulWidget {
  final Series series;
  final List<Volume> allVolumes;

  const _BulkMarkVolumesSheet({
    required this.series,
    required this.allVolumes,
  });

  @override
  ConsumerState<_BulkMarkVolumesSheet> createState() => _BulkMarkVolumesSheetState();
}

class _BulkMarkVolumesSheetState extends ConsumerState<_BulkMarkVolumesSheet> {
  String _target = 'unowned'; // 'unowned', 'all', 'range', 'custom'
  String _action = 'purchased'; // 'purchased', 'gift', 'unowned'
  late TextEditingController _startController;
  late TextEditingController _endController;
  late Set<String> _selectedVolumeIds;

  @override
  void initState() {
    super.initState();
    final sorted = List<Volume>.from(widget.allVolumes)
      ..sort((a, b) => a.volumeNumber.compareTo(b.volumeNumber));
    final firstNum = sorted.isNotEmpty ? sorted.first.volumeNumber.toInt() : 1;
    final lastNum = sorted.isNotEmpty ? sorted.last.volumeNumber.toInt() : 1;

    _startController = TextEditingController(text: '$firstNum');
    _endController = TextEditingController(text: '$lastNum');
    _selectedVolumeIds = widget.allVolumes.where((v) => !v.isOwned).map((v) => v.id).toSet();
  }

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  List<Volume> _getTargetVolumes() {
    switch (_target) {
      case 'unowned':
        return widget.allVolumes.where((v) => !v.isOwned).toList();
      case 'all':
        return widget.allVolumes;
      case 'range':
        final start = double.tryParse(_startController.text.trim()) ?? 1.0;
        final end = double.tryParse(_endController.text.trim()) ?? 999.0;
        return widget.allVolumes
            .where((v) => v.volumeNumber >= start && v.volumeNumber <= end)
            .toList();
      case 'custom':
        return widget.allVolumes.where((v) => _selectedVolumeIds.contains(v.id)).toList();
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final targetVolumes = _getTargetVolumes();
    final unownedCount = widget.allVolumes.where((v) => !v.isOwned).length;

    return Material(
      color: isDark ? AppColors.darkPastryCard : Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bulk Mark Volumes',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.deepCaramel,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.series.title} · ${widget.allVolumes.length} volume(s)',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark ? AppColors.darkTextMuted : AppColors.deepCaramelMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Target Scope Selector
              Text('1. Target Volumes', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _target,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.filter_list_rounded, size: 20),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'unowned',
                    child: Text('Unowned Volumes Only ($unownedCount)'),
                  ),
                  DropdownMenuItem(
                    value: 'all',
                    child: Text('All Volumes (${widget.allVolumes.length})'),
                  ),
                  const DropdownMenuItem(
                    value: 'range',
                    child: Text('Volume Number Range'),
                  ),
                  DropdownMenuItem(
                    value: 'custom',
                    child: Text('Choose Specific Volumes (${_selectedVolumeIds.length})'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _target = val);
                  }
                },
              ),
              const SizedBox(height: 12),

              // Range inputs if range is selected
              if (_target == 'range') ...[
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _startController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'From Vol.',
                          prefixIcon: Icon(Icons.first_page_rounded, size: 20),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _endController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'To Vol.',
                          prefixIcon: Icon(Icons.last_page_rounded, size: 20),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // Specific volume checklist if custom is selected
              if (_target == 'custom') ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_selectedVolumeIds.length} of ${widget.allVolumes.length} selected',
                      style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedVolumeIds = widget.allVolumes.map((v) => v.id).toSet();
                            });
                          },
                          child: const Text('Select All', style: TextStyle(fontSize: 12)),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedVolumeIds.clear();
                            });
                          },
                          child: const Text('Clear', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  constraints: const BoxConstraints(maxHeight: 180),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkPastryCardElevated : AppColors.pastryCrustLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppColors.darkPastryBorder : AppColors.pastryCrustBorder,
                    ),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: widget.allVolumes.length,
                    itemBuilder: (ctx, index) {
                      final vol = widget.allVolumes[index];
                      final isSelected = _selectedVolumeIds.contains(vol.id);
                      return CheckboxListTile(
                        dense: true,
                        value: isSelected,
                        title: Text(
                          'Vol. ${DateFormatter.formatVolumeNumber(vol.volumeNumber)}${vol.isOwned ? (vol.isGift ? " (Gift)" : " (Purchased)") : " (Unowned)"}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                        activeColor: AppColors.caramelizedAmber,
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedVolumeIds.add(vol.id);
                            } else {
                              _selectedVolumeIds.remove(vol.id);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Action Mode Selector
              Text('2. Mark Status As', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<String>(
                  style: SegmentedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    selectedBackgroundColor: AppColors.caramelizedAmber,
                    selectedForegroundColor: Colors.white,
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                  segments: const [
                    ButtonSegment(
                      value: 'purchased',
                      label: Text('Purchased', style: TextStyle(fontSize: 12)),
                      icon: Icon(Icons.shopping_bag_outlined, size: 16),
                    ),
                    ButtonSegment(
                      value: 'gift',
                      label: Text('Gift', style: TextStyle(fontSize: 12)),
                      icon: Icon(Icons.card_giftcard_rounded, size: 16),
                    ),
                    ButtonSegment(
                      value: 'unowned',
                      label: Text('Unmark', style: TextStyle(fontSize: 12)),
                      icon: Icon(Icons.remove_circle_outline_rounded, size: 16),
                    ),
                  ],
                  selected: {_action},
                  onSelectionChanged: (sel) => setState(() => _action = sel.first),
                ),
              ),
              const SizedBox(height: 18),

              // Summary Info
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.caramelizedAmber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.caramelizedAmber.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.caramelizedAmber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _action == 'unowned'
                            ? 'Will unmark ${targetVolumes.length} volume(s) and remove transactions.'
                            : 'Will mark ${targetVolumes.length} volume(s) as ${_action.toUpperCase()}.',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.caramelizedAmber,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: Text('Apply (${targetVolumes.length})'),
                    onPressed: targetVolumes.isEmpty
                        ? null
                        : () async {
                            final targetIds = targetVolumes.map((v) => v.id).toList();
                            final isOwned = _action != 'unowned';
                            final isGift = _action == 'gift';

                            await ref.read(volumesNotifierProvider.notifier).bulkUpdateOwnership(
                                  volumeIds: targetIds,
                                  isOwned: isOwned,
                                  isGift: isGift,
                                );

                            if (context.mounted) {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context)
                                ..clearSnackBars()
                                ..showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Updated ${targetIds.length} volume(s) for "${widget.series.title}"!',
                                    ),
                                    backgroundColor: AppColors.statusSuccess,
                                  ),
                                );
                              await SeriesStatusPromptHelper.checkAndPrompt(
                                context,
                                seriesId: widget.series.id,
                                ref: ref,
                              );
                            }
                          },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
