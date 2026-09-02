import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_helper.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/uuid_generator.dart';
import '../../models/series.dart';
import '../../models/volume.dart';
import '../../models/purchase_transaction.dart';
import '../../providers/series_provider.dart';
import '../../providers/quota_provider.dart';
import 'canele_dropdown.dart';
import '../helpers/series_status_prompt_helper.dart';

String _availabilityLabel(String key) {
  switch (key) {
    case 'available': return 'Available';
    case 'outOfStock': return 'Out of Stock';
    case 'outOfPrint': return 'Out of Print';
    case 'announced': return 'Announced';
    default: return key;
  }
}

class LogTransactionSheet extends ConsumerStatefulWidget {
  final Series? initialSeries;
  final Volume? initialVolume;

  const LogTransactionSheet({
    super.key,
    this.initialSeries,
    this.initialVolume,
  });

  static Future<void> show(
    BuildContext context, {
    Series? series,
    Volume? volume,
  }) async {
    final resultSeriesId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => LogTransactionSheet(
        initialSeries: series,
        initialVolume: volume,
      ),
    );

    if (resultSeriesId != null && context.mounted) {
      await SeriesStatusPromptHelper.checkAndPrompt(context, seriesId: resultSeriesId);
    }
  }

  @override
  ConsumerState<LogTransactionSheet> createState() => _LogTransactionSheetState();
}

