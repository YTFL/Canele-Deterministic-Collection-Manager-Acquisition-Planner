import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../ui/widgets/workspace_switcher_app_bar_title.dart';
import '../../models/game_series.dart';
import '../../providers/game_providers.dart';
import '../sheets/add_game_sheet.dart';
import '../widgets/game_card.dart';

enum GameCollectionSortOption {
  titleAsc,
  titleDesc,
  progressDesc,
  progressAsc,
}

class GameCollectionView extends ConsumerStatefulWidget {
  const GameCollectionView({super.key});

  @override
  ConsumerState<GameCollectionView> createState() => _GameCollectionViewState();
}

class _GameCollectionViewState extends ConsumerState<GameCollectionView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  GameCollectionSortOption _sortOption = GameCollectionSortOption.titleAsc;

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

  List<GameSeries> _filterAndSort(List<GameSeries> list) {
    final query = _searchController.text.trim().toLowerCase();
    var filtered = list.where((s) {
      if (query.isEmpty) return true;
      return s.title.toLowerCase().contains(query);
    }).toList();

    filtered.sort((a, b) {
      switch (_sortOption) {
        case GameCollectionSortOption.titleAsc:
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        case GameCollectionSortOption.titleDesc:
          return b.title.toLowerCase().compareTo(a.title.toLowerCase());
        default:
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      }
    });

    return filtered;
  }

  Widget _buildList(List<GameSeries> seriesList, String emptyMessage) {
    final filtered = _filterAndSort(seriesList);

    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.sports_esports_outlined, size: 48, color: AppColors.caramelizedAmber),
              const SizedBox(height: 12),
              Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => AddGameSheet.show(context),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Game'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        return GameCard(series: filtered[index]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final allSeries = ref.watch(gameSeriesNotifierProvider);

    final activeSeries = allSeries.where((s) => s.collectionStatus == 'active').toList();
    final acquiredSeries = allSeries.where((s) => s.collectionStatus == 'completed').toList();
    final wishlistSeries = allSeries.where((s) => s.collectionStatus == 'wishlist').toList();

    return Scaffold(
      appBar: AppBar(
        title: const WorkspaceSwitcherAppBarTitle(fallbackTitle: 'Game Collection'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.caramelizedAmber,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(text: 'Active (${activeSeries.length})'),
            Tab(text: 'Acquired (${acquiredSeries.length})'),
            Tab(text: 'Wishlist (${wishlistSeries.length})'),
            Tab(text: 'All (${allSeries.length})'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => AddGameSheet.show(context),
        backgroundColor: AppColors.caramelizedAmber,
        foregroundColor: Colors.white,
        tooltip: 'Add Game',
        child: const Icon(Icons.add_rounded),
      ),
      body: Column(
        children: [
          // Search & Sort bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search games or franchises...',
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
                PopupMenuButton<GameCollectionSortOption>(
                  icon: const Icon(Icons.sort_rounded),
                  tooltip: 'Sort Options',
                  onSelected: (opt) => setState(() => _sortOption = opt),
                  itemBuilder: (ctx) => const [
                    PopupMenuItem(
                      value: GameCollectionSortOption.titleAsc,
                      child: Text('Title: A to Z'),
                    ),
                    PopupMenuItem(
                      value: GameCollectionSortOption.titleDesc,
                      child: Text('Title: Z to A'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildList(activeSeries, 'No active games currently in your acquisition planner.'),
                _buildList(acquiredSeries, 'No acquired games yet in your collection.'),
                _buildList(wishlistSeries, 'No wishlist / backlog games queued.'),
                _buildList(allSeries, 'Your game collection is empty.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
