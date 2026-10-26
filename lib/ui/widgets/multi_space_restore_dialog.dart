import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../features/custom/services/custom_space_importer.dart';
import '../../features/games/services/game_space_importer.dart';
import '../../models/backup_manifest.dart';
import '../../models/profile.dart';
import '../../services/backup_service.dart';
import '../../services/profile_service.dart';
import '../../services/universal_importer.dart';

class DiscoveredSpaceBackup {
  final String profileId;
  final String name;
  final ProfileType type;
  final String folderName;
  final File backupFile;
  final int itemCount;
  final DateTime? backupTime;
  bool isSelected;

  DiscoveredSpaceBackup({
    required this.profileId,
    required this.name,
    required this.type,
    required this.folderName,
    required this.backupFile,
    this.itemCount = 0,
    this.backupTime,
    this.isSelected = true,
  });
}

class MultiSpaceRestoreDialog extends ConsumerStatefulWidget {
  final Directory backupDirectory;
  final List<DiscoveredSpaceBackup> discoveredSpaces;

  const MultiSpaceRestoreDialog({
    super.key,
    required this.backupDirectory,
    required this.discoveredSpaces,
  });

  /// Factory helper that inspects a backup directory and discovers spaces
  static Future<List<DiscoveredSpaceBackup>> discoverSpaces(Directory dir) async {
    final list = <DiscoveredSpaceBackup>[];

    // 1. Try reading canele_manifest.json
    final manifestFile = File('${dir.path}/canele_manifest.json');
    if (await manifestFile.exists()) {
      try {
        final content = await manifestFile.readAsString();
        final manifest = BackupManifest.fromJson(content);
        for (final entry in manifest.spaces) {
          final spaceFile = File('${dir.path}/${entry.folderName}/${entry.backupFileName}');
          if (await spaceFile.exists()) {
            list.add(DiscoveredSpaceBackup(
              profileId: entry.profileId,
              name: entry.name,
              type: entry.type,
              folderName: entry.folderName,
              backupFile: spaceFile,
              itemCount: entry.itemCount,
              backupTime: entry.lastBackupTime ?? manifest.exportedAt,
            ));
          }
        }
        if (list.isNotEmpty) return list;
      } catch (e) {
        debugPrint('[MultiSpaceRestore] Failed parsing manifest: $e');
      }
    }

    // 2. Discover by inspecting subdirectories
    try {
      final entities = await dir.list().toList();
      for (final entity in entities) {
        if (entity is Directory) {
          final subFile = File('${entity.path}/canele_backup.json');
          if (await subFile.exists()) {
            try {
              final raw = jsonDecode(await subFile.readAsString());
              if (raw is Map) {
                final folderName = entity.uri.pathSegments
                    .where((s) => s.isNotEmpty)
                    .last;
                final profileMap = raw['profile'] as Map? ?? {};
                final name = profileMap['name']?.toString() ?? folderName;
                final typeStr = profileMap['type']?.toString() ?? raw['spaceType']?.toString() ?? 'books';
                final type = ProfileType.values.firstWhere(
                  (t) => t.name == typeStr,
                  orElse: () => ProfileType.books,
                );
                final id = profileMap['id']?.toString() ?? 'discovered_${DateTime.now().millisecondsSinceEpoch}';

                int count = 0;
                if (raw['franchises'] is List) {
                  count = (raw['franchises'] as List).length;
                } else if (raw['games'] is List) {
                  count = (raw['games'] as List).length;
                } else if (raw['items'] is List) {
                  count = (raw['items'] as List).length;
                } else if (raw['series'] is List) {
                  count = (raw['series'] as List).length;
                }

                list.add(DiscoveredSpaceBackup(
                  profileId: id,
                  name: name,
                  type: type,
                  folderName: folderName,
                  backupFile: subFile,
                  itemCount: count,
                  backupTime: DateTime.tryParse(raw['exportedAt']?.toString() ?? ''),
                ));
              }
            } catch (_) {}
          }
        }
      }
    } catch (e) {
      debugPrint('[MultiSpaceRestore] Subdirectory scan failed: $e');
    }

    return list;
  }

  @override
  ConsumerState<MultiSpaceRestoreDialog> createState() => _MultiSpaceRestoreDialogState();
}

class _MultiSpaceRestoreDialogState extends ConsumerState<MultiSpaceRestoreDialog> {
  late List<DiscoveredSpaceBackup> _spaces;
  RestoreMode _restoreMode = RestoreMode.mergeAndKeepNewest;
  bool _isRestoring = false;

  @override
  void initState() {
    super.initState();
    _spaces = List.from(widget.discoveredSpaces);
  }

  int get _selectedCount => _spaces.where((s) => s.isSelected).length;

