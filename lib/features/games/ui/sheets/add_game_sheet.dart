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

enum GameStructureType { series, standalone }

class AddGameSheet extends ConsumerStatefulWidget {
  const AddGameSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const AddGameSheet(),
    );
  }

  @override
  ConsumerState<AddGameSheet> createState() => _AddGameSheetState();
}

class _AddGameSheetState extends ConsumerState<AddGameSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _totalGamesController = TextEditingController(text: '3');
  final _priceController = TextEditingController(text: '59.99');

  GameStructureType _structure = GameStructureType.series;

  // Acquisition / Collection Status
  String _collectionStatus = 'active'; // 'active', 'completed' (acquired), 'wishlist', 'dropped'

  // Standalone game fields
  bool _standaloneOwned = false;
  bool _isGift = false;
  bool _isPriorityTarget = false;
  GameAvailability _standaloneAvailability = GameAvailability.available;

  // Franchise fields
  int _ownedGamesCount = 0;
  bool _franchiseOwnedAsGift = false;
  String _seriesReleaseStatus = 'ongoing'; // 'ongoing', 'completed'

  String? _selectedCurrency;

  @override
  void dispose() {
    _titleController.dispose();
    _totalGamesController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _onToggleStandaloneOwned(bool val) {
    setState(() {
      _standaloneOwned = val;
      if (val) {
        _collectionStatus = 'completed'; // Automatically set to Acquired / Completed
      } else {
        if (_collectionStatus == 'completed') {
          _collectionStatus = 'active'; // Revert back to active planning
        }
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleController.text.trim();
    final isStandalone = _structure == GameStructureType.standalone;
    final seriesId = UuidGenerator.generate();
    final currency = _selectedCurrency ?? ref.read(ruleConfigNotifierProvider).currency;
    final parsedPrice = CurrencyHelper.parsePrice(_priceController.text);

    final gameSeries = GameSeries(
      id: seriesId,
      title: title,
      isStandalone: isStandalone,
      collectionStatus: _collectionStatus,
      releaseStatus: isStandalone ? 'completed' : _seriesReleaseStatus,
      defaultGamePrice: parsedPrice > 0 ? parsedPrice : null,
      defaultCurrency: currency,
      tags: const [],
    );

    await ref.read(gameSeriesNotifierProvider.notifier).saveSeries(gameSeries);

    if (isStandalone) {
      final gameItem = GameItem(
        id: UuidGenerator.generate(),
        seriesId: seriesId,
        title: title,
        itemType: GameItemType.game,
        gameNumber: 1.0,
        isOwned: _standaloneOwned,
        isGift: _isGift,
        price: parsedPrice > 0 ? parsedPrice : null,
        currency: currency,
        availability: _standaloneAvailability,
        isPriorityTarget: _isPriorityTarget,
      );

      await ref.read(gameItemsNotifierProvider.notifier).saveItem(gameItem);

      if (_standaloneOwned && parsedPrice > 0) {
        final quotaSummary = ref.read(quotaProvider);
        final tx = PurchaseTransaction(
          id: UuidGenerator.generate(),
          volumeId: gameItem.id,
          purchaseDate: DateTime.now(),
          quotaBucket: _isGift ? 'gift' : quotaSummary.suggestedAutoBucket,
          price: _isGift ? 0.0 : parsedPrice,
          currency: currency,
          notes: _isGift ? 'Gift / Free Claim' : 'Game initial purchase',
        );
        await ref.read(transactionsNotifierProvider.notifier).saveTransaction(tx);
      }
    } else {
      // Create N installments for franchise
      final totalGames = int.tryParse(_totalGamesController.text.trim()) ?? 1;
      final quotaSummary = ref.read(quotaProvider);

      for (int i = 1; i <= totalGames; i++) {
        final isOwned = i <= _ownedGamesCount;
        final isGift = isOwned && _franchiseOwnedAsGift;
        final gameItem = GameItem(
          id: UuidGenerator.generate(),
          seriesId: seriesId,
          title: '$title $i',
          itemType: GameItemType.game,
          gameNumber: i.toDouble(),
          isOwned: isOwned,
          isGift: isGift,
          price: parsedPrice > 0 ? parsedPrice : null,
          currency: currency,
          availability: GameAvailability.available,
          isPriorityTarget: false,
        );
        await ref.read(gameItemsNotifierProvider.notifier).saveItem(gameItem);

        if (isOwned && parsedPrice > 0) {
          final tx = PurchaseTransaction(
            id: UuidGenerator.generate(),
            volumeId: gameItem.id,
            purchaseDate: DateTime.now(),
            quotaBucket: isGift ? 'gift' : quotaSummary.suggestedAutoBucket,
            price: isGift ? 0.0 : parsedPrice,
            currency: currency,
            notes: isGift ? 'Initial franchise gift' : 'Initial franchise purchase',
          );
          await ref.read(transactionsNotifierProvider.notifier).saveTransaction(tx);
        }
      }
    }

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(
              _collectionStatus == 'completed'
                  ? 'Acquired "$title" added to collection!'
                  : 'Added "$title" to acquisition tracker!',
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
    final isStandalone = _structure == GameStructureType.standalone;

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
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.caramelizedAmber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.sports_esports_rounded,
                            color: AppColors.caramelizedAmber,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          isStandalone ? 'Add Standalone Game' : 'Add Game Franchise',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.deepCaramel,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Structure Selector: Franchise vs Standalone Game
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<GameStructureType>(
                    style: SegmentedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      selectedBackgroundColor: AppColors.caramelizedAmber,
                      selectedForegroundColor: Colors.white,
                    ),
                    segments: const [
                      ButtonSegment<GameStructureType>(
                        value: GameStructureType.series,
                        label: Text('Game Franchise'),
                        icon: Icon(Icons.view_carousel_outlined, size: 16),
                      ),
                      ButtonSegment<GameStructureType>(
                        value: GameStructureType.standalone,
                        label: Text('Standalone Game'),
                        icon: Icon(Icons.sports_esports_outlined, size: 16),
                      ),
                    ],
                    selected: {_structure},
                    onSelectionChanged: (sel) {
                      setState(() {
                        _structure = sel.first;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Title Field
                Text(
                  isStandalone ? 'Game Title' : 'Franchise Title',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _titleController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: isStandalone
                        ? 'e.g. Elden Ring, Chrono Trigger, Hollow Knight'
                        : 'e.g. Dark Souls, Final Fantasy, Witcher, Half-Life',
                    prefixIcon: const Icon(Icons.title_rounded, size: 20),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Title is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Acquisition Status (Addressing Point 4 fully)
                Text('Acquisition Status', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _collectionStatus,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.bookmark_outline_rounded, size: 20),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'active',
                      child: Text('Active (Plan acquisitions in monthly budget)'),
                    ),
                    DropdownMenuItem(
                      value: 'completed',
                      child: Text('Acquired / Owned (Already in collection)'),
                    ),
                    DropdownMenuItem(
                      value: 'wishlist',
                      child: Text('Wishlist (Backlog / queued for later)'),
                    ),
                    DropdownMenuItem(
                      value: 'dropped',
                      child: Text('Dropped (No longer acquiring)'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _collectionStatus = val;
                        if (val == 'completed') {
                          _standaloneOwned = true;
                        } else if (val == 'active' || val == 'wishlist') {
                          _standaloneOwned = false;
                        }
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Structure-Specific Details Card
                if (isStandalone) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkPastryCardElevated : AppColors.pastryCrustLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? AppColors.darkPastryBorder : AppColors.pastryCrustBorder,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Already Owned / Acquired?'),
                          subtitle: const Text('Mark this game as already purchased or in your collection'),
                          activeThumbColor: AppColors.caramelizedAmber,
                          value: _standaloneOwned,
                          onChanged: _onToggleStandaloneOwned,
                        ),
                        const Divider(height: 16),

                        if (_standaloneOwned) ...[
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Acquired as Gift / Free'),
                            subtitle: const Text('Does not count against purchase expenses'),
                            activeThumbColor: AppColors.caramelizedAmber,
                            value: _isGift,
                            onChanged: (val) => setState(() => _isGift = val),
                          ),
                          const SizedBox(height: 8),
                          Text('Acquisition Price', style: theme.textTheme.titleSmall),
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
                                    if (val != null) setState(() => _selectedCurrency = val);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          Text('Target Price (Optional)', style: theme.textTheme.titleSmall),
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
                                    if (val != null) setState(() => _selectedCurrency = val);
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text('Availability', style: theme.textTheme.titleSmall),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<GameAvailability>(
                            initialValue: _standaloneAvailability,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.event_available_rounded, size: 20),
                            ),
                            items: const [
                              DropdownMenuItem(value: GameAvailability.available, child: Text('Released / Buyable Now')),
                              DropdownMenuItem(value: GameAvailability.upcoming, child: Text('Upcoming / Announced (Pre-order)')),
                              DropdownMenuItem(value: GameAvailability.delisted, child: Text('Delisted / Not for sale')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _standaloneAvailability = val);
                            },
                          ),
                          const SizedBox(height: 12),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Watchlist Priority Target'),
                            subtitle: const Text('Flag as high-priority target to buy next'),
                            activeThumbColor: AppColors.caramelizedAmber,
                            value: _isPriorityTarget,
                            onChanged: (val) => setState(() => _isPriorityTarget = val),
                          ),
                        ],
                      ],
                    ),
                  ),
                ] else ...[
                  // Franchise Details Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkPastryCardElevated : AppColors.pastryCrustLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? AppColors.darkPastryBorder : AppColors.pastryCrustBorder,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total Games in Franchise', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(
                          'Estimated total main installments in this series',
                          style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _totalGamesController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: '3',
                            prefixIcon: Icon(Icons.format_list_numbered_rounded, size: 20),
                          ),
                          validator: (val) {
                            final parsed = int.tryParse(val?.trim() ?? '');
                            if (parsed == null || parsed < 1) {
                              return 'Enter at least 1 game';
                            }
                            return null;
                          },
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 14),

                        // Owned Count Stepper
                        () {
                          final totalGames = int.tryParse(_totalGamesController.text.trim()) ?? 1;
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Already Owned Games', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                                  Text(
                                    'Games 1 to $_ownedGamesCount marked owned',
                                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline),
                                    onPressed: _ownedGamesCount > 0 ? () => setState(() => _ownedGamesCount--) : null,
                                  ),
                                  Text(
                                    '$_ownedGamesCount / $totalGames',
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline),
                                    onPressed: _ownedGamesCount < totalGames ? () => setState(() => _ownedGamesCount++) : null,
                                  ),
                                ],
                              ),
                            ],
                          );
                        }(),
                        if (_ownedGamesCount > 0) ...[
                          const SizedBox(height: 8),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Mark Owned Games as Gifts / Free'),
                            subtitle: const Text('Games 1 to owned count will not deduct from budget'),
                            activeThumbColor: AppColors.caramelizedAmber,
                            value: _franchiseOwnedAsGift,
                            onChanged: (val) => setState(() => _franchiseOwnedAsGift = val),
                          ),
                        ],
                        const SizedBox(height: 14),

                        Text('Default Price Per Game', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
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
                                  if (val != null) setState(() => _selectedCurrency = val);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        Text('Franchise Status', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _seriesReleaseStatus,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.sync_rounded, size: 20),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'ongoing', child: Text('Ongoing (More games planned/releasing)')),
                            DropdownMenuItem(value: 'completed', child: Text('Completed (Franchise finished)')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _seriesReleaseStatus = val);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 8),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      _collectionStatus == 'completed'
                          ? 'Add Acquired Game'
                          : 'Save to Acquisition Tracker',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
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
