import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/profile.dart';

class CustomStatusDefinition {
  final String key;
  final String label;
  final Color color;
  final IconData icon;

  const CustomStatusDefinition({
    required this.key,
    required this.label,
    required this.color,
    required this.icon,
  });
}

class WorkspaceTerminology {
  final Profile profile;

  const WorkspaceTerminology(this.profile);

  /// Primary grouping term (e.g., "Series", "Game Series", "Artist", "Line")
  String get groupLabel {
    switch (profile.type) {
      case ProfileType.books:
        return 'Series';
      case ProfileType.games:
        return 'Game Series';
      case ProfileType.custom:
        final label = profile.customSchema?.groupLabel.trim();
        return (label != null && label.isNotEmpty) ? label : 'Group';
    }
  }

  /// Primary individual item term (e.g., "Volume", "Game", "Vinyl", "Figure")
  String get itemLabel {
    switch (profile.type) {
      case ProfileType.books:
        return 'Volume';
      case ProfileType.games:
        return 'Game';
      case ProfileType.custom:
        final label = profile.customSchema?.itemLabel.trim();
        return (label != null && label.isNotEmpty) ? label : 'Item';
    }
  }

  /// Pluralized item term (e.g., "Volumes", "Games & DLCs", "Vinyls", "Figures")
  String get itemsLabel {
    switch (profile.type) {
      case ProfileType.books:
        return 'Volumes';
      case ProfileType.games:
        return 'Games & DLCs';
      case ProfileType.custom:
        final singular = itemLabel;
        if (singular.toLowerCase() == 'series') return 'Series';
        if (singular.toLowerCase().endsWith('s')) return singular;
        if (singular.toLowerCase().endsWith('y') && !singular.toLowerCase().endsWith('ey')) {
          return '${singular.substring(0, singular.length - 1)}ies';
        }
        return '${singular}s';
    }
  }

  /// Singular high-level item term (e.g., "Book", "Game")
  String get singleItemLabel {
    switch (profile.type) {
      case ProfileType.books:
        return 'Book';
      case ProfileType.games:
        return 'Game';
      case ProfileType.custom:
        return itemLabel;
    }
  }

  /// Plural high-level item term (e.g., "Books", "Games")
  String get pluralItemLabel {
    switch (profile.type) {
      case ProfileType.books:
        return 'Books';
      case ProfileType.games:
        return 'Games';
      case ProfileType.custom:
        return itemsLabel;
    }
  }

  /// Cadence unit string for quota calculations (e.g. "books", "games")
  String get cadenceUnit {
    switch (profile.type) {
      case ProfileType.books:
        return 'books';
      case ProfileType.games:
        return 'games';
      case ProfileType.custom:
        return itemsLabel.toLowerCase();
    }
  }

  /// Recurring no-purchase months section title
  String get noPurchaseMonthTitle {
    switch (profile.type) {
      case ProfileType.books:
        return 'Recurring No-Book Months';
      case ProfileType.games:
        return 'Recurring No-Game Months';
      case ProfileType.custom:
        return 'Recurring Paused Months';
    }
  }

  /// Recurring no-purchase months description
  String get noPurchaseMonthDescription {
    switch (profile.type) {
      case ProfileType.books:
        return 'Select annual months with 0 regular book budget (e.g. Budget pause, Travel)';
      case ProfileType.games:
        return 'Select annual months with 0 regular game budget (e.g. Budget pause, Travel)';
      case ProfileType.custom:
        return 'Select annual months with 0 regular acquisition budget';
    }
  }

  /// Single no-purchase month title
  String get noPurchaseMonthSingleTitle {
    switch (profile.type) {
      case ProfileType.books:
        return 'No-Book Month';
      case ProfileType.games:
        return 'No-Game Month';
      case ProfileType.custom:
        return 'Paused Month';
    }
  }

  /// Single no-purchase month description
  String get noPurchaseMonthSingleDescription {
    switch (profile.type) {
      case ProfileType.books:
        return 'In a No-Book Month, your regular monthly acquisition target is set to 0. Use this for budget pauses, vacations, or catch-up reading months.';
      case ProfileType.games:
        return 'In a No-Game Month, your regular monthly acquisition target is set to 0. Use this for budget pauses, vacations, or catch-up gaming months.';
      case ProfileType.custom:
        return 'In a Paused Month, your regular monthly acquisition target is set to 0.';
    }
  }

  /// Scope label for rules
  String get scopeLabel {
    switch (profile.type) {
      case ProfileType.books:
        return 'Series Scope';
      case ProfileType.games:
        return 'Game Series Scope';
      case ProfileType.custom:
        return '$groupLabel Scope';
    }
  }

  /// Target format label for rules
  String get targetFormatLabel {
    switch (profile.type) {
      case ProfileType.books:
        return 'Target Book Format';
      case ProfileType.games:
        return 'Target Platform / Format';
      case ProfileType.custom:
        return 'Target Format / Category';
    }
  }

  /// Restock / Watchlist priority toggle label
  String get restockPriorityLabel {
    switch (profile.type) {
      case ProfileType.books:
        return 'Restock Watchlist Priority';
      case ProfileType.games:
        return 'Watchlist & Release Priority';
      case ProfileType.custom:
        return 'Priority Watchlist';
    }
  }

  /// Restock / Watchlist priority toggle description
  String get restockPriorityDescription {
    switch (profile.type) {
      case ProfileType.books:
        return 'Prioritize volumes marked as in-stock or on your restock watchlist';
      case ProfileType.games:
        return 'Prioritize games & DLCs on your acquisition watchlist or available on release';
      case ProfileType.custom:
        return 'Prioritize items marked on your priority watchlist';
    }
  }

