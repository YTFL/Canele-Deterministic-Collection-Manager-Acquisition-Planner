import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../models/backup_metadata.dart';
import '../../providers/backup_provider.dart';
import '../../providers/database_provider.dart';
import '../../providers/quota_provider.dart';
import '../../providers/rule_provider.dart';
import '../../providers/series_provider.dart';
import '../../services/universal_exporter.dart';
import '../../services/universal_importer.dart';
import '../widgets/backup_folder_card.dart';
import '../widgets/canele_card.dart';
import '../widgets/export_options_sheet.dart';
import '../widgets/import_preview_modal.dart';

class ImportExportScreen extends ConsumerStatefulWidget {
  const ImportExportScreen({super.key});

  @override
  ConsumerState<ImportExportScreen> createState() => _ImportExportScreenState();
}

class _ImportExportScreenState extends ConsumerState<ImportExportScreen> {
  bool _isBackingUp = false;
  bool _isImporting = false;

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  Future<void> _triggerManualBackup() async {
    setState(() => _isBackingUp = true);
    final success = await ref.read(backupNotifierProvider.notifier).performManualBackup();
    if (mounted) {
      setState(() => _isBackingUp = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Manual backup snapshot created successfully!'
                : 'Failed to create backup. Check folder permissions.',
          ),
          backgroundColor: success ? AppColors.statusSuccess : AppColors.statusDanger,
        ),
      );
    }
  }

  void _openExportSheet(ExportType type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ExportOptionsSheet(initialType: type),
    );
  }

  Future<void> _pickAndImportFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['canele', 'json', 'csv', 'xlsx'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;

    if (file.bytes == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not read file data.')),
        );
      }
      return;
    }

    final ext = file.extension?.toLowerCase() ?? '';

    if (ext == 'json' || ext == 'canele') {
      _showJsonRestoreDialog(file.name, file.bytes!);
    } else if (ext == 'csv') {
      try {
        final csvStr = utf8.decode(file.bytes!);
        final items = UniversalImporter.parseCsvString(csvStr);
        if (items.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No book records found in CSV file.')),
            );
          }
          return;
        }
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ImportPreviewModal(
                items: items,
                sourceName: file.name,
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error parsing CSV: $e')),
          );
        }
      }
    } else if (ext == 'xlsx') {
      try {
        final items = UniversalImporter.parseExcelBytes(file.bytes!);
        if (items.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No book records found in Excel file.')),
            );
          }
          return;
        }
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ImportPreviewModal(
                items: items,
                sourceName: file.name,
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error parsing Excel: $e')),
          );
        }
      }
    }
  }

  void _showJsonRestoreDialog(String fileName, List<int> bytes) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Restore from $fileName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select how you want to restore the database:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.merge_type_rounded, color: AppColors.caramelizedAmber),
              title: const Text('Merge & Keep Newest', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Combines incoming series/volumes without deleting your existing books.'),
              onTap: () {
                Navigator.pop(ctx);
                _executeJsonRestore(bytes, RestoreMode.mergeAndKeepNewest);
              },
            ),
            const Divider(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.restore_page_rounded, color: AppColors.statusDanger),
              title: const Text('Replace All (Wipe & Restore)', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.statusDanger)),
              subtitle: const Text('Erases current database and restores the exact state in the backup file.'),
              onTap: () {
                Navigator.pop(ctx);
                _executeJsonRestore(bytes, RestoreMode.replaceAll);
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ],
      ),
    );
  }

  Future<void> _executeJsonRestore(List<int> bytes, RestoreMode mode) async {
    setState(() => _isImporting = true);

    try {
      final jsonString = utf8.decode(bytes);
      final result = await UniversalImporter.restoreFromJson(jsonString, mode: mode);

      if (result.success) {
        ref.read(seriesNotifierProvider.notifier).load();
        ref.read(volumesNotifierProvider.notifier).load();
        ref.read(transactionsNotifierProvider.notifier).load();
        ref.read(ruleConfigNotifierProvider.notifier).load();
        ref.read(rulesNotifierProvider.notifier).load();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                mode == RestoreMode.replaceAll
                    ? 'Database restored: ${result.seriesCount} series, ${result.volumesCount} volumes, ${result.transactionsCount} transactions.'
                    : 'Merged: ${result.seriesCount} series, ${result.volumesCount} volumes added/updated.',
              ),
              backgroundColor: AppColors.statusSuccess,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Restore failed: ${result.errorMessage}'),
              backgroundColor: AppColors.statusDanger,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restore failed: $e'),
            backgroundColor: AppColors.statusDanger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  void _showPasteJsonDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import from Raw JSON'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Paste full database JSON backup text:'),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              maxLines: 8,
              decoration: const InputDecoration(
                hintText: '{\n  "version": "2.0.0",\n  "series": [...]\n}',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isEmpty) return;
              Navigator.pop(ctx);
              _executeJsonRestore(utf8.encode(text), RestoreMode.mergeAndKeepNewest);
            },
            child: const Text('Merge Import'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusDanger),
            onPressed: () {
              final text = controller.text.trim();
              if (text.isEmpty) return;
              Navigator.pop(ctx);
              _executeJsonRestore(utf8.encode(text), RestoreMode.replaceAll);
            },
            child: const Text('Replace All'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backupMeta = ref.watch(backupNotifierProvider);

    final lastBackupTimeStr = backupMeta.lastBackupTime != null
        ? DateFormat('yyyy-MM-dd HH:mm:ss').format(backupMeta.lastBackupTime!)
        : 'Never';

    return Scaffold(
      appBar: AppBar(
        title: const Text('File Hub & Auto-Backup'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= SECTION 1: AUTO-BACKUP ENGINE =================
            Row(
              children: [
                const Icon(Icons.sync_lock_rounded, color: AppColors.caramelizedAmber, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Auto-Backup Engine',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Target Folder Card
            const BackupFolderCard(),
            const SizedBox(height: 10),

            // Auto-Backup Settings & Status Card
            CaneleCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Master Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Auto-Backup on Changes',
                              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Automatic snapshot on database changes',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.darkTextMuted : AppColors.deepCaramelMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: backupMeta.isAutoBackupEnabled,
                        activeColor: AppColors.caramelizedAmber,
                        onChanged: (val) {
                          ref.read(backupNotifierProvider.notifier).toggleAutoBackup(val);
                        },
                      ),
                    ],
                  ),
                  const Divider(height: 20),

                  // Status Panel Grid
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Last Backup Time',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? AppColors.darkTextMuted : AppColors.deepCaramelMuted,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              lastBackupTimeStr,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Backup Snapshot Size',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? AppColors.darkTextMuted : AppColors.deepCaramelMuted,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatBytes(backupMeta.lastBackupSizeBytes),
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Rolling Backup Safeguard badge
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkPastryCardElevated : AppColors.pastryCrustLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.security_rounded,
                          size: 16,
                          color: backupMeta.lastBackupStatus == 'error'
                              ? AppColors.statusDanger
                              : AppColors.statusSuccess,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            backupMeta.lastBackupStatus == 'error'
                                ? 'Backup error: ${backupMeta.lastErrorMessage ?? "Storage error"}'
                                : 'Rolling backup active (canele_autobackup_prev.json)',
                            style: TextStyle(
                              fontSize: 11,
                              color: backupMeta.lastBackupStatus == 'error'
                                  ? AppColors.statusDanger
                                  : (isDark ? AppColors.darkTextPrimary : AppColors.deepCaramel),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Manual Backup Now Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isBackingUp ? null : _triggerManualBackup,
                      icon: _isBackingUp
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.backup_rounded, size: 18),
                      label: Text(_isBackingUp ? 'Creating Snapshot...' : 'Backup Now (Manual Snapshot)'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ================= SECTION 2: EXPORTS =================
            Row(
              children: [
                const Icon(Icons.file_download_rounded, color: AppColors.caramelizedAmber, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Exports',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 10),

            CaneleCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.save_as_rounded, color: AppColors.caramelizedAmber),
                    title: const Text('Full State Backup (.canele / .json)', style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: const Text('Complete database snapshot with rules and history'),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    onTap: () => _openExportSheet(ExportType.fullState),
                  ),
                  const Divider(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.table_chart_rounded, color: AppColors.caramelizedAmber),
                    title: const Text('Collection Spreadsheet (.csv / .xlsx)', style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: const Text('Spreadsheet of all series, volumes, and formats'),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    onTap: () => _openExportSheet(ExportType.collectionSpreadsheet),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ================= SECTION 3: IMPORTS =================
            Row(
              children: [
                const Icon(Icons.file_upload_rounded, color: AppColors.caramelizedAmber, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Imports & Restore',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 10),

            CaneleCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.file_open_rounded, color: AppColors.caramelizedAmber),
                    title: const Text('Select File to Import', style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: const Text('Supports .canele, .json, .csv, .xlsx, Goodreads & StoryGraph'),
                    trailing: _isImporting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    onTap: _isImporting ? null : _pickAndImportFile,
                  ),
                  const Divider(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.code_rounded, color: AppColors.caramelizedAmber),
                    title: const Text('Paste Raw JSON Backup Text'),
                    subtitle: const Text('Restore database from clipboard text'),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    onTap: _showPasteJsonDialog,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
