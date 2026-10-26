import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_helper.dart';
import '../../../../core/utils/uuid_generator.dart';
import '../../../../models/purchase_transaction.dart';
import '../../../../providers/quota_provider.dart';
import '../../../../providers/series_provider.dart';
import '../../../../ui/widgets/canele_card.dart';
import '../../../../ui/widgets/canele_progress_bar.dart';
import '../../models/game_item.dart';
import '../../models/game_series.dart';
import '../../providers/game_providers.dart';
import '../sheets/edit_game_series_sheet.dart';
import '../sheets/edit_game_item_sheet.dart';
import '../sheets/log_game_acquisition_sheet.dart';

class GameDetailScreen extends ConsumerStatefulWidget {
  final String seriesId;

  const GameDetailScreen({super.key, required this.seriesId});

  @override
  ConsumerState<GameDetailScreen> createState() => _GameDetailScreenState();
}

class _GameDetailScreenState extends ConsumerState<GameDetailScreen> {
  String _filter = 'all'; // 'all', 'missing', 'owned'

  void _showAddItemDialog({required bool isDlc, required double nextNumber, required GameSeries series}) async {
    final titleController = TextEditingController(
      text: isDlc ? '${series.title} DLC' : '${series.title} ${nextNumber.toInt()}',
    );
    final priceController = TextEditingController(
      text: series.defaultGamePrice != null && series.defaultGamePrice! > 0
          ? series.defaultGamePrice!.toStringAsFixed(
              series.defaultGamePrice == series.defaultGamePrice!.roundToDouble() ? 0 : 2)
          : '',
    );
    bool isOwned = false;
    bool isGift = false;
    bool isPriorityTarget = false;
    GameAvailability availability = GameAvailability.available;
    String currency = series.defaultCurrency ?? ref.read(ruleConfigNotifierProvider).currency;

    final added = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isDlc ? 'Add DLC / Expansion' : 'Add Game Installment'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Title', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    TextField(controller: titleController),
                    const SizedBox(height: 12),

                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Already Owned / Acquired'),
                      activeThumbColor: AppColors.caramelizedAmber,
                      value: isOwned,
                      onChanged: (val) {
                        setDialogState(() {
                          isOwned = val;
                          if (!val) isGift = false;
                        });
                      },
                    ),

