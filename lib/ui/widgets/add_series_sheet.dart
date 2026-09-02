import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_helper.dart';
import '../../core/utils/type_helper.dart';
import '../../providers/series_provider.dart';
import '../../providers/quota_provider.dart';
import 'canele_dropdown.dart';
import '../helpers/series_status_prompt_helper.dart';

enum SeriesStructure { multiVolume, standalone }

class AddSeriesSheet extends ConsumerStatefulWidget {
  const AddSeriesSheet({super.key});

  @override
  ConsumerState<AddSeriesSheet> createState() => _AddSeriesSheetState();
}

class _AddSeriesSheetState extends ConsumerState<AddSeriesSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _totalVolumesController = TextEditingController(text: '1');
  final _ownedCountController = TextEditingController(text: '0');
  final _priceController = TextEditingController();
  final _defaultVolPriceController = TextEditingController(text: CurrencyHelper.defaultVolumePrice.toString());

  SeriesStructure _structure = SeriesStructure.multiVolume;
  String? _selectedType;
  final Set<String> _customTypes = {};
  String _collectionStatus = 'active';
  String _releaseStatus = 'ongoing';
  String? _selectedCurrency;
  String? _selectedDefaultVolCurrency = CurrencyHelper.defaultVolumeCurrency;
  bool _markOwned = true;
  int _ownedCount = 0;
  bool _isGift = false;

  @override
  void dispose() {
    _titleController.dispose();
    _totalVolumesController.dispose();
    _ownedCountController.dispose();
    _priceController.dispose();
    _defaultVolPriceController.dispose();
    super.dispose();
  }

  Future<void> _showAddCustomTypeDialog(BuildContext context) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final newType = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Format Type'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'e.g. Manga, Novel, Comic, Artbook',
              labelText: 'Format Type Name',
              prefixIcon: Icon(Icons.category_outlined, size: 20),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Enter a format type name';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(ctx).pop(controller.text.trim());
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (newType != null && newType.isNotEmpty) {
      final formatted = TypeHelper.formatTypeLabel(newType);
      setState(() {
        _customTypes.add(formatted);
        _selectedType = formatted;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final allSeries = ref.watch(seriesNotifierProvider);
    final availableTypes = TypeHelper.getAllAvailableTypes([
      ...allSeries.map((s) => s.type),
      ..._customTypes,
    ]);

    // Default select first available type if not set yet
    if (_selectedType == null && availableTypes.isNotEmpty) {
      _selectedType = availableTypes.first;
    }

    final isMulti = _structure == SeriesStructure.multiVolume;

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
                    'Add New Series',
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
              const SizedBox(height: 14),

              // Title
              Text('Series Title', style: theme.textTheme.titleSmall),
              const SizedBox(height: 6),
              TextFormField(
                controller: _titleController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'e.g. 86 - Eighty-Six or Frieren',
                  prefixIcon: Icon(Icons.book_outlined, size: 20),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a series title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Type
              Text('Format Type', style: theme.textTheme.titleSmall),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: CaneleDropdown<String>(
                      value: _selectedType,
                      hint: 'Select format type',
                      prefixIcon: const Icon(Icons.category_outlined, size: 20),
                      items: [
                        ...availableTypes.map(
                          (t) => DropdownMenuItem<String>(
                            value: t,
                            child: Text(t),
                          ),
                        ),
                        const DropdownMenuItem<String>(
                          value: '__ADD_NEW__',
                          child: Text('Add new type...'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val == '__ADD_NEW__') {
                          _showAddCustomTypeDialog(context);
                        } else if (val != null) {
                          setState(() => _selectedType = val);
                        }
                      },
                      validator: (val) {
                        if (_selectedType == null ||
                            _selectedType!.trim().isEmpty ||
                            _selectedType == '__ADD_NEW__') {
                          return 'Please select or add a format type';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: 'Add Format Type',
                    icon: const Icon(Icons.add_rounded),
                    onPressed: () => _showAddCustomTypeDialog(context),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Structure Segmented Button
              Text('Structure', style: theme.textTheme.titleSmall),
              const SizedBox(height: 6),
              SegmentedButton<SeriesStructure>(
                segments: const [
                  ButtonSegment(
                    value: SeriesStructure.multiVolume,
                    label: Text('Series'),
                    icon: Icon(Icons.auto_stories_rounded, size: 18),
                  ),
                  ButtonSegment(
                    value: SeriesStructure.standalone,
                    label: Text('Single'),
                    icon: Icon(Icons.menu_book_rounded, size: 18),
                  ),
                ],
                selected: {_structure},
                onSelectionChanged: (set) {
                  setState(() {
                    _structure = set.first;
                    if (_structure == SeriesStructure.standalone) {
                      _totalVolumesController.text = '1';
                      _ownedCountController.text = '1';
                      _ownedCount = 1;
                      _collectionStatus = 'completed';
                      _releaseStatus = 'completed';
                      _markOwned = true;
                    } else {
                      _totalVolumesController.text = '1';
                      _ownedCountController.text = '0';
                      _ownedCount = 0;
                      _collectionStatus = 'active';
                      _releaseStatus = 'ongoing';
                      _markOwned = true;
                    }
                  });
                },
              ),
              const SizedBox(height: 14),

              // Volume Count & Owned Inputs
              if (isMulti) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Total Released Volumes
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total Released', style: theme.textTheme.titleSmall),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _totalVolumesController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'e.g. 12',
                              prefixIcon: const Icon(Icons.format_list_numbered_rounded, size: 20),
                              suffixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline_rounded, size: 18),
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () {
                                      final cur = int.tryParse(_totalVolumesController.text.trim()) ?? 1;
                                      if (cur > 1) {
                                        setState(() {
                                          _totalVolumesController.text = '${cur - 1}';
                                        });
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () {
                                      final cur = int.tryParse(_totalVolumesController.text.trim()) ?? 1;
                                      setState(() {
                                        _totalVolumesController.text = '${cur + 1}';
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                            validator: (val) {
                              final parsed = int.tryParse(val?.trim() ?? '');
                              if (parsed == null || parsed < 1) {
                                return 'Enter >= 1';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Currently Owned Count
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Currently Owned', style: theme.textTheme.titleSmall),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _ownedCountController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'e.g. 8',
                              prefixIcon: const Icon(Icons.inventory_2_outlined, size: 20),
                              suffixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline_rounded, size: 18),
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () {
                                      final cur = int.tryParse(_ownedCountController.text.trim()) ?? 0;
                                      if (cur > 0) {
                                        setState(() {
                                          _ownedCount = cur - 1;
                                          _ownedCountController.text = '$_ownedCount';
                                        });
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () {
                                      final cur = int.tryParse(_ownedCountController.text.trim()) ?? 0;
                                      setState(() {
                                        _ownedCount = cur + 1;
                                        _ownedCountController.text = '$_ownedCount';
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                            onChanged: (val) {
                              final parsed = int.tryParse(val.trim());
                              if (parsed != null && parsed >= 0) {
                                setState(() => _ownedCount = parsed);
                              }
                            },
                            validator: (val) {
                              final parsed = int.tryParse(val?.trim() ?? '');
                              if (parsed == null || parsed < 0) {
                                return 'Enter >= 0';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Mark Owned Checkbox
                if (_ownedCount > 0)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text('Mark Volumes 1 to $_ownedCount as Owned'),
                    subtitle: const Text('Auto-generates owned status for existing volumes'),
                    value: _markOwned,
                    activeColor: AppColors.caramelizedAmber,
                    onChanged: (val) => setState(() => _markOwned = val ?? true),
                  ),
                // Gift / Purchase toggle (shown when any owned volumes)
                if (_ownedCount > 0 && _markOwned) ...[
                  const SizedBox(height: 4),
                  _GiftPurchaseToggle(
                    isGift: _isGift,
                    onChanged: (val) => setState(() => _isGift = val),
                  ),
                ],
              ] else ...[
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: const Text('Mark this book as Owned'),
                  value: _markOwned,
                  activeColor: AppColors.caramelizedAmber,
                  onChanged: (val) => setState(() => _markOwned = val ?? true),
                ),
                // Gift / Purchase toggle (shown for standalone when owned)
                if (_markOwned) ...[
                  const SizedBox(height: 4),
                  _GiftPurchaseToggle(
                    isGift: _isGift,
                    onChanged: (val) => setState(() => _isGift = val),
                  ),
                ],
              ],
              const SizedBox(height: 14),

              // Collection Status & Release Status
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Collection Status', style: theme.textTheme.titleSmall),
                        const SizedBox(height: 6),
                        CaneleDropdown<String>(
                          value: _collectionStatus,
                          items: const [
                            DropdownMenuItem(value: 'active', child: Text('Active')),
                            DropdownMenuItem(value: 'wishlist', child: Text('Wishlist')),
                            DropdownMenuItem(value: 'completed', child: Text('Completed')),
                            DropdownMenuItem(value: 'dropped', child: Text('Dropped')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _collectionStatus = val;
                                if (val == 'completed') {
                                  _releaseStatus = 'completed';
                                  final total = int.tryParse(_totalVolumesController.text.trim()) ?? 1;
                                  _ownedCount = total;
                                  _ownedCountController.text = '$total';
                                  _markOwned = true;
                                  _isGift = false;
                                }
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Release Status', style: theme.textTheme.titleSmall),
                        const SizedBox(height: 6),
                        CaneleDropdown<String>(
                          value: _releaseStatus,
                          items: const [
                            DropdownMenuItem(value: 'ongoing', child: Text('Ongoing')),
                            DropdownMenuItem(value: 'completed', child: Text('Completed')),
                          ],
                          onChanged: (val) => setState(() => _releaseStatus = val!),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Default Volume Price (Optional)
              Text('Default Price Per Volume (Optional)', style: theme.textTheme.titleSmall),
              const SizedBox(height: 2),
              Text(
                'Used for all volumes in this series unless an explicit price is entered for a volume',
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _defaultVolPriceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        hintText: '14.99',
                        prefixIcon: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          child: CurrencySymbolText(
                            currencyCode: _selectedDefaultVolCurrency ?? CurrencyHelper.defaultVolumeCurrency,
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
                      value: _selectedDefaultVolCurrency ?? CurrencyHelper.defaultVolumeCurrency,
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedDefaultVolCurrency = val);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Series Combined Price (Optional)
              Text('Combined Series Price (Optional)', style: theme.textTheme.titleSmall),
              const SizedBox(height: 2),
              Text(
                'Sets a combined total price for the whole series/bundle instead of pricing individual volumes',
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
              ),
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
                            currencyCode: _selectedCurrency ?? ref.watch(ruleConfigNotifierProvider).currency,
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
                      value: _selectedCurrency ?? ref.watch(ruleConfigNotifierProvider).currency,
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedCurrency = val);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

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
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: const Text('Add Series'),
                    onPressed: () async {
                      if (!_formKey.currentState!.validate()) return;

                      final isCompleted = _collectionStatus == 'completed';
                      final totalVol = isMulti
                          ? (int.tryParse(_totalVolumesController.text.trim()) ?? 1)
                          : 1;

                      final owned = isCompleted
                          ? totalVol
                          : (isMulti ? _ownedCount : (_markOwned ? 1 : 0));
                      final markOwned = isCompleted ? true : _markOwned;
                      final isGift = isCompleted ? false : _isGift;

                      final parsedPrice = CurrencyHelper.parsePrice(_priceController.text);
                      final activeCurrency = _selectedCurrency ?? ref.read(ruleConfigNotifierProvider).currency;

                      final parsedDefaultVolPrice = CurrencyHelper.parsePrice(_defaultVolPriceController.text);
                      final activeDefaultVolCurrency = _selectedDefaultVolCurrency ?? CurrencyHelper.defaultVolumeCurrency;

                      final series = await ref.read(seriesNotifierProvider.notifier).createSeriesWithVolumes(
                        title: _titleController.text.trim(),
                        type: TypeHelper.normalizeKey(_selectedType ?? 'book'),
                        collectionStatus: _collectionStatus,
                        releaseStatus: isCompleted ? 'completed' : _releaseStatus,
                        totalReleasedVolumes: totalVol,
                        ownedCount: owned,
                        markOwned: markOwned,
                        isGift: isGift,
                        seriesPrice: parsedPrice > 0 ? parsedPrice : null,
                        currency: parsedPrice > 0 ? activeCurrency : null,
                        defaultVolumePrice: parsedDefaultVolPrice > 0 ? parsedDefaultVolPrice : CurrencyHelper.defaultVolumePrice,
                        defaultVolumeCurrency: parsedDefaultVolPrice > 0 ? activeDefaultVolCurrency : CurrencyHelper.defaultVolumeCurrency,
                      );

                      if (context.mounted) {
                        Navigator.of(context).pop(series.id);
                        ScaffoldMessenger.of(context)
                          ..clearSnackBars()
                          ..showSnackBar(
                          SnackBar(
                            content: Text(
                              'Created "${_titleController.text.trim()}" with $totalVol volume(s) generated!',
                            ),
                          ),
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
    ),
  );
}
}

/// Gift vs Purchase segmented toggle
class _GiftPurchaseToggle extends StatelessWidget {
  final bool isGift;
  final ValueChanged<bool> onChanged;

  const _GiftPurchaseToggle({
    required this.isGift,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<bool>(
        style: SegmentedButton.styleFrom(
          visualDensity: VisualDensity.compact,
          selectedBackgroundColor: AppColors.caramelizedAmber,
          selectedForegroundColor: Colors.white,
        ),
        segments: const [
          ButtonSegment<bool>(
            value: false,
            label: Text('Purchased'),
            icon: Icon(Icons.shopping_bag_outlined, size: 16),
          ),
          ButtonSegment<bool>(
            value: true,
            label: Text('Gift'),
            icon: Icon(Icons.card_giftcard_rounded, size: 16),
          ),
        ],
        selected: {isGift},
        onSelectionChanged: (sel) => onChanged(sel.first),
      ),
    );
  }
}

/// Helper to show AddSeriesSheet as a modal bottom sheet
Future<void> showAddSeriesSheet(BuildContext context) async {
  final createdSeriesId = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const AddSeriesSheet(),
  );

  if (createdSeriesId != null && context.mounted) {
    await SeriesStatusPromptHelper.checkAndPrompt(context, seriesId: createdSeriesId);
  }
}
