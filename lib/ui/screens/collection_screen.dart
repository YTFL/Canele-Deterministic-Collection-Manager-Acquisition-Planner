import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/type_helper.dart';
import '../../core/utils/uuid_generator.dart';
import '../../models/series.dart';
import '../../models/volume.dart';
import '../../providers/series_provider.dart';
import '../widgets/canele_card.dart';
import '../widgets/canele_progress_bar.dart';
import '../widgets/add_series_sheet.dart';
import 'series_detail_screen.dart';

enum CollectionSortOption {
  titleAsc('Title (A → Z)', Icons.sort_by_alpha_rounded),
  titleDesc('Title (Z → A)', Icons.sort_by_alpha_rounded),
  progressDesc('Progress (High to Low)', Icons.trending_up_rounded),
  progressAsc('Progress (Low to High)', Icons.trending_down_rounded),
  volumesDesc('Volumes (Most First)', Icons.format_list_numbered_rounded),
  volumesAsc('Volumes (Fewest First)', Icons.format_list_numbered_rtl_rounded),
  typeAsc('Format Type', Icons.category_rounded);

  final String label;
  final IconData icon;
  const CollectionSortOption(this.label, this.icon);
}

class CollectionScreen extends ConsumerStatefulWidget {
  const CollectionScreen({super.key});

  @override
  ConsumerState<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends ConsumerState<CollectionScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _selectedType = 'all';
  CollectionSortOption _sortOption = CollectionSortOption.titleAsc;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showAddSeriesDialog(BuildContext context) {
    showAddSeriesSheet(context);
  }

  List<Series> _filterAndSortSeries(List<Series> list, List<Volume> allVolumes) {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = list.where((s) {
      final matchesQuery = query.isEmpty || s.title.toLowerCase().contains(query);
      
      final formattedType = TypeHelper.formatTypeLabel(s.type);
      final matchesType = _selectedType == 'all' ||
          formattedType.toLowerCase() == _selectedType.toLowerCase() ||
          s.type.toLowerCase() == _selectedType.toLowerCase();
      return matchesQuery && matchesType;
    }).toList();

    filtered.sort((a, b) {
      switch (_sortOption) {
        case CollectionSortOption.titleAsc:
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        case CollectionSortOption.titleDesc:
          return b.title.toLowerCase().compareTo(a.title.toLowerCase());
        case CollectionSortOption.volumesDesc:
          final aCount = allVolumes.where((v) => v.seriesId == a.id).length;
          final bCount = allVolumes.where((v) => v.seriesId == b.id).length;
          return bCount.compareTo(aCount);
        case CollectionSortOption.volumesAsc:
          final aCount = allVolumes.where((v) => v.seriesId == a.id).length;
          final bCount = allVolumes.where((v) => v.seriesId == b.id).length;
          return aCount.compareTo(bCount);
        case CollectionSortOption.progressDesc:
        case CollectionSortOption.progressAsc:
          final aVols = allVolumes.where((v) => v.seriesId == a.id).toList();
          final bVols = allVolumes.where((v) => v.seriesId == b.id).toList();
          final aOwned = aVols.where((v) => v.isOwned).length;
          final bOwned = bVols.where((v) => v.isOwned).length;
          final aRatio = aVols.isEmpty ? 0.0 : aOwned / aVols.length;
          final bRatio = bVols.isEmpty ? 0.0 : bOwned / bVols.length;
          return _sortOption == CollectionSortOption.progressDesc
              ? bRatio.compareTo(aRatio)
              : aRatio.compareTo(bRatio);
        case CollectionSortOption.typeAsc:
          final typeComp = a.type.toLowerCase().compareTo(b.type.toLowerCase());
          if (typeComp != 0) return typeComp;
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      }
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final allSeries = ref.watch(seriesNotifierProvider);
    final allVolumes = ref.watch(volumesNotifierProvider);
    final availableTypes = TypeHelper.getAllAvailableTypes(allSeries.map((s) => s.type));

    final activeSeries = ref.watch(activeSeriesProvider);
    final wishlistSeries = ref.watch(wishlistSeriesProvider);
    final completedSeries = ref.watch(completedSeriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Collection'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          physics: const NeverScrollableScrollPhysics(),
          tabAlignment: TabAlignment.start,
          labelPadding: const EdgeInsets.symmetric(horizontal: 23),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          indicatorColor: AppColors.caramelizedAmber,
          indicatorSize: TabBarIndicatorSize.label,
          labelColor: isDark ? AppColors.caramelizedAmberLight : AppColors.caramelizedAmber,
          unselectedLabelColor: isDark ? AppColors.darkTextMuted : AppColors.deepCaramelMuted,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Active'),
            Tab(text: 'Wishlist'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Bar & Filter Chips
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search title or tag...',
                          prefixIcon: const Icon(Icons.search_rounded, size: 20),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<CollectionSortOption>(
                      tooltip: 'Sort: ${_sortOption.label}',
                      initialValue: _sortOption,
                      onSelected: (val) => setState(() => _sortOption = val),
                      itemBuilder: (ctx) => CollectionSortOption.values.map((opt) {
                        final isCur = opt == _sortOption;
                        return PopupMenuItem(
                          value: opt,
                          child: Row(
                            children: [
                              Icon(
                                opt.icon,
                                size: 18,
                                color: isCur ? AppColors.caramelizedAmber : (isDark ? AppColors.darkTextMuted : AppColors.deepCaramelMuted),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  opt.label,
                                  style: TextStyle(
                                    fontWeight: isCur ? FontWeight.w700 : FontWeight.w500,
                                    color: isCur ? AppColors.caramelizedAmber : null,
                                  ),
                                ),
                              ),
                              if (isCur)
                                const Icon(Icons.check_rounded, size: 16, color: AppColors.caramelizedAmber),
                            ],
                          ),
                        );
                      }).toList(),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkPastryCardElevated : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? AppColors.darkPastryBorder : AppColors.pastryCrustBorder,
                          ),
                        ),
                        child: const Icon(Icons.swap_vert_rounded, size: 20, color: AppColors.caramelizedAmber),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All',
                        isSelected: _selectedType == 'all',
                        onSelected: () => setState(() => _selectedType = 'all'),
                      ),
                      for (final t in availableTypes) ...[
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: t,
                          isSelected: _selectedType.toLowerCase() == t.toLowerCase(),
                          onSelected: () => setState(() => _selectedType = t),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _SeriesListView(
                  seriesList: _filterAndSortSeries(allSeries, allVolumes),
                  emptyMessage: 'No books found in collection.',
                ),
                _SeriesListView(
                  seriesList: _filterAndSortSeries(activeSeries, allVolumes),
                  emptyMessage: 'No active series found.',
                ),
                _SeriesListView(
                  seriesList: _filterAndSortSeries(wishlistSeries, allVolumes),
                  emptyMessage: 'No wishlist series found.',
                ),
                _SeriesListView(
                  seriesList: _filterAndSortSeries(completedSeries, allVolumes),
                  emptyMessage: 'No completed series found.',
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSeriesDialog(context),
        backgroundColor: AppColors.caramelizedAmber,
        foregroundColor: Colors.white,
        tooltip: 'Add Series',
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onSelected,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.caramelizedAmber.withValues(alpha: 0.25) : AppColors.pastryCrustLight)
              : (isDark ? AppColors.darkPastryCardElevated : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.caramelizedAmber
                : (isDark ? AppColors.darkPastryBorder : AppColors.pastryCrustBorder),
            width: isSelected ? 1.5 : 0.9,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          softWrap: false,
          overflow: TextOverflow.visible,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? (isDark ? AppColors.caramelizedAmberLight : AppColors.caramelizedAmber)
                : (isDark ? AppColors.darkTextMuted : AppColors.deepCaramel),
          ),
        ),
      ),
    );
  }
}

