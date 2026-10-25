import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_helper.dart';
import '../../models/game_series.dart';
import '../../providers/game_providers.dart';

class EditGameSeriesSheet extends ConsumerStatefulWidget {
  final GameSeries series;

  const EditGameSeriesSheet({super.key, required this.series});

  static Future<void> show(BuildContext context, {required GameSeries series}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => EditGameSeriesSheet(series: series),
    );
  }

  @override
  ConsumerState<EditGameSeriesSheet> createState() => _EditGameSeriesSheetState();
}

class _EditGameSeriesSheetState extends ConsumerState<EditGameSeriesSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _priceController;

  late String _collectionStatus;
  late String _releaseStatus;
  late String _currency;

  @override
  void initState() {
    super.initState();
    final s = widget.series;
    _titleController = TextEditingController(text: s.title);
    _priceController = TextEditingController(
      text: s.defaultGamePrice != null && s.defaultGamePrice! > 0
          ? s.defaultGamePrice!.toStringAsFixed(s.defaultGamePrice == s.defaultGamePrice!.roundToDouble() ? 0 : 2)
          : '',
    );
    _collectionStatus = s.collectionStatus;
    _releaseStatus = s.releaseStatus;
    _currency = s.defaultCurrency ?? 'USD';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final parsedPrice = CurrencyHelper.parsePrice(_priceController.text);

    final updated = widget.series.copyWith(
      title: _titleController.text.trim(),
      collectionStatus: _collectionStatus,
      releaseStatus: _releaseStatus,
      defaultGamePrice: parsedPrice > 0 ? parsedPrice : null,
      clearDefaultPrice: parsedPrice <= 0,
      defaultCurrency: _currency,
    );

    await ref.read(gameSeriesNotifierProvider.notifier).saveSeries(updated);

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text('Updated "${updated.title}"!'),
            backgroundColor: AppColors.statusSuccess,
          ),
        );
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${widget.series.title}"?'),
        content: Text(
          'Are you sure you want to delete this ${widget.series.isStandalone ? 'game' : 'franchise'} and all its tracked items? This cannot be undone.',
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
      // Delete all items of this series
      final allItems = ref.read(gameItemsNotifierProvider);
      final seriesItems = allItems.where((i) => i.seriesId == widget.series.id).toList();
      for (final item in seriesItems) {
        await ref.read(gameItemsNotifierProvider.notifier).deleteItem(item.id);
      }
      await ref.read(gameSeriesNotifierProvider.notifier).deleteSeries(widget.series.id);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text('Deleted "${widget.series.title}"'),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Edit ${widget.series.isStandalone ? 'Standalone Game' : 'Game Franchise'}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.deepCaramel,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.statusDanger),
                      tooltip: 'Delete',
                      onPressed: _delete,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Title
                Text('Title', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(hintText: 'Game Title'),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Title is required';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Collection Status
                Text('Acquisition Status', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _collectionStatus,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'active', child: Text('Active (Planning / In budget)')),
                    DropdownMenuItem(value: 'completed', child: Text('Acquired / Owned')),
                    DropdownMenuItem(value: 'wishlist', child: Text('Wishlist (Backlog)')),
                    DropdownMenuItem(value: 'dropped', child: Text('Dropped (Shelved)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _collectionStatus = val);
                  },
                ),
                const SizedBox(height: 14),

                // Franchise Release Status (if franchise)
                if (!widget.series.isStandalone) ...[
                  Text('Release Status', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _releaseStatus,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'ongoing', child: Text('Ongoing (More releases planned)')),
                      DropdownMenuItem(value: 'completed', child: Text('Completed (Franchise finished)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _releaseStatus = val);
                    },
                  ),
                  const SizedBox(height: 14),
                ],

                // Default Price & Currency
                Text(
                  widget.series.isStandalone ? 'Price' : 'Default Game Price',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Row(
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
                const SizedBox(height: 20),

                // Buttons
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
