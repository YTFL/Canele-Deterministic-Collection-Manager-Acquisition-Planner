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

  /// Primary grouping term (e.g., "Series", "Franchise", "Artist", "Line")
  String get groupLabel {
    switch (profile.type) {
      case ProfileType.books:
        return 'Series';
      case ProfileType.games:
        return 'Franchise';
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

  /// Pluralized item term (e.g., "Volumes", "Games", "Vinyls", "Figures")
  String get itemsLabel {
    final singular = itemLabel;
    if (singular.toLowerCase() == 'series') return 'Series';
    if (singular.toLowerCase().endsWith('s')) return singular;
    if (singular.toLowerCase().endsWith('y') && !singular.toLowerCase().endsWith('ey')) {
      return '${singular.substring(0, singular.length - 1)}ies';
    }
    return '${singular}s';
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
