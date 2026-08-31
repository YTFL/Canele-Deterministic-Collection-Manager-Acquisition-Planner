class BackupMetadata {
  final String? targetDirectoryPath;
  final bool isAutoBackupEnabled;
  final DateTime? lastBackupTime;
  final int lastBackupSizeBytes;
  final String lastBackupStatus; // 'idle', 'in_progress', 'success', 'error'
  final String? lastErrorMessage;

  const BackupMetadata({
    this.targetDirectoryPath,
    this.isAutoBackupEnabled = false,
    this.lastBackupTime,
    this.lastBackupSizeBytes = 0,
    this.lastBackupStatus = 'idle',
    this.lastErrorMessage,
  });

  BackupMetadata copyWith({
    String? targetDirectoryPath,
    bool? isAutoBackupEnabled,
    DateTime? lastBackupTime,
    int? lastBackupSizeBytes,
    String? lastBackupStatus,
    String? lastErrorMessage,
    bool clearDirectoryPath = false,
    bool clearErrorMessage = false,
  }) {
    return BackupMetadata(
      targetDirectoryPath: clearDirectoryPath
          ? null
          : (targetDirectoryPath ?? this.targetDirectoryPath),
      isAutoBackupEnabled: isAutoBackupEnabled ?? this.isAutoBackupEnabled,
      lastBackupTime: lastBackupTime ?? this.lastBackupTime,
      lastBackupSizeBytes: lastBackupSizeBytes ?? this.lastBackupSizeBytes,
      lastBackupStatus: lastBackupStatus ?? this.lastBackupStatus,
      lastErrorMessage: clearErrorMessage
          ? null
          : (lastErrorMessage ?? this.lastErrorMessage),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'targetDirectoryPath': targetDirectoryPath,
      'isAutoBackupEnabled': isAutoBackupEnabled,
      'lastBackupTime': lastBackupTime?.toIso8601String(),
      'lastBackupSizeBytes': lastBackupSizeBytes,
      'lastBackupStatus': lastBackupStatus,
      'lastErrorMessage': lastErrorMessage,
    };
  }

  factory BackupMetadata.fromMap(Map<dynamic, dynamic> map) {
    DateTime? parsedDate;
    if (map['lastBackupTime'] is String && (map['lastBackupTime'] as String).isNotEmpty) {
      parsedDate = DateTime.tryParse(map['lastBackupTime'] as String);
    }

    return BackupMetadata(
      targetDirectoryPath: map['targetDirectoryPath'] as String?,
      isAutoBackupEnabled: map['isAutoBackupEnabled'] as bool? ?? false,
      lastBackupTime: parsedDate,
      lastBackupSizeBytes: map['lastBackupSizeBytes'] as int? ?? 0,
      lastBackupStatus: map['lastBackupStatus'] as String? ?? 'idle',
      lastErrorMessage: map['lastErrorMessage'] as String?,
    );
  }

  static BackupMetadata initial() {
    return const BackupMetadata(
      targetDirectoryPath: null,
      isAutoBackupEnabled: true,
      lastBackupTime: null,
      lastBackupSizeBytes: 0,
      lastBackupStatus: 'idle',
      lastErrorMessage: null,
    );
  }
}
