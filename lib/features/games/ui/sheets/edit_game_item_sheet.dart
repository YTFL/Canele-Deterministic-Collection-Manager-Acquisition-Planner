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

class EditGameItemSheet extends ConsumerStatefulWidget {
  final GameItem item;
  final GameSeries series;

  const EditGameItemSheet({
    super.key,
    required this.item,
    required this.series,
  });

  static Future<void> show(BuildContext context, {required GameItem item, required GameSeries series}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => EditGameItemSheet(item: item, series: series),
    );
  }

  @override
  ConsumerState<EditGameItemSheet> createState() => _EditGameItemSheetState();
}

class _EditGameItemSheetState extends ConsumerState<EditGameItemSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _numberController;
  late TextEditingController _priceController;

  late GameItemType _itemType;
  late bool _isOwned;
  late bool _isGift;
  late bool _isPriorityTarget;
  late GameAvailability _availability;
  late String _currency;

  @override
  void initState() {
    super.initState();
    final it = widget.item;
    _titleController = TextEditingController(text: it.title);
    _numberController = TextEditingController(
      text: it.gameNumber == it.gameNumber.roundToDouble()
          ? it.gameNumber.toInt().toString()
          : it.gameNumber.toString(),
    );
    _priceController = TextEditingController(
      text: it.price != null && it.price! > 0
          ? it.price!.toStringAsFixed(it.price == it.price!.roundToDouble() ? 0 : 2)
          : '',
    );
    _itemType = it.itemType;
    _isOwned = it.isOwned;
    _isGift = it.isGift;
    _isPriorityTarget = it.isPriorityTarget;
    _availability = it.availability;
    _currency = it.currency ?? widget.series.defaultCurrency ?? 'USD';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _numberController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final parsedPrice = CurrencyHelper.parsePrice(_priceController.text);
    final parsedNumber = double.tryParse(_numberController.text.trim()) ?? widget.item.gameNumber;

    final updatedItem = widget.item.copyWith(
      title: _titleController.text.trim(),
      itemType: _itemType,
      gameNumber: parsedNumber,
      isOwned: _isOwned,
      isGift: _isGift,
      price: parsedPrice > 0 ? parsedPrice : null,
      clearPrice: parsedPrice <= 0,
      currency: _currency,
      availability: _availability,
      isPriorityTarget: _isPriorityTarget,
    );

    await ref.read(gameItemsNotifierProvider.notifier).saveItem(updatedItem);

    // Sync transaction ledger if needed
    final txNotifier = ref.read(transactionsNotifierProvider.notifier);
    final allTxs = ref.read(transactionsNotifierProvider);
    final existingTx = allTxs.cast<PurchaseTransaction?>().firstWhere(
          (t) => t?.volumeId == widget.item.id,
          orElse: () => null,
        );

    if (_isOwned) {
      final quotaSummary = ref.read(quotaProvider);
      final bucket = _isGift ? 'gift' : quotaSummary.suggestedAutoBucket;
      final finalPrice = _isGift ? 0.0 : (parsedPrice > 0 ? parsedPrice : (widget.series.defaultGamePrice ?? 0.0));

      if (existingTx != null) {
        final updatedTx = existingTx.copyWith(
          quotaBucket: bucket,
          price: finalPrice,
          currency: _currency,
          notes: _isGift ? 'Gift / Free Claim' : 'Updated purchase',
        );
        await txNotifier.saveTransaction(updatedTx);
      } else {
        final newTx = PurchaseTransaction(
          id: UuidGenerator.generate(),
          volumeId: widget.item.id,
          purchaseDate: DateTime.now(),
          quotaBucket: bucket,
          price: finalPrice,
          currency: _currency,
          notes: _isGift ? 'Gift / Free Claim' : 'Logged purchase',
        );
        await txNotifier.saveTransaction(newTx);
      }
    } else {
      if (existingTx != null) {
        await txNotifier.deleteTransaction(existingTx.id);
      }
    }

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text('Updated "${updatedItem.title}"!'),
            backgroundColor: AppColors.statusSuccess,
          ),
        );
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${widget.item.title}"?'),
        content: const Text(
          'Are you sure you want to remove this item? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusDanger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await ref.read(gameItemsNotifierProvider.notifier).deleteItem(widget.item.id);
      final allTxs = ref.read(transactionsNotifierProvider);
      final existingTx = allTxs.cast<PurchaseTransaction?>().firstWhere(
            (t) => t?.volumeId == widget.item.id,
            orElse: () => null,
          );
      if (existingTx != null) {
        await ref.read(transactionsNotifierProvider.notifier).deleteTransaction(existingTx.id);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text('Removed "${widget.item.title}"'),
              backgroundColor: AppColors.statusDanger,
            ),
          );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
        child: Form(
          key: _formKey,
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
                      _itemType == GameItemType.dlc ? 'Edit DLC / Expansion' : 'Edit Game',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.deepCaramel,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.statusDanger),
                      tooltip: 'Delete Item',
                      onPressed: _delete,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Item Type Selector (Game vs DLC)
                SegmentedButton<GameItemType>(
                  style: SegmentedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    selectedBackgroundColor: AppColors.caramelizedAmber,
                    selectedForegroundColor: Colors.white,
                  ),
                  segments: const [
                    ButtonSegment(
                      value: GameItemType.game,
                      label: Text('Full Game'),
                      icon: Icon(Icons.sports_esports_rounded, size: 16),
                    ),
                    ButtonSegment(
                      value: GameItemType.dlc,
                      label: Text('DLC / Expansion'),
                      icon: Icon(Icons.extension_rounded, size: 16),
                    ),
                  ],
                  selected: {_itemType},
                  onSelectionChanged: (sel) => setState(() => _itemType = sel.first),
                ),
                const SizedBox(height: 14),

                // Title
                Text('Title', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Dark Souls III, Shadow of the Erdtree',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Title is required';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Number Order (if in a franchise)
                if (!widget.series.isStandalone) ...[
                  Text('Installment / Sequence Order',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _numberController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      hintText: 'e.g. 1, 2, 1.5',
                      prefixIcon: Icon(Icons.format_list_numbered_rounded, size: 20),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Ownership Switch
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Already Acquired / Owned'),
                  subtitle: const Text('Game is in your possession / digital library'),
                  activeThumbColor: AppColors.caramelizedAmber,
                  value: _isOwned,
                  onChanged: (val) {
                    setState(() {
                      _isOwned = val;
                      if (!val) _isGift = false;
                    });
                  },
                ),

                // Gift / Free Claim Switch (visible when Owned is true)
                if (_isOwned) ...[
                  Container(
                    margin: const EdgeInsets.only(top: 4, bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.caramelizedAmber.withValues(alpha: isDark ? 0.15 : 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.caramelizedAmber.withValues(alpha: 0.3),
                      ),
                    ),
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Row(
                        children: [
                          const Icon(Icons.card_giftcard_rounded, size: 18, color: AppColors.caramelizedAmber),
                          const SizedBox(width: 8),
                          Text(
                            'Acquired as Gift / Free Claim',
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      subtitle: const Text('Does not deduct from monthly acquisition budget'),
                      activeThumbColor: AppColors.caramelizedAmber,
                      value: _isGift,
                      onChanged: (val) => setState(() => _isGift = val),
                    ),
                  ),
                ],

                const SizedBox(height: 8),

                // Price & Currency
                Text('Price / Cost', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _priceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          hintText: _isGift ? '0.00 (Gift)' : '59.99',
                          prefixIcon: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            child: CurrencySymbolText(
                              currencyCode: _currency,
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
                        value: _currency,
                        onChanged: (val) {
                          if (val != null) setState(() => _currency = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Availability Status
                Text('Availability', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                DropdownButtonFormField<GameAvailability>(
                  initialValue: _availability,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.event_available_rounded, size: 20),
                  ),
                  items: const [
                    DropdownMenuItem(value: GameAvailability.available, child: Text('Available to Buy')),
                    DropdownMenuItem(value: GameAvailability.upcoming, child: Text('Upcoming / Pre-order')),
                    DropdownMenuItem(value: GameAvailability.delisted, child: Text('Delisted / Not for sale')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _availability = val);
                  },
                ),
                const SizedBox(height: 14),

                // Watchlist Priority Target (only for unowned)
                if (!_isOwned) ...[
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Watchlist Priority Target'),
                    subtitle: const Text('Star as high-priority acquisition target'),
                    activeThumbColor: AppColors.caramelizedAmber,
                    value: _isPriorityTarget,
                    onChanged: (val) => setState(() => _isPriorityTarget = val),
                  ),
                  const SizedBox(height: 14),
                ],

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _save,
                        child: const Text('Save Changes'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