                    if (isOwned) ...[
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Acquired as Gift / Free Claim'),
                        subtitle: const Text('Does not count against acquisition budget'),
                        activeThumbColor: AppColors.caramelizedAmber,
                        value: isGift,
                        onChanged: (val) => setDialogState(() => isGift = val),
                      ),
                      const SizedBox(height: 8),
                    ],

                    if (!isOwned) ...[
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Watchlist Priority Target'),
                        subtitle: const Text('Prioritize buying this next'),
                        activeThumbColor: AppColors.caramelizedAmber,
                        value: isPriorityTarget,
                        onChanged: (val) => setDialogState(() => isPriorityTarget = val),
                      ),
                      const SizedBox(height: 8),

                      const Text('Availability', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<GameAvailability>(
                        initialValue: availability,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: GameAvailability.available, child: Text('Released / Buyable Now')),
                          DropdownMenuItem(value: GameAvailability.upcoming, child: Text('Upcoming / Announced (Pre-order)')),
                          DropdownMenuItem(value: GameAvailability.delisted, child: Text('Delisted / Not for sale')),
                        ],
                        onChanged: (val) {
                          if (val != null) setDialogState(() => availability = val);
                        },
                      ),
                      const SizedBox(height: 12),
                    ],

                    const Text('Price (Optional)', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: priceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              hintText: isGift ? '0.00 (Gift)' : '59.99',
                              prefixIcon: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                child: CurrencySymbolText(currencyCode: currency, baseFontSize: 15, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: CurrencyDropdownField(
                            value: currency,
                            onChanged: (val) {
                              if (val != null) setDialogState(() => currency = val);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );

    if (added == true && mounted) {
      final parsedPrice = CurrencyHelper.parsePrice(priceController.text);
      final newItem = GameItem(
        id: UuidGenerator.generate(),
        seriesId: series.id,
        title: titleController.text.trim(),
        itemType: isDlc ? GameItemType.dlc : GameItemType.game,
        gameNumber: nextNumber,
        isOwned: isOwned,
        isGift: isGift,
        price: parsedPrice > 0 ? parsedPrice : null,
        currency: currency,
        availability: availability,
        isPriorityTarget: isPriorityTarget,
      );

      await ref.read(gameItemsNotifierProvider.notifier).saveItem(newItem);

      if (isOwned) {
        final quotaSummary = ref.read(quotaProvider);
        final bucket = isGift ? 'gift' : quotaSummary.suggestedAutoBucket;
        final finalPrice = isGift ? 0.0 : (parsedPrice > 0 ? parsedPrice : (series.defaultGamePrice ?? 0.0));
        final tx = PurchaseTransaction(
          id: UuidGenerator.generate(),
          volumeId: newItem.id,
          purchaseDate: DateTime.now(),
          quotaBucket: bucket,
          price: finalPrice,
          currency: currency,
          notes: isGift ? 'Gift / Free Claim' : 'Added owned installment',
        );
        await ref.read(transactionsNotifierProvider.notifier).saveTransaction(tx);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final allSeries = ref.watch(gameSeriesNotifierProvider);
    final series = allSeries.cast<GameSeries?>().firstWhere(
          (s) => s?.id == widget.seriesId,
          orElse: () => null,
        );

    if (series == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Game Details')),
        body: const Center(child: Text('Game not found')),
      );
    }

    final allItems = ref.watch(gameItemsNotifierProvider);
    final seriesItems = allItems.where((i) => i.seriesId == series.id).toList()
      ..sort((a, b) => a.gameNumber.compareTo(b.gameNumber));

    final games = seriesItems.where((i) => i.itemType == GameItemType.game).toList();
    final dlcs = seriesItems.where((i) => i.itemType == GameItemType.dlc).toList();

    final ownedGamesCount = games.where((i) => i.isOwned).length;
    final totalGamesCount = games.length;
    final ownedDlcsCount = dlcs.where((i) => i.isOwned).length;
    final totalDlcsCount = dlcs.length;

    final filteredItems = seriesItems.where((i) {
      if (_filter == 'missing') return !i.isOwned;
      if (_filter == 'owned') return i.isOwned;
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(series.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Details',
            onPressed: () => EditGameSeriesSheet.show(context, series: series),
          ),
          PopupMenuButton<String>(
            onSelected: (val) async {
              if (val == 'complete') {
                for (final item in seriesItems) {
                  if (!item.isOwned) {
                    await ref.read(gameItemsNotifierProvider.notifier).toggleOwned(item.id, true);
                  }
                }
                await ref.read(gameSeriesNotifierProvider.notifier).markCompleted(series.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Marked "${series.title}" as Acquired!'),
                      backgroundColor: AppColors.statusSuccess,
                    ),
                  );
                }
              } else if (val == 'delete') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete from Collection?'),
                    content: Text('Are you sure you want to delete "${series.title}" and all its installments and DLCs?'),
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
                  for (final item in seriesItems) {
                    await ref.read(gameItemsNotifierProvider.notifier).deleteItem(item.id);
                  }
                  await ref.read(gameSeriesNotifierProvider.notifier).deleteSeries(series.id);
                  if (context.mounted) Navigator.pop(context);
                }
              }
            },
            itemBuilder: (ctx) => [
              if (series.collectionStatus != 'completed')
                const PopupMenuItem(
                  value: 'complete',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline_rounded, color: AppColors.statusSuccess, size: 20),
                      SizedBox(width: 8),
                      Text('Mark as Fully Acquired'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded, color: AppColors.statusDanger, size: 20),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: AppColors.statusDanger)),
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
                          series.isStandalone ? 'STANDALONE GAME' : 'GAME FRANCHISE',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.caramelizedAmber,
                          ),
                        ),
                      ),
                      _buildStatusPill(series.collectionStatus, isDark),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Text(
                    series.title,
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),

                  if (!series.isStandalone) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$ownedGamesCount of $totalGamesCount Games Acquired',
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        if (totalDlcsCount > 0)
                          Text(
                            '$ownedDlcsCount of $totalDlcsCount DLCs',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.caramelizedAmber),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    CaneleProgressBar(
                      value: totalGamesCount > 0 ? (ownedGamesCount / totalGamesCount) : 0.0,
                      height: 8,
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Icon(
                          ownedGamesCount > 0 ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                          color: ownedGamesCount > 0 ? AppColors.statusSuccess : AppColors.caramelizedAmber,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          ownedGamesCount > 0 ? 'Acquired and Owned' : 'Planned for Acquisition',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: ownedGamesCount > 0 ? AppColors.statusSuccess : AppColors.caramelizedAmber,
                          ),
                        ),
                        if (series.defaultGamePrice != null && series.defaultGamePrice! > 0) ...[
                          const Spacer(),
                          Text(
                            '${series.defaultCurrency ?? '\$'} ${series.defaultGamePrice!.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Filter Tabs & Add Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SegmentedButton<String>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: 'all', label: Text('All')),
                    ButtonSegment(value: 'missing', label: Text('Missing')),
                    ButtonSegment(value: 'owned', label: Text('Acquired')),
                  ],
                  selected: {_filter},
                  onSelectionChanged: (set) => setState(() => _filter = set.first),
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                PopupMenuButton<String>(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.caramelizedAmber,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded, color: Colors.white, size: 18),
                        SizedBox(width: 4),
                        Text('Add...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                      ],
                    ),
                  ),
                  onSelected: (val) {
                    if (val == 'game') {
                      double maxNum = 0.0;
                      for (final g in games) {
                        if (g.gameNumber > maxNum) maxNum = g.gameNumber;
                      }
                      _showAddItemDialog(
                        isDlc: false,
                        nextNumber: maxNum > 0 ? maxNum + 1.0 : 1.0,
                        series: series,
                      );
                    } else if (val == 'dlc') {
                      double maxDlc = 0.5;
                      for (final d in dlcs) {
                        if (d.gameNumber > maxDlc) maxDlc = d.gameNumber;
                      }
                      _showAddItemDialog(
                        isDlc: true,
                        nextNumber: maxDlc + 0.1,
                        series: series,
                      );
                    }
                  },
                  itemBuilder: (ctx) => [
                    if (!series.isStandalone)
                      const PopupMenuItem(
                        value: 'game',
                        child: Row(
                          children: [
                            Icon(Icons.sports_esports_rounded, color: AppColors.caramelizedAmber, size: 20),
                            SizedBox(width: 8),
                            Text('Add Game Installment'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'dlc',
                      child: Row(
                        children: [
                          Icon(Icons.extension_rounded, color: AppColors.caramelizedAmber, size: 20),
                          SizedBox(width: 8),
                          Text('Add DLC / Expansion'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Items List
            if (filteredItems.isEmpty) ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text('No items match the selected filter', style: theme.textTheme.bodyMedium),
                ),
              ),
            ] else ...[
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredItems.length,
                itemBuilder: (context, index) {
                  final item = filteredItems[index];
                  final isDlc = item.itemType == GameItemType.dlc;

                  return CaneleCard(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    onTap: () => EditGameItemSheet.show(context, item: item, series: series),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Quick Ownership Toggle
                        IconButton(
                          onPressed: () async {
                            if (!item.isOwned) {
                              await LogGameAcquisitionSheet.show(
                                context,
                                series: series,
                                item: item,
                              );
                            } else {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: Text('Mark "${item.title}" as Unacquired?'),
                                  content: const Text(
                                    'This will remove this game from your acquired library and delete its purchase record from your quota ledger.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusDanger),
                                      child: const Text('Mark Unacquired'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                await ref.read(gameItemsNotifierProvider.notifier).toggleOwned(item.id, false);
                                final allTxs = ref.read(transactionsNotifierProvider);
                                final existingTx = allTxs.cast<PurchaseTransaction?>().firstWhere(
                                      (t) => t?.volumeId == item.id,
                                      orElse: () => null,
                                    );
                                if (existingTx != null) {
                                  await ref.read(transactionsNotifierProvider.notifier).deleteTransaction(existingTx.id);
                                }
                              }
                            }
                          },
                          icon: Icon(
                            item.isOwned
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            color: item.isOwned
                                ? (isDark ? AppColors.caramelizedAmberLight : AppColors.caramelizedAmber)
                                : (isDark ? AppColors.darkTextMuted : AppColors.pastryCrustBorder),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Item Details (Title + Sub-row with Badges/Price)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Row 1: Badge + Title
                              Row(
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(right: 6),
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
                                  Expanded(
                                    child: Text(
                                      item.title,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        decoration: item.isOwned ? TextDecoration.lineThrough : null,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),

                              // Row 2: Gift Badge, Availability Badge, Formatted Price
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  if (item.isOwned && item.isGift)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isDark ? AppColors.darkPastryCardElevated : AppColors.pastryCrustLight,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: isDark ? AppColors.darkPastryBorder : AppColors.pastryCrustBorder,
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Text(
                                        'GIFT',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: isDark ? AppColors.caramelizedAmberLight : AppColors.caramelizedAmber,
                                        ),
                                      ),
                                    ),

                                  if (!item.isOwned && item.availability == GameAvailability.upcoming)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.statusInfo.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text('UPCOMING',
                                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.statusInfo)),
                                    ),

                                  if (!item.isOwned && item.availability == GameAvailability.delisted)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.statusDanger.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text('DELISTED',
                                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.statusDanger)),
                                    ),

                                  if (!item.isGift && item.price != null && item.price! > 0)
                                    Text(
                                      '${item.currency ?? series.defaultCurrency ?? '\$'} ${item.price!.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? AppColors.darkTextPrimary : AppColors.deepCaramel,
                                      ),
                                    )
                                  else if (!item.isGift && (series.defaultGamePrice ?? 0) > 0)
                                    Text(
                                      '${series.defaultCurrency ?? '\$'} ${series.defaultGamePrice!.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? AppColors.darkTextMuted : AppColors.deepCaramelMuted,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Priority Watchlist Star (for unowned items)
                        if (!item.isOwned)
                          IconButton(
                            icon: Icon(
                              item.isPriorityTarget ? Icons.star_rounded : Icons.star_outline_rounded,
                              color: item.isPriorityTarget
                                  ? AppColors.caramelizedAmber
                                  : (isDark ? AppColors.darkTextMuted : AppColors.deepCaramelMuted),
                            ),
                            tooltip: item.isPriorityTarget ? 'Remove Priority Target' : 'Mark Priority Target',
                            onPressed: () {
                              ref.read(gameItemsNotifierProvider.notifier).togglePriorityTarget(item.id, !item.isPriorityTarget);
                            },
                          ),

                        // Menu: Edit, Toggle Gift, Delete (with confirmation!)
                        PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_vert_rounded,
                            color: isDark ? AppColors.darkTextMuted : AppColors.deepCaramelMuted,
                            size: 20,
                          ),
                          onSelected: (value) async {
                            if (value == 'edit') {
                              EditGameItemSheet.show(context, item: item, series: series);
                            } else if (value == 'toggle_gift') {
                              final newGift = !item.isGift;
                              await ref.read(gameItemsNotifierProvider.notifier).saveItem(item.copyWith(isGift: newGift));
                              final allTxs = ref.read(transactionsNotifierProvider);
                              final existingTx = allTxs.cast<PurchaseTransaction?>().firstWhere(
                                    (t) => t?.volumeId == item.id,
                                    orElse: () => null,
                                  );
                              if (existingTx != null) {
                                final quotaSummary = ref.read(quotaProvider);
                                final updatedTx = existingTx.copyWith(
                                  quotaBucket: newGift ? 'gift' : quotaSummary.suggestedAutoBucket,
                                  price: newGift ? 0.0 : (item.price ?? series.defaultGamePrice ?? 0.0),
                                  notes: newGift ? 'Marked as Gift' : 'Marked as Purchased',
                                );
                                await ref.read(transactionsNotifierProvider.notifier).saveTransaction(updatedTx);
                              }
                              if (context.mounted) {
                                ScaffoldMessenger.of(context)
                                  ..clearSnackBars()
                                  ..showSnackBar(
                                    SnackBar(
                                      content: Text(newGift ? 'Marked "${item.title}" as Gift!' : 'Marked "${item.title}" as Purchased!'),
                                      backgroundColor: AppColors.caramelizedAmber,
                                    ),
                                  );
                              }
                            } else if (value == 'delete') {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: Text('Delete "${item.title}"?'),
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
                              if (confirm == true) {
                                await ref.read(gameItemsNotifierProvider.notifier).deleteItem(item.id);
                                final allTxs = ref.read(transactionsNotifierProvider);
                                final existingTx = allTxs.cast<PurchaseTransaction?>().firstWhere(
                                      (t) => t?.volumeId == item.id,
                                      orElse: () => null,
                                    );
                                if (existingTx != null) {
                                  await ref.read(transactionsNotifierProvider.notifier).deleteTransaction(existingTx.id);
                                }
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context)
                                    ..clearSnackBars()
                                    ..showSnackBar(
                                      SnackBar(
                                        content: Text('Removed "${item.title}"'),
                                        backgroundColor: AppColors.statusDanger,
                                      ),
                                    );
                                }
                              }
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined, size: 18),
                                  SizedBox(width: 8),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                            if (item.isOwned)
                              PopupMenuItem(
                                value: 'toggle_gift',
                                child: Row(
                                  children: [
                                    Icon(item.isGift ? Icons.shopping_bag_outlined : Icons.card_giftcard_rounded, size: 18),
                                    const SizedBox(width: 8),
                                    Text(item.isGift ? 'Mark as Purchased' : 'Mark as Gift'),
                                  ],
                                ),
                              ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline, size: 18, color: AppColors.statusDanger),
                                  SizedBox(width: 8),
                                  Text('Delete', style: TextStyle(color: AppColors.statusDanger)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPill(String status, bool isDark) {
    Color color;
    String label;
    switch (status.toLowerCase()) {
      case 'completed':
        color = AppColors.statusSuccess;
        label = 'ACQUIRED';
        break;
      case 'wishlist':
        color = AppColors.statusInfo;
        label = 'WISHLIST';
        break;
      case 'dropped':
        color = AppColors.statusDanger;
        label = 'DROPPED';
        break;
      case 'active':
      default:
        color = AppColors.caramelizedAmber;
        label = 'ACTIVE';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: isDark ? 0.5 : 0.35), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}
