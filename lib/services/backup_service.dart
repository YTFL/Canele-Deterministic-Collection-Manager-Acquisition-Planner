import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/database/hive_boxes.dart';
import '../models/backup_metadata.dart';
import 'universal_exporter.dart';

typedef BackupMetadataCallback = void Function(BackupMetadata metadata);

class BackupService {
  static final BackupService _instance = BackupService._internal();
  static BackupService get instance => _instance;

  factory BackupService() => _instance;

  BackupService._internal();

  Timer? _debounceTimer;
  Duration debounceDuration = const Duration(seconds: 3);

  final List<StreamSubscription<BoxEvent>> _subscriptions = [];
  bool _isListening = false;
  bool _isPaused = false;

  String? _targetDirectoryPath;
  bool _isAutoBackupEnabled = true;
  BackupMetadata _currentMetadata = BackupMetadata.initial();
  BackupMetadataCallback? _onMetadataChanged;

  bool get isListening => _isListening;
  bool get isPaused => _isPaused;
  String? get targetDirectoryPath => _targetDirectoryPath;
  bool get isAutoBackupEnabled => _isAutoBackupEnabled;
  BackupMetadata get currentMetadata => _currentMetadata;

  /// Loads persisted configuration from Hive on startup and starts listening immediately
  void initFromStorage() {
    try {
      final raw = HiveBoxes.ruleConfigBox.get('backup_metadata');
      if (raw != null) {
        _currentMetadata = BackupMetadata.fromMap(raw);
        _targetDirectoryPath = _currentMetadata.targetDirectoryPath;
        _isAutoBackupEnabled = _currentMetadata.isAutoBackupEnabled;
      } else {
        _currentMetadata = BackupMetadata.initial();
        _targetDirectoryPath = _currentMetadata.targetDirectoryPath;
        _isAutoBackupEnabled = _currentMetadata.isAutoBackupEnabled;
      }
    } catch (e) {
      debugPrint('[BackupService] initFromStorage error: $e');
    }

    if (_isAutoBackupEnabled) {
      startListening();
    }
  }

  /// Requests runtime storage permissions on Android (All Files Access / MANAGE_EXTERNAL_STORAGE)
  static Future<bool> requestStoragePermissions() async {
    if (!Platform.isAndroid) return true;

    try {
      var manageStatus = await Permission.manageExternalStorage.status;
      if (!manageStatus.isGranted) {
        manageStatus = await Permission.manageExternalStorage.request();
      }
      if (manageStatus.isGranted) return true;

      var storageStatus = await Permission.storage.status;
      if (!storageStatus.isGranted) {
        storageStatus = await Permission.storage.request();
      }
      return storageStatus.isGranted;
    } catch (e) {
      debugPrint('[BackupService] Permission request failed: $e');
      return false;
    }
  }

  void configure({
    String? targetDirectoryPath,
    bool? isAutoBackupEnabled,
    BackupMetadataCallback? onMetadataChanged,
    Duration? customDebounceDuration,
    bool clearTargetDirectory = false,
  }) {
    if (clearTargetDirectory) {
      _targetDirectoryPath = null;
    } else if (targetDirectoryPath != null) {
      _targetDirectoryPath = targetDirectoryPath;
    }

    if (isAutoBackupEnabled != null) {
      _isAutoBackupEnabled = isAutoBackupEnabled;
    }
    if (onMetadataChanged != null) {
      _onMetadataChanged = onMetadataChanged;
    }
    if (customDebounceDuration != null) {
      debounceDuration = customDebounceDuration;
    }

    _currentMetadata = _currentMetadata.copyWith(
      targetDirectoryPath: _targetDirectoryPath,
      isAutoBackupEnabled: _isAutoBackupEnabled,
    );

    if (_isAutoBackupEnabled && !_isListening) {
      startListening();
    } else if (!_isAutoBackupEnabled && _isListening) {
      stopListening();
    }
  }

  void startListening() {
    stopListening();
    _isListening = true;

    void onMutation(BoxEvent event) {
      if (_isPaused || !_isAutoBackupEnabled) return;

      // Ignore metadata and migration box keys to avoid infinite save loops
      if (event.key == 'backup_metadata' ||
          event.key == 'app_database_schema_version' ||
          event.key == 'global_config_backup') {
        return;
      }

      debugPrint('[BackupService] Box mutation detected on key: ${event.key}. Triggering debounced auto-backup...');
      _triggerDebouncedBackup();
    }

    try {
      _subscriptions.add(HiveBoxes.seriesBox.watch().listen(onMutation));
      _subscriptions.add(HiveBoxes.volumesBox.watch().listen(onMutation));
      _subscriptions.add(HiveBoxes.transactionsBox.watch().listen(onMutation));
      _subscriptions.add(HiveBoxes.rulesBox.watch().listen(onMutation));
      _subscriptions.add(HiveBoxes.ruleConfigBox.watch().listen(onMutation));
      debugPrint('[BackupService] Active and listening to Hive box mutations.');
    } catch (e) {
      debugPrint('[BackupService] Error starting Hive watchers: $e');
    }
  }