  Future<void> _executeRestore() async {
    final selected = _spaces.where((s) => s.isSelected).toList();
    if (selected.isEmpty) return;

    setState(() => _isRestoring = true);
    BackupService.instance.pauseListening();

    int totalRestoredSpaces = 0;
    int totalItems = 0;

    try {
      for (final space in selected) {
        final content = await space.backupFile.readAsString();
        final dynamic decoded = jsonDecode(content);
        if (decoded is! Map) continue;
        final data = Map<String, dynamic>.from(decoded);

        // Ensure profile exists in ProfileService
        final existingProfile = ProfileService.instance.getProfileById(space.profileId);
        if (existingProfile == null) {
          await ProfileService.instance.createProfile(
            name: space.name,
            type: space.type,
            icon: space.type == ProfileType.games ? 'gamepad' : (space.type == ProfileType.books ? 'book' : 'layers'),
            autoSwitch: false,
          );
        }

        // Delegate restore by space type
        if (space.type == ProfileType.games) {
          final res = await GameSpaceImporter.restoreFromJson(
            profileId: space.profileId,
            data: data,
            mode: _restoreMode,
          );
          if (res.success) {
            totalRestoredSpaces++;
            totalItems += res.gamesCount;
          }
        } else if (space.type == ProfileType.custom) {
          final res = await CustomSpaceImporter.restoreFromJson(
            profileId: space.profileId,
            data: data,
            mode: _restoreMode,
          );
          if (res.success) {
            totalRestoredSpaces++;
            totalItems += res.itemsCount;
          }
        } else {
          // Books space
          final res = await UniversalImporter.restoreSingleWorkspace(
            profileId: space.profileId,
            data: data,
            mode: _restoreMode,
          );
          if (res.success) {
            totalRestoredSpaces++;
            totalItems += res.volumesCount;
          }
        }
      }

      // Switch to first restored profile if available
      if (selected.isNotEmpty) {
        await ProfileService.instance.switchProfile(selected.first.profileId);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text('Successfully restored $totalRestoredSpaces space(s) ($totalItems items)!'),
              backgroundColor: AppColors.statusSuccess,
            ),
          );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRestoring = false);
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text('Restore failed: $e'),
              backgroundColor: AppColors.statusDanger,
            ),
          );
      }
    } finally {
      BackupService.instance.resumeListening();
    }
  }

  IconData _iconForType(ProfileType type) {
    switch (type) {
      case ProfileType.games:
        return Icons.sports_esports_rounded;
      case ProfileType.books:
        return Icons.auto_stories_rounded;
      case ProfileType.custom:
        return Icons.category_rounded;
    }
  }

  String _badgeLabel(ProfileType type) {
    switch (type) {
      case ProfileType.games:
        return 'GAMES';
      case ProfileType.books:
        return 'BOOKS';
      case ProfileType.custom:
        return 'CUSTOM';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: theme.cardColor,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 650),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.caramelizedAmber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.folder_copy_rounded, color: AppColors.caramelizedAmber),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Restore From Backup Folder',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '${_spaces.length} space(s) discovered in backup',
                          style: theme.textTheme.bodySmall?.copyWith(color: AppColors.deepCaramelMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Restore Mode Selector
              Text('Restore Strategy', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              SegmentedButton<RestoreMode>(
                segments: const [
                  ButtonSegment(
                    value: RestoreMode.mergeAndKeepNewest,
                    label: Text('Merge & Keep Newest', style: TextStyle(fontSize: 12)),
                    icon: Icon(Icons.merge_type_rounded, size: 16),
                  ),
                  ButtonSegment(
                    value: RestoreMode.replaceAll,
                    label: Text('Replace All', style: TextStyle(fontSize: 12)),
                    icon: Icon(Icons.restore_page_rounded, size: 16),
                  ),
                ],
                selected: {_restoreMode},
                onSelectionChanged: (set) => setState(() => _restoreMode = set.first),
              ),
              const SizedBox(height: 14),

              // Selection Toolbar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Select Spaces ($_selectedCount/${_spaces.length})', style: const TextStyle(fontWeight: FontWeight.w600)),
                  TextButton(
                    onPressed: () {
                      final allSelected = _selectedCount == _spaces.length;
                      setState(() {
                        for (final s in _spaces) {
                          s.isSelected = !allSelected;
                        }
                      });
                    },
                    child: Text(_selectedCount == _spaces.length ? 'Deselect All' : 'Select All'),
                  ),
                ],
              ),
              const Divider(height: 1),

              // Spaces List
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _spaces.length,
                  itemBuilder: (context, index) {
                    final space = _spaces[index];
                    return CheckboxListTile(
                      value: space.isSelected,
                      onChanged: (val) => setState(() => space.isSelected = val ?? false),
                      activeColor: AppColors.caramelizedAmber,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (isDark ? AppColors.darkPastryCardElevated : AppColors.pastryCrustLight),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(_iconForType(space.type), color: AppColors.caramelizedAmber, size: 20),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              space.name,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.caramelizedAmber.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _badgeLabel(space.type),
                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.caramelizedAmber),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        '${space.folderName} · ${space.itemCount} items',
                        style: theme.textTheme.bodySmall,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isRestoring ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: (_isRestoring || _selectedCount == 0) ? null : _executeRestore,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _restoreMode == RestoreMode.replaceAll ? AppColors.statusDanger : AppColors.caramelizedAmber,
                      foregroundColor: Colors.white,
                    ),
                    icon: _isRestoring
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.restore_rounded, size: 18),
                    label: Text(_isRestoring ? 'Restoring...' : 'Restore ($_selectedCount)'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
