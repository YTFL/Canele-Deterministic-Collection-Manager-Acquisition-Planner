import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/database/hive_boxes.dart';
import '../models/backup_metadata.dart';
import '../services/backup_service.dart';

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService.instance;
});

class BackupNotifier extends StateNotifier<BackupMetadata> {
  final Ref _ref;

  BackupNotifier(this._ref) : super(BackupMetadata.initial()) {
    _loadAndInit();
  }

  void _loadAndInit() {
    try {
      final raw = HiveBoxes.ruleConfigBox.get('backup_metadata');
      if (raw != null && raw is Map) {
        state = BackupMetadata.fromMap(raw);
      }
    } catch (_) {}

    // Configure singleton service
    final service = _ref.read(backupServiceProvider);
    service.configure(
      targetDirectoryPath: state.targetDirectoryPath,
      isAutoBackupEnabled: state.isAutoBackupEnabled,
      onMetadataChanged: (newMeta) {
        state = newMeta;
        _persistMetadata(newMeta);
      },
    );
  }

  Future<void> _persistMetadata(BackupMetadata meta) async {
    try {
      await HiveBoxes.ruleConfigBox.put('backup_metadata', meta.toMap());
    } catch (_) {}
  }

  Future<void> setTargetDirectory(String path) async {
    state = state.copyWith(targetDirectoryPath: path);
    await _persistMetadata(state);

    final service = _ref.read(backupServiceProvider);
    service.configure(
      targetDirectoryPath: path,
      isAutoBackupEnabled: state.isAutoBackupEnabled,
      onMetadataChanged: (newMeta) {
        state = newMeta;
        _persistMetadata(newMeta);
      },
    );
  }

  Future<void> clearTargetDirectory() async {
    state = state.copyWith(clearDirectoryPath: true);
    await _persistMetadata(state);

    final service = _ref.read(backupServiceProvider);
    service.configure(
      clearTargetDirectory: true,
      isAutoBackupEnabled: state.isAutoBackupEnabled,
      onMetadataChanged: (newMeta) {
        state = newMeta;
        _persistMetadata(newMeta);
      },
    );
  }

  Future<void> toggleAutoBackup(bool enabled) async {
    state = state.copyWith(isAutoBackupEnabled: enabled);
    await _persistMetadata(state);

    final service = _ref.read(backupServiceProvider);
    service.configure(
      targetDirectoryPath: state.targetDirectoryPath,
      isAutoBackupEnabled: enabled,
      onMetadataChanged: (newMeta) {
        state = newMeta;
        _persistMetadata(newMeta);
      },
    );
  }

  Future<bool> performManualBackup() async {
    final service = _ref.read(backupServiceProvider);
    final file = await service.createBackupSnapshot(
      targetDirectory: state.targetDirectoryPath,
    );
    return file != null;
  }
}

final backupNotifierProvider =
    StateNotifierProvider<BackupNotifier, BackupMetadata>((ref) {
  return BackupNotifier(ref);
});
