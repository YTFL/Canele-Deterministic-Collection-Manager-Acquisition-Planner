import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../models/profile.dart';
import '../../providers/profile_provider.dart';
import 'add_workspace_dialog.dart';
import 'workspace_switcher_modal.dart';

class WorkspaceSwitcherAppBarTitle extends ConsumerWidget {
  final String fallbackTitle;
  final bool showWorkspaceBadge;

  const WorkspaceSwitcherAppBarTitle({
    super.key,
    this.fallbackTitle = 'Canelé',
    this.showWorkspaceBadge = true,
  });

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

  void _openSwitcher(BuildContext context, WidgetRef ref, ProfileState profileState) {
    WorkspaceSwitcherModal.show(
      context: context,
      activeProfile: profileState.activeProfile,
      profiles: profileState.allProfiles,
      onSelectProfile: (id) {
        ref.read(profileNotifierProvider.notifier).switchProfile(id);
      },
      onAddWorkspace: () {
        AddWorkspaceDialog.show(
          context: context,
          onCreate: ({
            required String name,
            required ProfileType type,
            String? icon,
            CustomWorkspaceSchema? customSchema,
          }) async {
            await ref.read(profileNotifierProvider.notifier).createProfile(
                  name: name,
                  type: type,
                  icon: icon,
                  customSchema: customSchema,
                );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final profileState = ref.watch(profileNotifierProvider);
    final activeProfile = profileState.activeProfile;

    return InkWell(
      key: const Key('workspace_switcher_header_button'),
      onTap: () => _openSwitcher(context, ref, profileState),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Workspace Icon Badge
            if (showWorkspaceBadge) ...[
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.caramelizedAmber.withValues(alpha: 0.3)
                      : AppColors.warmPastryCrust,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getIconData(activeProfile.icon, activeProfile.type),
                  color: isDark
                      ? AppColors.caramelizedAmberLight
                      : AppColors.caramelizedAmber,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
            ],

            // Active Workspace Title
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activeProfile.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),

            // Dropdown Chevron
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: isDark ? AppColors.darkTextMuted : AppColors.deepCaramelMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
