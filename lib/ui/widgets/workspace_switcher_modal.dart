import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/profile.dart';
import 'edit_custom_schema_sheet.dart';

class WorkspaceSwitcherModal extends StatefulWidget {
  final Profile activeProfile;
  final List<Profile> profiles;
  final ValueChanged<String> onSelectProfile;
  final VoidCallback onAddWorkspace;
  final void Function(Profile profile)? onEditProfile;

  const WorkspaceSwitcherModal({
    super.key,
    required this.activeProfile,
    required this.profiles,
    required this.onSelectProfile,
    required this.onAddWorkspace,
    this.onEditProfile,
  });

  static Future<void> show({
    required BuildContext context,
    required Profile activeProfile,
    required List<Profile> profiles,
    required ValueChanged<String> onSelectProfile,
    required VoidCallback onAddWorkspace,
    void Function(Profile profile)? onEditProfile,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => WorkspaceSwitcherModal(
        activeProfile: activeProfile,
        profiles: profiles,
        onSelectProfile: onSelectProfile,
        onAddWorkspace: onAddWorkspace,
        onEditProfile: onEditProfile,
      ),
    );
  }

  @override
  State<WorkspaceSwitcherModal> createState() => _WorkspaceSwitcherModalState();
}

class _WorkspaceSwitcherModalState extends State<WorkspaceSwitcherModal> {
  IconData _getIconData(String iconName, ProfileType type) {
    switch (iconName.toLowerCase()) {
      case 'gamepad':
      case 'games':
      case 'controller':
        return Icons.sports_esports_rounded;
      case 'custom':
      case 'layers':
        return Icons.layers_rounded;
      case 'music':
      case 'vinyl':
        return Icons.album_rounded;
      case 'movie':
      case 'film':
        return Icons.movie_filter_rounded;
      case 'stars':
      case 'star':
        return Icons.auto_awesome_rounded;
      case 'bookmark':
        return Icons.bookmark_rounded;
      case 'books':
      case 'book':
      default:
        return type == ProfileType.games
            ? Icons.sports_esports_rounded
            : (type == ProfileType.custom
                ? Icons.layers_rounded
                : Icons.auto_stories_rounded);
    }
  }

  String _getPresetLabel(ProfileType type) {
    switch (type) {
      case ProfileType.books:
        return 'Books Preset';
      case ProfileType.games:
        return 'Games Preset';
      case ProfileType.custom:
        return 'Custom Workspace';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: 24 + bottomInset,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkPastryCard : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkPastryBorder : AppColors.pastryCrustBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Workspaces',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Switch context or configure isolated profiles',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark ? AppColors.darkTextMuted : AppColors.deepCaramelMuted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Close',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Profile List
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                itemCount: widget.profiles.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (ctx, index) {
                  final profile = widget.profiles[index];
                  final isActive = profile.id == widget.activeProfile.id;

                  return InkWell(
                    key: Key('workspace_tile_${profile.id}'),
                    onTap: () {
                      Navigator.of(context).pop();
                      widget.onSelectProfile(profile.id);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isActive
                            ? (isDark
                                ? AppColors.caramelizedAmber.withValues(alpha: 0.22)
                                : AppColors.warmPastryCrust.withValues(alpha: 0.55))
                            : (isDark
                                ? AppColors.darkPastryCardElevated
                                : AppColors.pastryCrustLight),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isActive
                              ? AppColors.caramelizedAmber
                              : (isDark
                                  ? AppColors.darkPastryBorder
                                  : AppColors.pastryCrustBorder),
                          width: isActive ? 1.8 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Workspace Icon Avatar
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppColors.caramelizedAmber
                                  : (isDark
                                      ? AppColors.darkPastryBorder
                                      : AppColors.warmPastryCrust),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _getIconData(profile.icon, profile.type),
                              color: isActive
                                  ? Colors.white
                                  : (isDark
                                      ? AppColors.caramelizedAmberLight
                                      : AppColors.caramelizedAmber),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Profile Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        profile.name,
                                        style: TextStyle(
                                          fontWeight: isActive
                                              ? FontWeight.w800
                                              : FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? AppColors.darkPastryBorder
                                            : AppColors.warmPastryCrust,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        _getPresetLabel(profile.type),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? AppColors.darkTextMuted
                                              : AppColors.deepCaramelMuted,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  isActive ? 'Active workspace' : 'Tap to switch',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isActive
                                        ? AppColors.caramelizedAmber
                                        : (isDark
                                            ? AppColors.darkTextMuted
                                            : AppColors.deepCaramelMuted),
                                    fontWeight: isActive
                                        ? FontWeight.w700
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Custom Workspace Schema Tune Button
                          if (profile.type == ProfileType.custom) ...[
                            IconButton(
                              key: Key('edit_schema_${profile.id}'),
                              icon: const Icon(Icons.tune_rounded, size: 20),
                              tooltip: 'Edit Schema & Terminology',
                              color: isDark ? AppColors.caramelizedAmberLight : AppColors.caramelizedAmber,
                              onPressed: () {
                                Navigator.of(context).pop();
                                showEditCustomSchemaSheet(context, profile);
                              },
                            ),
                            const SizedBox(width: 4),
                          ],

                          // Active Radio/Checkmark Indicator
                          if (isActive)
                            Container(
                              width: 28,
                              height: 28,
                              decoration: const BoxDecoration(
                                color: AppColors.caramelizedAmber,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            )
                          else
                            Icon(
                              Icons.radio_button_unchecked_rounded,
                              color: isDark
                                  ? AppColors.darkPastryBorder
                                  : AppColors.pastryCrustBorder,
                              size: 22,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 18),

            // + Add Workspace Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                key: const Key('add_workspace_button'),
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onAddWorkspace();
                },
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text(
                  'Add Workspace',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.caramelizedAmber,
                  side: const BorderSide(
                    color: AppColors.caramelizedAmber,
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
