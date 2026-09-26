import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_helper.dart';
import '../../core/utils/uuid_generator.dart';
import '../../models/game_item.dart';
import '../../providers/series_provider.dart';
import '../../models/purchase_transaction.dart';
import 'canele_dropdown.dart';

void showAddGameSheet(BuildContext context, {GameItem? existingGame}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => AddGameSheet(existingGame: existingGame),
  );
}

class AddGameSheet extends ConsumerStatefulWidget {
  final GameItem? existingGame;

  const AddGameSheet({super.key, this.existingGame});

  @override
  ConsumerState<AddGameSheet> createState() => _AddGameSheetState();
}

class _AddGameSheetState extends ConsumerState<AddGameSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _editionController;
  late final TextEditingController _priceController;
  late final TextEditingController _coverUrlController;
  late final TextEditingController _playtimeController;
  late final TextEditingController _notesController;

  late String _selectedPlatformKey;
  late GameFormat _selectedFormat;
  late GameBacklogStatus _selectedStatus;
  String? _selectedCurrency;
  double? _rating;
  final bool _recordTransaction = true;

  final List<String> _commonEditions = [
    'Standard Edition',
    'Deluxe Edition',
    'Collector\'s Edition',
    'Steelbook Edition',
    'Complete Edition',
    'Limited Run',
  ];

  @override
  void initState() {
    super.initState();
    final g = widget.existingGame;

    _titleController = TextEditingController(text: g?.title ?? '');
    _editionController = TextEditingController(text: g?.edition ?? 'Standard Edition');
    _priceController = TextEditingController(
      text: (g?.price != null && g!.price! > 0)
          ? g.price!.toStringAsFixed(g.price! == g.price!.roundToDouble() ? 0 : 2)
          : '',
    );
    _coverUrlController = TextEditingController(text: g?.coverUrl ?? '');
    _playtimeController = TextEditingController(
      text: (g?.playtimeHours != null && g!.playtimeHours! > 0)
          ? g.playtimeHours!.toStringAsFixed(g.playtimeHours! == g.playtimeHours!.roundToDouble() ? 0 : 1)
          : '',
    );
    _notesController = TextEditingController(text: g?.notes ?? '');

    _selectedPlatformKey = g?.platform ?? 'ps5';
    _selectedFormat = g?.format ?? GameFormat.physical;
    _selectedStatus = g?.backlogStatus ?? GameBacklogStatus.backlog;
    _selectedCurrency = g?.currency ?? CurrencyHelper.defaultVolumeCurrency;
    _rating = g?.rating;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _editionController.dispose();
    _priceController.dispose();
    _coverUrlController.dispose();
    _playtimeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleController.text.trim();
    final edition = _editionController.text.trim().isEmpty ? 'Standard Edition' : _editionController.text.trim();
    final price = double.tryParse(_priceController.text.trim());
    final coverUrl = _coverUrlController.text.trim().isEmpty ? null : _coverUrlController.text.trim();
    final playtime = double.tryParse(_playtimeController.text.trim());
    final notes = _notesController.text.trim().isEmpty ? null : _notesController.text.trim();

    final isEditing = widget.existingGame != null;
    final gameId = widget.existingGame?.id ?? UuidGenerator.generate();

    final game = GameItem(
      id: gameId,
      title: title,
      platform: _selectedPlatformKey,
      edition: edition,
      format: _selectedFormat,
      backlogStatus: _selectedStatus,
      price: price,
      currency: _selectedCurrency,
      coverUrl: coverUrl,
      rating: _rating,
      playtimeHours: playtime,
      notes: notes,
      tags: widget.existingGame?.tags ?? [],
      releaseDate: widget.existingGame?.releaseDate,
    );

    // Save game into active workspace's series box
    await ref.read(seriesNotifierProvider.notifier).saveSeries(game.toSeries());

    // Record initial acquisition transaction if new and requested
    if (!isEditing && _recordTransaction && price != null && price > 0 && _selectedStatus != GameBacklogStatus.wishlist) {
      final tx = PurchaseTransaction(
        id: UuidGenerator.generate(),
        volumeId: gameId,
        purchaseDate: DateTime.now(),
        quotaBucket: 'regular',
        price: price,
        currency: _selectedCurrency,
        notes: '$title ($edition)',
      );
      await ref.read(transactionsNotifierProvider.notifier).saveTransaction(tx);
    }

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? 'Updated "$title"' : 'Added "$title" to Game Backlog!'),
          backgroundColor: AppColors.caramelizedAmber,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEditing = widget.existingGame != null;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkPastryCard : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Grab Handle
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkPastryBorder : AppColors.pastryCrustBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Sheet Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEditing ? 'Edit Game' : 'Add to Game Backlog',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Cancel',
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 1. Title Input
                TextFormField(
                  key: const Key('game_title_input'),
                  controller: _titleController,
                  autofocus: !isEditing,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Game Title',
                    hintText: 'e.g. Elden Ring, Metroid Dread, Persona 5',
                    prefixIcon: Icon(Icons.sports_esports_rounded, size: 20),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter a game title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // 2. Gaming Platform Selector
                Text(
                  'Platform',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextMuted : AppColors.deepCaramelMuted,
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: GamePlatform.presets.map((p) {
                      final isSelected = _selectedPlatformKey == p.key;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          key: Key('platform_chip_${p.key}'),
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                p.icon,
                                size: 14,
                                color: isSelected ? Colors.white : p.badgeColor,
                              ),
                              const SizedBox(width: 5),
                              Text(p.displayName),
                            ],
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) setState(() => _selectedPlatformKey = p.key);
                          },
                          selectedColor: p.badgeColor,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? AppColors.darkTextPrimary : AppColors.deepCaramel),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 18),

                // 3. Format & Backlog Status
                Row(
                  children: [
                    // Physical vs. Digital Toggle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Format',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkTextMuted : AppColors.deepCaramelMuted,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () => setState(() => _selectedFormat = GameFormat.physical),
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 9),
                                    decoration: BoxDecoration(
                                      color: _selectedFormat == GameFormat.physical
                                          ? AppColors.caramelizedAmber
                                          : (isDark ? AppColors.darkPastryCardElevated : AppColors.pastryCrustLight),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    alignment: Alignment.center,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.album_rounded,
                                          size: 14,
                                          color: _selectedFormat == GameFormat.physical ? Colors.white : AppColors.deepCaramelMuted,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Physical',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: _selectedFormat == GameFormat.physical ? Colors.white : AppColors.deepCaramelMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: InkWell(
                                  onTap: () => setState(() => _selectedFormat = GameFormat.digital),
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 9),
                                    decoration: BoxDecoration(
                                      color: _selectedFormat == GameFormat.digital
                                          ? AppColors.caramelizedAmber
                                          : (isDark ? AppColors.darkPastryCardElevated : AppColors.pastryCrustLight),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    alignment: Alignment.center,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.cloud_download_rounded,
                                          size: 14,
                                          color: _selectedFormat == GameFormat.digital ? Colors.white : AppColors.deepCaramelMuted,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Digital',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: _selectedFormat == GameFormat.digital ? Colors.white : AppColors.deepCaramelMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // 4. Backlog Status Picker
                Text(
                  'Backlog Status',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextMuted : AppColors.deepCaramelMuted,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: GameBacklogStatus.values.map((status) {
                    final isSelected = _selectedStatus == status;
                    return ChoiceChip(
                      key: Key('status_chip_${status.name}'),
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(status.icon, size: 14, color: isSelected ? Colors.white : status.color),
                          const SizedBox(width: 5),
                          Text(status.label),
                        ],
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedStatus = status);
                      },
                      selectedColor: status.color,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? AppColors.darkTextPrimary : AppColors.deepCaramel),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),

                // 5. Edition Field
                Autocomplete<String>(
                  initialValue: TextEditingValue(text: _editionController.text),
                  optionsBuilder: (textEditingValue) {
                    if (textEditingValue.text.isEmpty) return _commonEditions;
                    return _commonEditions.where((opt) =>
                        opt.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                  },
                  onSelected: (val) => _editionController.text = val,
                  fieldViewBuilder: (ctx, controller, focusNode, onFieldSubmitted) {
                    _editionController.text = controller.text.isEmpty ? _editionController.text : controller.text;
                    return TextFormField(
                      controller: controller..text = _editionController.text,
                      focusNode: focusNode,
                      decoration: const InputDecoration(
                        labelText: 'Edition',
                        hintText: 'e.g. Standard, Deluxe, Collector\'s Edition',
                        prefixIcon: Icon(Icons.bookmark_outline_rounded, size: 20),
                      ),
                      onChanged: (val) => _editionController.text = val,
                    );
                  },
                ),
                const SizedBox(height: 18),

                // 6. Price & Currency
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        key: const Key('game_price_input'),
                        controller: _priceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Price Paid',
                          hintText: '0.00',
                          prefixIcon: Icon(Icons.payments_outlined, size: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: CaneleDropdown<String>(
                        value: _selectedCurrency,
                        items: CurrencyHelper.supportedCurrencies
                            .map((c) => DropdownMenuItem(
                                  value: c.code,
                                  child: Text('${c.code} (${c.symbol})', style: const TextStyle(fontSize: 14)),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedCurrency = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // 7. Cover Image URL
                TextFormField(
                  controller: _coverUrlController,
                  keyboardType: TextInputType.url,
                  decoration: InputDecoration(
                    labelText: 'Cover Art Image URL (Optional)',
                    hintText: 'https://.../cover.jpg',
                    prefixIcon: const Icon(Icons.image_outlined, size: 20),
                    suffixIcon: _coverUrlController.text.trim().isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () => setState(() => _coverUrlController.clear()),
                          )
                        : null,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 18),

                // 8. Playtime & Rating
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _playtimeController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Hours Played',
                          hintText: 'e.g. 24.5',
                          prefixIcon: Icon(Icons.timer_outlined, size: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        initialValue: _rating?.toStringAsFixed(1) ?? '',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Rating (1 - 10)',
                          hintText: 'e.g. 9.5',
                          prefixIcon: Icon(Icons.star_outline_rounded, size: 20),
                        ),
                        onChanged: (val) {
                          final parsed = double.tryParse(val.trim());
                          if (parsed != null && parsed >= 0 && parsed <= 10) {
                            _rating = parsed;
                          } else if (val.trim().isEmpty) {
                            _rating = null;
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // 9. Notes
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Backlog Notes / Thoughts',
                    hintText: 'e.g. Great story, beat boss on chapter 4, backlog priority high...',
                    prefixIcon: Icon(Icons.edit_note_rounded, size: 20),
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    key: const Key('save_game_button'),
                    onPressed: _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.caramelizedAmber,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      isEditing ? 'Save Changes' : 'Add to Collection',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