  void stopListening() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    _isListening = false;
  }

  void pauseListening() {
    _isPaused = true;
    _debounceTimer?.cancel();
  }

  void resumeListening() {
    _isPaused = false;
  }

  void _triggerDebouncedBackup() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounceDuration, () async {
      if (!_isPaused && _isAutoBackupEnabled) {
        debugPrint('[BackupService] Debounce timer elapsed. Creating auto-backup snapshot...');
        await createBackupSnapshot();
      }
    });
  }

  /// Resolves target directory
  Future<Directory> resolveTargetDirectory([String? customPath]) async {
    final candidatePath = customPath ?? _targetDirectoryPath;

    if (candidatePath != null && candidatePath.trim().isNotEmpty) {
      final dir = Directory(candidatePath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir;
    }

    final appDocDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${appDocDir.path}/canele_backups');
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    return backupDir;
  }

  /// Helper to atomically write snapshot and rotate rolling previous backup
  Future<File> _writeAtomicSnapshot(
    Directory dir,
    String baseFileName,
    String jsonContent,
  ) async {
    final tempFile = File('${dir.path}/canele_backup.tmp');
    final mainFile = File('${dir.path}/$baseFileName.json');
    final prevFile = File('${dir.path}/${baseFileName}_prev.json');

    // 1. Write to temp file
    await tempFile.writeAsString(jsonContent, flush: true);

    // 2. Rotate previous backup
    if (await mainFile.exists()) {
      try {
        if (await prevFile.exists()) {
          await prevFile.delete();
        }
        await mainFile.rename(prevFile.path);
      } catch (_) {
        try {
          await mainFile.copy(prevFile.path);
          await mainFile.delete();
        } catch (_) {}
      }
    }

    // 3. Move temp to main
    File finalFile;
    try {
      finalFile = await tempFile.rename(mainFile.path);
    } catch (_) {
      finalFile = await tempFile.copy(mainFile.path);
      try {
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      } catch (_) {}
    }

    return finalFile;
  }

  /// Creates atomic snapshot with rolling secondary backup strictly in the selected target directory
  Future<File?> createBackupSnapshot({
    String? targetDirectory,
    String baseFileName = 'canele_autobackup',
  }) async {
    _currentMetadata = _currentMetadata.copyWith(
      lastBackupStatus: 'in_progress',
      clearErrorMessage: true,
    );
    _onMetadataChanged?.call(_currentMetadata);

    try {
      final jsonContent = UniversalExporter.exportFullAppStateToJson(indent: true);
      final customPath = targetDirectory ?? _targetDirectoryPath;

      File? writtenFile;
      String? errorMsg;

      // 1. Try writing to custom directory if configured
      if (customPath != null && customPath.trim().isNotEmpty) {
        try {
          final customDir = Directory(customPath);
          if (!await customDir.exists()) {
            await customDir.create(recursive: true);
          }
          writtenFile = await _writeAtomicSnapshot(customDir, baseFileName, jsonContent);
        } catch (e) {
          debugPrint('[BackupService] Custom folder write failed: $e');
          errorMsg = e.toString();
          if (Platform.isAndroid && (errorMsg.contains('errno = 1') || errorMsg.contains('errno = 13'))) {
            errorMsg = 'Storage permission required. Please enable "All Files Access" for Canelé in Android Settings.';
          }
        }
      }

      // 2. If no custom directory OR custom directory failed, write to guaranteed app docs directory
      if (writtenFile == null) {
        final appDocDir = await getApplicationDocumentsDirectory();
        final backupDir = Directory('${appDocDir.path}/canele_backups');
        if (!await backupDir.exists()) {
          await backupDir.create(recursive: true);
        }
        writtenFile = await _writeAtomicSnapshot(backupDir, baseFileName, jsonContent);
      }

      final fileSize = await writtenFile.length();
      final now = DateTime.now();

      _currentMetadata = _currentMetadata.copyWith(
        targetDirectoryPath: _targetDirectoryPath ?? writtenFile.parent.path,
        lastBackupTime: now,
        lastBackupSizeBytes: fileSize,
        lastBackupStatus: errorMsg != null ? 'error' : 'success',
        lastErrorMessage: errorMsg,
      );
      _onMetadataChanged?.call(_currentMetadata);

      debugPrint('[BackupService] Auto-backup successfully written: ${writtenFile.path} ($fileSize bytes)');
      return writtenFile;
    } catch (e) {
      debugPrint('[BackupService] Backup creation failed: $e');
      _currentMetadata = _currentMetadata.copyWith(
        lastBackupStatus: 'error',
        lastErrorMessage: e.toString(),
      );
      _onMetadataChanged?.call(_currentMetadata);
      return null;
    }
  }

  /// Trigger immediate manual backup
  Future<File?> performManualBackup({String? targetDirectory}) async {
    return await createBackupSnapshot(
      targetDirectory: targetDirectory ?? _targetDirectoryPath,
      baseFileName: 'canele_autobackup',
    );
  }

  void dispose() {
    stopListening();
  }
}
