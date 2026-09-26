import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_helper.dart';
import '../../core/utils/uuid_generator.dart';
import '../../core/utils/workspace_terminology.dart';
import '../../models/custom_item.dart';
import '../../models/profile.dart';
import '../../providers/series_provider.dart';
import 'canele_dropdown.dart';

void showAddCustomItemSheet(BuildContext context, Profile profile, {CustomItem? existingItem}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => AddCustomItemSheet(profile: profile, existingItem: existingItem),
  );
}

class AddCustomItemSheet extends ConsumerStatefulWidget {
  final Profile profile;
  final CustomItem? existingItem;

  const AddCustomItemSheet({
    super.key,
    required this.profile,
    this.existingItem,
  });

  @override
  ConsumerState<AddCustomItemSheet> createState() => _AddCustomItemSheetState();
}

class _AddCustomItemSheetState extends ConsumerState<AddCustomItemSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _groupController;
  late final TextEditingController _editionController;
  late final TextEditingController _platformController;
  late final TextEditingController _priceController;
  late final TextEditingController _coverUrlController;
  late final TextEditingController _notesController;

  late String _selectedStatus;
  String? _selectedCurrency;
  double? _rating;
  DateTime? _selectedReleaseDate;

  @override
  void initState() {
    super.initState();
    final item = widget.existingItem;
    final terms = widget.profile.terms;

    _titleController = TextEditingController(text: item?.title ?? '');
    _groupController = TextEditingController(text: item?.groupTitle ?? '');
    _editionController = TextEditingController(text: item?.edition ?? '');
    _platformController = TextEditingController(text: item?.platform ?? '');
    _priceController = TextEditingController(
      text: (item?.price != null && item!.price! > 0)
          ? item.price!.toStringAsFixed(item.price! == item.price!.roundToDouble() ? 0 : 2)
          : '',
    );
    _coverUrlController = TextEditingController(text: item?.coverUrl ?? '');
    _notesController = TextEditingController(text: item?.notes ?? '');

    final available = terms.availableStatuses;
    _selectedStatus = item?.status ?? (available.isNotEmpty ? available.first.key : 'backlog');
    _selectedCurrency = item?.currency ?? CurrencyHelper.defaultVolumeCurrency;
    _rating = item?.rating;
    _selectedReleaseDate = item?.releaseDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _groupController.dispose();
    _editionController.dispose();
    _platformController.dispose();
    _priceController.dispose();
    _coverUrlController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final isEditing = widget.existingItem != null;
    final title = _titleController.text.trim();
    final group = _groupController.text.trim().isEmpty ? null : _groupController.text.trim();
    final edition = _editionController.text.trim().isEmpty ? null : _editionController.text.trim();
    final platform = _platformController.text.trim().isEmpty ? null : _platformController.text.trim();
    final price = CurrencyHelper.parsePrice(_priceController.text);
    final coverUrl = _coverUrlController.text.trim().isEmpty ? null : _coverUrlController.text.trim();
    final notes = _notesController.text.trim().isEmpty ? null : _notesController.text.trim();

    final item = CustomItem(
      id: widget.existingItem?.id ?? 'custom_${UuidGenerator.generate()}',
      title: title,
      groupTitle: group,
      status: _selectedStatus,
      edition: edition,
      platform: platform,
      price: price > 0 ? price : null,
      currency: _selectedCurrency,
      coverUrl: coverUrl,
      releaseDate: _selectedReleaseDate,
      rating: _rating,
      notes: notes,
      tags: widget.existingItem?.tags ?? [],
      customFields: widget.existingItem?.customFields ?? {},
    );

    await ref.read(seriesNotifierProvider.notifier).saveSeries(item.toSeries());

    if (mounted) {
      Navigator.of(context).pop();
      final terms = widget.profile.terms;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing
              ? 'Updated "${item.title}"'
              : 'Added "${item.title}" to ${terms.itemsLabel}!'),
          backgroundColor: AppColors.caramelizedAmber,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final terms = widget.profile.terms;
    final isEditing = widget.existingItem != null;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final showCover = terms.isFieldEnabled('coverUrl');
    final showPrice = terms.isFieldEnabled('price');
    final showReleaseDate = terms.isFieldEnabled('releaseDate');
    final showEdition = terms.isFieldEnabled('edition');
    final showPlatform = terms.isFieldEnabled('platform');
    final showRating = terms.isFieldEnabled('rating');
    final showNotes = terms.isFieldEnabled('notes');

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.90),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkPastryCard : theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: bottomInset + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle
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

            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEditing ? 'Edit ${terms.itemLabel}' : 'Add ${terms.itemLabel}',
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

            // Scrollable Form Fields
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Title Input
                    TextFormField(
                      key: const Key('custom_item_title_input'),
                      controller: _titleController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: '${terms.itemLabel} Title',
                        hintText: 'e.g. Abbey Road, Gundam Aerial, Issue #1',
                        prefixIcon: const Icon(Icons.label_outline_rounded, size: 20),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter a ${terms.itemLabel.toLowerCase()} title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // 2. Group Input (Artist / Manufacturer / Publisher)
                    TextFormField(
                      controller: _groupController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: terms.groupLabel,
                        hintText: 'e.g. The Beatles, Bandai, DC Comics',
                        prefixIcon: const Icon(Icons.folder_outlined, size: 20),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 3. Status Selector
                    Text(
                      'Status',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextMuted : AppColors.deepCaramelMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: terms.availableStatuses.map((s) {
                        final isSelected = _selectedStatus.toLowerCase() == s.key.toLowerCase();
                        return ChoiceChip(
                          key: Key('custom_status_chip_${s.key}'),
                          label: Text(s.label),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) setState(() => _selectedStatus = s.key);
                          },
                          selectedColor: s.color,
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

                    // 4. Edition & Platform / Category (if enabled)
                    if (showEdition || showPlatform) ...[
                      Row(
                        children: [
                          if (showEdition)
                            Expanded(
                              child: TextFormField(
                                controller: _editionController,
                                decoration: const InputDecoration(
                                  labelText: 'Edition / Pressing',
                                  hintText: 'e.g. 1st Press, Deluxe',
                                  prefixIcon: Icon(Icons.stars_outlined, size: 20),
                                ),
                              ),
                            ),
                          if (showEdition && showPlatform) const SizedBox(width: 12),
                          if (showPlatform)
                            Expanded(
                              child: TextFormField(
                                controller: _platformController,
                                decoration: const InputDecoration(
                                  labelText: 'Category / Format',
                                  hintText: 'e.g. Vinyl, 1/7 Scale',
                                  prefixIcon: Icon(Icons.category_outlined, size: 20),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 18),
                    ],

                    // 5. Price & Currency (if enabled)
                    if (showPrice) ...[
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
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
                    ],

                    // Release / Acquisition Date (if enabled)
                    if (showReleaseDate) ...[
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedReleaseDate ?? DateTime.now(),
                            firstDate: DateTime(1900),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() => _selectedReleaseDate = picked);
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Release / Acquisition Date',
                            prefixIcon: Icon(Icons.calendar_today_outlined, size: 20),
                          ),
                          child: Text(
                            _selectedReleaseDate != null
                                ? '${_selectedReleaseDate!.year}-${_selectedReleaseDate!.month.toString().padLeft(2, '0')}-${_selectedReleaseDate!.day.toString().padLeft(2, '0')}'
                                : 'Select date (optional)',
                            style: TextStyle(
                              color: _selectedReleaseDate != null
                                  ? (isDark ? AppColors.darkTextPrimary : AppColors.deepCaramel)
                                  : (isDark ? AppColors.darkTextMuted : AppColors.deepCaramelMuted),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],

                    // 6. Cover URL (if enabled)
                    if (showCover) ...[
                      TextFormField(
                        controller: _coverUrlController,
                        keyboardType: TextInputType.url,
                        decoration: const InputDecoration(
                          labelText: 'Cover Image URL',
                          hintText: 'https://...',
                          prefixIcon: Icon(Icons.image_outlined, size: 20),
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],

                    // 7. Rating & Notes (if enabled)
                    if (showRating) ...[
                      TextFormField(
                        initialValue: _rating?.toStringAsFixed(1) ?? '',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Rating (1 - 10)',
                          hintText: 'e.g. 9.0',
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
                      const SizedBox(height: 18),
                    ],

                    if (showNotes) ...[
                      TextFormField(
                        controller: _notesController,
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Notes & Thoughts',
                          hintText: 'e.g. Mastered at Abbey Road, pristine condition...',
                          prefixIcon: Icon(Icons.edit_note_rounded, size: 20),
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                key: const Key('submit_custom_item_button'),
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.caramelizedAmber,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  isEditing ? 'Save Changes' : 'Add ${terms.itemLabel}',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