class _LogTransactionSheetState extends ConsumerState<LogTransactionSheet> {
  Series? _selectedSeries;
  Volume? _selectedVolume;
  final DateTime _purchaseDate = DateTime.now();
  bool _isGift = false; // Toggle between Purchased (false) and Gift (true)
  String? _selectedCurrency;
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedSeries = widget.initialSeries;
    _selectedVolume = widget.initialVolume;
    if (_selectedVolume != null) {
      if (_selectedVolume!.isGift) {
        _isGift = true;
      }
      _selectedCurrency = _selectedVolume!.currency ?? _selectedSeries?.defaultVolumeCurrency ?? CurrencyHelper.defaultVolumeCurrency;
      if (_selectedVolume!.price != null && _selectedVolume!.price! > 0) {
        _priceController.text = _selectedVolume!.price!.toStringAsFixed(
          _selectedVolume!.price! == _selectedVolume!.price!.roundToDouble() ? 0 : 2,
        );
      } else {
        final defPrice = _selectedSeries?.defaultVolumePrice ?? CurrencyHelper.defaultVolumePrice;
        _priceController.text = defPrice.toStringAsFixed(
          defPrice == defPrice.roundToDouble() ? 0 : 2,
        );
      }
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedVolume == null) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
        const SnackBar(content: Text('Please select a volume')),
      );
      return;
    }

    final config = ref.read(ruleConfigNotifierProvider);
    final quotaSummary = ref.read(quotaProvider);
    final bucket = _isGift ? 'gift' : quotaSummary.suggestedAutoBucket;
    final priceVal = _isGift ? 0.0 : CurrencyHelper.parsePrice(_priceController.text.trim());
    final effectiveCurrency = _selectedCurrency ?? config.currency;

    // 1. Update Volume to Owned
    final updatedVol = _selectedVolume!.copyWith(
      isOwned: true,
      isGift: _isGift,
      isRestockedWatchlist: false,
      price: priceVal > 0 ? priceVal : _selectedVolume!.price,
      currency: priceVal > 0 ? effectiveCurrency : (_selectedVolume!.currency ?? effectiveCurrency),
    );
    await ref.read(volumesNotifierProvider.notifier).saveVolume(updatedVol);

    // 2. Save Purchase Transaction
    final tx = PurchaseTransaction(
      id: UuidGenerator.generate(),
      volumeId: _selectedVolume!.id,
      purchaseDate: _purchaseDate,
      quotaBucket: bucket,
      price: priceVal,
      currency: effectiveCurrency,
      notes: _notesController.text.trim(),
    );
    await ref.read(transactionsNotifierProvider.notifier).saveTransaction(tx);

    final targetSeriesId = _selectedSeries?.id ?? _selectedVolume!.seriesId;

    if (mounted) {
      Navigator.of(context).pop(targetSeriesId);
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
        SnackBar(
          content: Text(
            'Logged Vol. ${DateFormatter.formatVolumeNumber(_selectedVolume!.volumeNumber)} as ${bucket.toUpperCase()} acquisition!',
          ),
          backgroundColor: AppColors.caramelizedAmber,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final allSeries = ref.watch(seriesNotifierProvider);
    final allVolumes = ref.watch(volumesNotifierProvider);
    final quota = ref.watch(quotaProvider);
    final config = ref.watch(ruleConfigNotifierProvider);

    // Filter available unowned volumes for selected series
    List<Volume> seriesVolumes = [];
    if (_selectedSeries != null) {
      seriesVolumes = allVolumes
          .where((v) => v.seriesId == _selectedSeries!.id && !v.isOwned)
          .toList()
        ..sort((a, b) => a.volumeNumber.compareTo(b.volumeNumber));
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkPastryCard : AppColors.custardCream,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: isDark ? AppColors.darkPastryBorder : AppColors.pastryCrustBorder,
        ),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Handle & Title
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkPastryBorder : AppColors.pastryCrustBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Log Book Acquisition',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const Divider(height: 20),

            // Series Selector (if not pre-selected)
            if (widget.initialSeries == null) ...[
              Text('Series', style: theme.textTheme.titleMedium),
              const SizedBox(height: 6),
              CaneleDropdown<Series>(
                value: _selectedSeries,
                hint: 'Select a series',
                items: allSeries.map((s) {
                  return DropdownMenuItem<Series>(
                    value: s,
                    child: Text(s.title, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (s) {
                  setState(() {
                    _selectedSeries = s;
                    _selectedVolume = null;
                  });
                },
              ),
              const SizedBox(height: 14),
            ] else ...[
              Text(
                _selectedSeries!.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.caramelizedAmber,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Volume Selector
            if (widget.initialVolume == null && _selectedSeries != null) ...[
              Text('Volume', style: theme.textTheme.titleMedium),
              const SizedBox(height: 6),
              if (seriesVolumes.isEmpty)
                Text(
                  'No unowned volumes found for this series.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.statusWarning),
                )
              else
              CaneleDropdown<Volume>(
                  value: _selectedVolume,
                  hint: 'Select volume to acquire',
                  items: seriesVolumes.map((v) {
                    return DropdownMenuItem<Volume>(
                      value: v,
                      child: Text(
                        'Vol. ${DateFormatter.formatVolumeNumber(v.volumeNumber)}  ·  ${_availabilityLabel(v.availability)}',
                      ),
                    );
                  }).toList(),
                  onChanged: (v) {
                    setState(() {
                      _selectedVolume = v;
                      if (v != null) {
                        if (v.price != null && v.price! > 0) {
                          _priceController.text = v.price!.toStringAsFixed(
                            v.price! == v.price!.roundToDouble() ? 0 : 2,
                          );
                          if (v.currency != null) _selectedCurrency = v.currency;
                        } else {
                          final defPrice = _selectedSeries?.defaultVolumePrice ?? CurrencyHelper.defaultVolumePrice;
                          final defCurr = _selectedSeries?.defaultVolumeCurrency ?? CurrencyHelper.defaultVolumeCurrency;
                          _priceController.text = defPrice.toStringAsFixed(
                            defPrice == defPrice.roundToDouble() ? 0 : 2,
                          );
                          _selectedCurrency = defCurr;
                        }
                      }
                    });
                  },
                ),
              const SizedBox(height: 16),
            ] else if (_selectedVolume != null) ...[
              Text(
                'Volume ${DateFormatter.formatVolumeNumber(_selectedVolume!.volumeNumber)}',
                style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 14),
            ],

            // Simplified [ Purchased ] | [ Gift ] Toggle
            Text('Acquisition Type', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _isGift = false),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !_isGift
                            ? AppColors.caramelizedAmber
                            : (isDark ? AppColors.darkPastryCardElevated : AppColors.pastryCrustLight),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: !_isGift
                              ? AppColors.caramelizedAmber
                              : (isDark ? AppColors.darkPastryBorder : AppColors.pastryCrustBorder),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_bag_outlined,
                            size: 18,
                            color: !_isGift ? Colors.white : null,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Purchased',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: !_isGift ? Colors.white : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _isGift = true),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _isGift
                            ? AppColors.caramelizedAmber
                            : (isDark ? AppColors.darkPastryCardElevated : AppColors.pastryCrustLight),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isGift
                              ? AppColors.caramelizedAmber
                              : (isDark ? AppColors.darkPastryBorder : AppColors.pastryCrustBorder),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.card_giftcard_rounded,
                            size: 18,
                            color: _isGift ? Colors.white : null,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Gift',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: _isGift ? Colors.white : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Dynamic Informational Subtitle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkPastryCardElevated : AppColors.pastryCrustLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    _isGift ? Icons.card_giftcard_rounded : Icons.info_outline_rounded,
                    size: 16,
                    color: AppColors.caramelizedAmber,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isGift
                          ? 'Gift acquisition — Does not deduct from your monthly regular or bonus quota.'
                          : quota.allocationDescription,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Price (Only for purchased acquisitions)
            if (!_isGift) ...[
              Text('Price (Optional)', style: theme.textTheme.titleMedium),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        hintText: '0.00',
                        prefixIcon: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          child: CurrencySymbolText(
                            currencyCode: _selectedCurrency ?? config.currency,
                            baseFontSize: 16,
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
                      value: _selectedCurrency ?? config.currency,
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedCurrency = val);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Notes
            Text('Notes (Optional)', style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                hintText: 'e.g. Bought during restock sale',
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                child: const Text('Record Acquisition'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
