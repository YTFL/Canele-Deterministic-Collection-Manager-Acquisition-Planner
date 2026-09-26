import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../services/universal_exporter.dart';
import '../../services/profile_service.dart';

enum ExportType {
  fullState,
  collectionSpreadsheet,
}

enum FileFormat {
  canele,
  json,
  csv,
  xlsx,
}

class ExportOptionsSheet extends StatefulWidget {
  final ExportType initialType;

  const ExportOptionsSheet({
    super.key,
    this.initialType = ExportType.fullState,
  });

  @override
  State<ExportOptionsSheet> createState() => _ExportOptionsSheetState();
}

class _ExportOptionsSheetState extends State<ExportOptionsSheet> {
  late ExportType _exportType;
  late FileFormat _fileFormat;
  bool _exportAllWorkspaces = true;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _exportType = widget.initialType;
    _fileFormat = _defaultFormatFor(_exportType);
  }

  FileFormat _defaultFormatFor(ExportType type) {
    switch (type) {
      case ExportType.fullState:
        return FileFormat.canele;
      case ExportType.collectionSpreadsheet:
        return FileFormat.csv;
    }
  }

  List<FileFormat> get _availableFormats {
    switch (_exportType) {
      case ExportType.fullState:
        return [FileFormat.canele, FileFormat.json];
      case ExportType.collectionSpreadsheet:
        return [FileFormat.csv, FileFormat.xlsx];
    }
  }

  Future<void> _executeExport() async {
    setState(() => _isExporting = true);

    try {
      final timeStamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final activeProfile = ProfileService.instance.activeProfile;

      switch (_exportType) {
        case ExportType.fullState:
          final specificId = _exportAllWorkspaces ? null : activeProfile.id;
          final jsonString = UniversalExporter.exportFullAppStateToJson(indent: true, specificProfileId: specificId);
          final ext = _fileFormat == FileFormat.canele ? 'canele' : 'json';
          final prefix = _exportAllWorkspaces
              ? 'canele_full_backup'
              : 'canele_${activeProfile.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}';
          final fileName = '${prefix}_$timeStamp.$ext';
          final bytes = utf8.encode(jsonString);

          await UniversalExporter.shareExportedFile(
            bytes: bytes,
            fileName: fileName,
            subject: _exportAllWorkspaces ? 'Canelé Full Database Backup' : 'Canelé Workspace Backup (${activeProfile.name})',
            text: 'Canelé offline state backup ($fileName)',
          );
          break;

        case ExportType.collectionSpreadsheet:
          final prefix = 'canele_${activeProfile.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}';
          if (_fileFormat == FileFormat.csv) {
            final csvStr = UniversalExporter.exportCollectionToCsv(profile: activeProfile);
            final fileName = '${prefix}_$timeStamp.csv';
            final bytes = utf8.encode(csvStr);
            await UniversalExporter.shareExportedFile(
              bytes: bytes,
              fileName: fileName,
              subject: 'Canelé Collection Spreadsheet (${activeProfile.name} - CSV)',
            );
          } else {
            final bytes = UniversalExporter.exportCollectionToXlsx(profile: activeProfile);
            final fileName = '${prefix}_$timeStamp.xlsx';
            await UniversalExporter.shareExportedFile(
              bytes: bytes,
              fileName: fileName,
              subject: 'Canelé Collection Spreadsheet (${activeProfile.name} - Excel)',
            );
          }
          break;
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
          const SnackBar(
            content: Text('Export generated successfully!'),
            backgroundColor: AppColors.statusSuccess,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: AppColors.statusDanger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _copyToClipboard() {
    final activeProfile = ProfileService.instance.activeProfile;
    final specificId = _exportAllWorkspaces ? null : activeProfile.id;
    final jsonString = UniversalExporter.exportFullAppStateToJson(indent: true, specificProfileId: specificId);
    Clipboard.setData(ClipboardData(text: jsonString));
    Navigator.pop(context);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
      const SnackBar(content: Text('Database JSON copied to clipboard!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeProfile = ProfileService.instance.activeProfile;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
                  Icons.file_download_rounded,
                  color: AppColors.caramelizedAmber,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Export Data',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Export Type Selection
          Text(
            'Select Export Content',
            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          SegmentedButton<ExportType>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                value: ExportType.fullState,
                label: Text('Full State', style: TextStyle(fontSize: 12)),
              ),
              ButtonSegment(
                value: ExportType.collectionSpreadsheet,
                label: Text('Collection', style: TextStyle(fontSize: 12)),
              ),
            ],
            selected: {_exportType},
            onSelectionChanged: (set) {
              setState(() {
                _exportType = set.first;
                _fileFormat = _defaultFormatFor(_exportType);
              });
            },
          ),
          const SizedBox(height: 16),

          // Workspace Scope Selection (for Full State)
          if (_exportType == ExportType.fullState) ...[
            Text(
              'Backup Scope',
              style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: [
                const ButtonSegment(
                  value: true,
                  label: Text('All Workspaces', style: TextStyle(fontSize: 12)),
                ),
                ButtonSegment(
                  value: false,
                  label: Text('Only "${activeProfile.name}"', style: const TextStyle(fontSize: 12)),
                ),
              ],
              selected: {_exportAllWorkspaces},
              onSelectionChanged: (set) => setState(() => _exportAllWorkspaces = set.first),
            ),
            const SizedBox(height: 16),
          ],

          // Format Selection
          Text(
            'Select Format',
            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _availableFormats.map((fmt) {
              final isSelected = _fileFormat == fmt;
              String label = fmt.name.toUpperCase();
              if (fmt == FileFormat.canele) label = '.CANELE (Full App)';
              if (fmt == FileFormat.json) label = '.JSON (Universal)';
              if (fmt == FileFormat.csv) label = '.CSV (Spreadsheet)';
              if (fmt == FileFormat.xlsx) label = '.XLSX (Excel)';

              return ChoiceChip(
                label: Text(label),
                selected: isSelected,
                selectedColor: AppColors.caramelizedAmber,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black87),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _fileFormat = fmt);
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Actions
          Row(
            children: [
              if (_exportType == ExportType.fullState)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isExporting ? null : _copyToClipboard,
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text('Copy JSON'),
                  ),
                ),
              if (_exportType == ExportType.fullState) const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _isExporting ? null : _executeExport,
                  icon: _isExporting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.share_rounded, size: 18),
                  label: Text(_isExporting ? 'Generating...' : 'Export & Share File'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
