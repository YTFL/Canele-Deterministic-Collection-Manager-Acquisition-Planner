import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/backup_provider.dart';
import '../../services/backup_service.dart';
import 'canele_card.dart';

class BackupFolderCard extends ConsumerWidget {
  const BackupFolderCard({super.key});

  Future<void> _pickDirectory(BuildContext context, WidgetRef ref) async {
    try {
      if (Platform.isAndroid) {
        await BackupService.requestStoragePermissions();
      }

      final selectedPath = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select Auto-Backup Destination Folder',
      );

      if (selectedPath != null && selectedPath.isNotEmpty) {
        await ref.read(backupNotifierProvider.notifier).setTargetDirectory(selectedPath);

        if (context.mounted) {
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(
            SnackBar(
              content: Text('Backup folder set to: $selectedPath'),
              backgroundColor: AppColors.statusSuccess,
              action: Platform.isAndroid
                  ? SnackBarAction(
                      label: 'Settings',
                      textColor: Colors.white,
                      onPressed: () => openAppSettings(),
                    )
                  : null,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
          SnackBar(
            content: Text('Could not access selected directory: $e'),
            backgroundColor: AppColors.statusDanger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backupMeta = ref.watch(backupNotifierProvider);
    final hasCustomFolder = backupMeta.targetDirectoryPath != null &&
        backupMeta.targetDirectoryPath!.trim().isNotEmpty;

    return CaneleCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.caramelizedAmber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.folder_special_rounded,
                  color: AppColors.caramelizedAmber,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Backup Destination Folder',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasCustomFolder ? 'Custom local storage folder' : 'App Internal Documents (Default)',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextMuted : AppColors.deepCaramelMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Current Folder Path Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkPastryCardElevated : AppColors.pastryCrustLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? AppColors.darkPastryBorder : AppColors.pastryCrustBorder,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.folder_open_rounded,
                  size: 16,
                  color: hasCustomFolder ? AppColors.caramelizedAmber : AppColors.deepCaramelMuted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hasCustomFolder
                        ? backupMeta.targetDirectoryPath!
                        : 'Default (app_flutter/canele_backups)',
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: hasCustomFolder ? 'monospace' : null,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.deepCaramel,
                      fontWeight: hasCustomFolder ? FontWeight.w600 : FontWeight.normal,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Change / Reset Folder Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickDirectory(context, ref),
                  icon: const Icon(Icons.folder_rounded, size: 16),
                  label: Text(hasCustomFolder ? 'Change Folder' : 'Select Folder'),
                ),
              ),
              if (hasCustomFolder) ...[
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Reset to default',
                  icon: const Icon(Icons.restart_alt_rounded, size: 20),
                  onPressed: () async {
                    await ref.read(backupNotifierProvider.notifier).clearTargetDirectory();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(
                        const SnackBar(content: Text('Reset to default internal documents directory.')),
                      );
                    }
                  },
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
