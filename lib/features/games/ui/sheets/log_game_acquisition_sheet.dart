import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_helper.dart';
import '../../../../core/utils/uuid_generator.dart';
import '../../../../models/purchase_transaction.dart';
import '../../../../providers/quota_provider.dart';
import '../../../../providers/series_provider.dart';
import '../../models/game_item.dart';
import '../../models/game_series.dart';
import '../../providers/game_providers.dart';

class LogGameAcquisitionSheet extends ConsumerStatefulWidget {
  final GameSeries series;
  final GameItem item;

  const LogGameAcquisitionSheet({
    super.key,
    required this.series,
    required this.item,
  });

  static Future<bool?> show(
    BuildContext context, {
    required GameSeries series,
    required GameItem item,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => LogGameAcquisitionSheet(
        series: series,
        item: item,
      ),
    );
  }

  @override
  ConsumerState<LogGameAcquisitionSheet> createState() => _LogGameAcquisitionSheetState();
}

class _LogGameAcquisitionSheetState extends ConsumerState<LogGameAcquisitionSheet> {
  bool _isGift = false;
  String? _selectedCurrency;
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _isGift = widget.item.isGift;
    _selectedCurrency = widget.item.currency ??
        widget.series.defaultCurrency ??
        CurrencyHelper.defaultVolumeCurrency;

    final initialPrice = widget.item.price ?? widget.series.defaultGamePrice ?? 0.0;
    if (initialPrice > 0) {
      _priceController.text = initialPrice.toStringAsFixed(
        initialPrice == initialPrice.roundToDouble() ? 0 : 2,
      );
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final parsedPrice = CurrencyHelper.parsePrice(_priceController.text);
    final quotaSummary = ref.read(quotaProvider);
    final currency = _selectedCurrency ?? widget.series.defaultCurrency ?? 'USD';

    // 1. Update GameItem to owned
    final updatedItem = widget.item.copyWith(
      isOwned: true,
      isGift: _isGift,
      price: _isGift ? null : (parsedPrice > 0 ? parsedPrice : null),
      currency: currency,
    );
    await ref.read(gameItemsNotifierProvider.notifier).saveItem(updatedItem);

    // 2. Create PurchaseTransaction in ledger
    final bucket = _isGift ? 'gift' : quotaSummary.suggestedAutoBucket;
    final finalPrice = _isGift ? 0.0 : (parsedPrice > 0 ? parsedPrice : 0.0);

    final tx = PurchaseTransaction(
      id: UuidGenerator.generate(),
      volumeId: widget.item.id,
      purchaseDate: DateTime.now(),
      quotaBucket: bucket,
      price: finalPrice,
      currency: currency,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : (_isGift ? 'Gift / Free Claim' : 'Acquired game'),
    );

    await ref.read(transactionsNotifierProvider.notifier).saveTransaction(tx);

    if (mounted) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(
              _isGift
                  ? 'Acquired "${widget.item.title}" as a Gift / Free Claim!'
                  : 'Acquired "${widget.item.title}"!',
            ),
            backgroundColor: AppColors.statusSuccess,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final quotaSummary = ref.watch(quotaProvider);
    final config = ref.watch(ruleConfigNotifierProvider);
    final isDlc = widget.item.itemType == GameItemType.dlc;

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
                  Text(
                    'Log Acquisition',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.deepCaramel,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Series & Game Title Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkPastryCardElevated : AppColors.pastryCrustLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppColors.darkPastryBorder : AppColors.pastryCrustBorder,
                    width: 0.8,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!widget.series.isStandalone) ...[
                      Text(
                        widget.series.title,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextMuted : AppColors.deepCaramelMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: isDlc
                                ? AppColors.statusInfo.withValues(alpha: isDark ? 0.25 : 0.15)
                                : AppColors.caramelizedAmber.withValues(alpha: isDark ? 0.25 : 0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isDlc
                                  ? AppColors.statusInfo.withValues(alpha: 0.4)
                                  : AppColors.caramelizedAmber.withValues(alpha: 0.4),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            isDlc ? 'DLC' : 'GAME',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: isDlc
                                  ? AppColors.statusInfo
                                  : (isDark ? AppColors.caramelizedAmberLight : AppColors.caramelizedAmber),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.item.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Acquisition Type: [ Purchased ] | [ Gift / Free Claim ]
              Text('Acquisition Type', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
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
                              color: !_isGift ? Colors.white : (isDark ? AppColors.darkTextPrimary : AppColors.deepCaramel),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Purchased',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: !_isGift ? Colors.white : (isDark ? AppColors.darkTextPrimary : AppColors.deepCaramel),
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
                              color: _isGift ? Colors.white : (isDark ? AppColors.darkTextPrimary : AppColors.deepCaramel),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Gift / Free Claim',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: _isGift ? Colors.white : (isDark ? AppColors.darkTextPrimary : AppColors.deepCaramel),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Dynamic Informational Notice
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkPastryCardElevated : AppColors.pastryCrustLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? AppColors.darkPastryBorder : AppColors.pastryCrustBorder,
                    width: 0.8,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isGift ? Icons.card_giftcard_rounded : Icons.info_outline_rounded,
                      size: 18,
                      color: AppColors.caramelizedAmber,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _isGift
                            ? 'Gift / Free Claim (e.g. Epic giveaway, PS Plus, gifted copy) does not deduct from your monthly acquisition quota.'
                            : (quotaSummary.totalRemaining > 0
                                ? 'Will use 1 ${quotaSummary.suggestedAutoBucket} quota for this month (${quotaSummary.totalRemaining} left in budget).'
                                : 'Quota fulfilled: this will be tracked as extra acquisition in your ledger.'),
                        style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Price & Currency (only for purchases)
              if (!_isGift) ...[
                Text('Purchase Price', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
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
                          hintText: '59.99',
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
                          if (val != null) setState(() => _selectedCurrency = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // Notes
              Text('Notes (Optional)', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Steam Summer Sale, Gifted by friend',
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                  label: Text(_isGift ? 'Confirm Gift Claim' : 'Confirm Purchase'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: AppColors.caramelizedAmber,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