class _SeriesListView extends ConsumerWidget {
  final List<Series> seriesList;
  final String emptyMessage;

  const _SeriesListView({
    required this.seriesList,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (seriesList.isEmpty) {
      return Center(
        child: Text(emptyMessage, style: theme.textTheme.bodyMedium),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: seriesList.length,
      itemBuilder: (context, index) {
        final series = seriesList[index];
        final stats = ref.watch(seriesStatsProvider(series.id));

        return CaneleCard(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SeriesDetailScreen(seriesId: series.id),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      series.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkPastryCardElevated : AppColors.pastryCrustLight,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.pastryCrustBorder, width: 0.8),
                    ),
                    child: Text(
                      series.type.toUpperCase(),
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      final volumes = ref.read(volumesNotifierProvider).where((v) => v.seriesId == series.id).toList();
                      double maxVol = 0.0;
                      for (final v in volumes) {
                        if (v.volumeNumber > maxVol) maxVol = v.volumeNumber;
                      }
                      final nextVolNum = maxVol > 0 ? (maxVol + 1.0) : 1.0;
                      final newVol = Volume(
                        id: UuidGenerator.generate(),
                        seriesId: series.id,
                        volumeNumber: nextVolNum,
                        releaseDate: null,
                        isOwned: false,
                        availability: 'available',
                      );
                      await ref.read(volumesNotifierProvider.notifier).saveVolume(newVol);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context)
                          ..clearSnackBars()
                          ..showSnackBar(
                          SnackBar(
                            content: Text('Added Vol. ${DateFormatter.formatVolumeNumber(nextVolNum)} to ${series.title}'),
                            backgroundColor: AppColors.caramelizedAmber,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.add_circle_outline_rounded,
                        size: 18,
                        color: AppColors.caramelizedAmber,
                      ),
                    ),
                  ),
                  if (series.status != 'completed')
                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.more_vert_rounded, size: 18, color: AppColors.caramelizedAmber),
                      onSelected: (val) async {
                        if (val == 'complete') {
                          final volumes = ref.read(volumesNotifierProvider).where((v) => v.seriesId == series.id).toList();
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Mark Series as Completed?'),
                              content: Text(
                                'Are you sure you want to mark "${series.title}" as completed?\n\n'
                                'This will mark all ${volumes.length} volume(s) as purchased and move the series to Completed collection.',
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
                        }
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: 'complete',
                          child: Row(
                            children: [
                              Icon(Icons.check_circle_outline_rounded, size: 18, color: AppColors.caramelizedAmber),
                              SizedBox(width: 8),
                              Text('Mark as Completed'),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Progress Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${stats.totalOwned}/${stats.totalReleased} Owned',
                    style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (stats.nextMissingVolume != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.caramelizedAmber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Next: Vol. ${DateFormatter.formatVolumeNumber(stats.nextMissingVolume!.volumeNumber)}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.caramelizedAmber,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              CaneleProgressBar(
                value: stats.completionPercentage,
                showPercentage: true,
              ),
            ],
          ),
        );
      },
    );
  }
}