  /// Default rule 1 title
  String get defaultRule1Title {
    switch (profile.type) {
      case ProfileType.books:
        return 'Prioritize In-Stock & Restocked';
      case ProfileType.games:
        return 'Prioritize Watchlist Games & DLCs';
      case ProfileType.custom:
        return 'Prioritize Watchlist Items';
    }
  }

  /// Default rule 1 description
  String get defaultRule1Desc {
    switch (profile.type) {
      case ProfileType.books:
        return 'Bumps volumes marked on your restock watchlist to the top of your monthly recommendations.';
      case ProfileType.games:
        return 'Bumps games and DLCs on your acquisition watchlist to the top of your monthly planner.';
      case ProfileType.custom:
        return 'Bumps high-priority watchlist items to the top of your recommendations.';
    }
  }

  /// Default rule 2 title
  String get defaultRule2Title {
    switch (profile.type) {
      case ProfileType.books:
        return 'Complete Nearly-Finished Series';
      case ProfileType.games:
        return 'Finish Near-Complete Game Series';
      case ProfileType.custom:
        return 'Complete Near-Finished Collections';
    }
  }

  /// Default rule 2 description
  String get defaultRule2Desc {
    switch (profile.type) {
      case ProfileType.books:
        return 'Prioritizes series with 2 or fewer unowned volumes to help you complete them.';
      case ProfileType.games:
        return 'Prioritizes game series with 2 or fewer unowned games or expansions.';
      case ProfileType.custom:
        return 'Prioritizes groups near completion.';
    }
  }

  /// Default rule 3 title
  String get defaultRule3Title {
    switch (profile.type) {
      case ProfileType.books:
        return 'Fill Gaps & Next Volume';
      case ProfileType.games:
        return 'Next Sequential Game or DLC';
      case ProfileType.custom:
        return 'Next Sequential Item';
    }
  }

  /// Default rule 3 description
  String get defaultRule3Desc {
    switch (profile.type) {
      case ProfileType.books:
        return 'Recommends the next unowned volume in sequential order for your active series.';
      case ProfileType.games:
        return 'Recommends the next unowned installment or DLC in sequential order.';
      case ProfileType.custom:
        return 'Recommends the next item in sequential order.';
    }
  }

  /// Button label to restore default rules
  String get emptyRulesActionLabel {
    switch (profile.type) {
      case ProfileType.books:
        return 'Load Default Book Rules';
      case ProfileType.games:
        return 'Load Default Game Rules';
      case ProfileType.custom:
        return 'Load Default Rules';
    }
  }

  /// Whether a specific schema field is enabled in the current workspace.
  bool isFieldEnabled(String fieldKey) {
    switch (profile.type) {
      case ProfileType.books:
        // Books enable standard metadata except gaming platform
        if (fieldKey == 'platform') return false;
        return true;
      case ProfileType.games:
        return true;
      case ProfileType.custom:
        final schema = profile.customSchema;
        if (schema == null) {
          // Default fallbacks for custom
          const defaults = {
            'coverUrl': true,
            'price': true,
            'releaseDate': true,
            'notes': true,
            'rating': false,
            'edition': false,
            'platform': false,
            'groupTitle': true,
          };
          return defaults[fieldKey] ?? false;
        }
        return schema.enabledFields[fieldKey] ?? false;
    }
  }

  /// Resolves status metadata (label, color, icon) for a status key
  CustomStatusDefinition resolveStatus(String statusKey) {
    final lower = statusKey.toLowerCase().trim();

    if (lower == 'backlog' || lower == 'queued' || lower == 'wishlist' || lower == 'plan') {
      return CustomStatusDefinition(
        key: statusKey,
        label: _capitalize(statusKey),
        color: AppColors.deepCaramelMuted,
        icon: Icons.inventory_2_outlined,
      );
    }

    if (lower == 'inprogress' || lower == 'active' || lower == 'reading' || lower == 'playing') {
      return CustomStatusDefinition(
        key: statusKey,
        label: lower == 'inprogress' ? 'In Progress' : _capitalize(statusKey),
        color: AppColors.caramelizedAmber,
        icon: Icons.hourglass_top_rounded,
      );
    }

    if (lower == 'completed' || lower == 'finished' || lower == 'beaten' || lower == 'done') {
      return CustomStatusDefinition(
        key: statusKey,
        label: _capitalize(statusKey),
        color: AppColors.statusSuccess,
        icon: Icons.check_circle_outline_rounded,
      );
    }

    if (lower == 'dropped' || lower == 'abandoned' || lower == 'paused') {
      return CustomStatusDefinition(
        key: statusKey,
        label: _capitalize(statusKey),
        color: AppColors.statusDanger,
        icon: Icons.pause_circle_outline_rounded,
      );
    }

    return CustomStatusDefinition(
      key: statusKey,
      label: _capitalize(statusKey),
      color: AppColors.caramelizedAmber,
      icon: Icons.label_outline_rounded,
    );
  }

  /// List of custom statuses defined for this profile
  List<CustomStatusDefinition> get availableStatuses {
    final schema = profile.customSchema;
    final keys = schema?.customStatuses ?? const ['backlog', 'inProgress', 'completed'];
    return keys.map((k) => resolveStatus(k)).toList();
  }

  static String _capitalize(String str) {
    if (str.isEmpty) return str;
    return str[0].toUpperCase() + str.substring(1);
  }
}

extension ProfileTerminologyExtension on Profile {
  WorkspaceTerminology get terms => WorkspaceTerminology(this);
}
