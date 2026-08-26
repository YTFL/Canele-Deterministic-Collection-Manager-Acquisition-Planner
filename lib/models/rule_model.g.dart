part of 'rule_model.dart';

class RuleScopeTypeAdapter extends TypeAdapter<RuleScopeType> {
  @override
  final int typeId = 10;

  @override
  RuleScopeType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return RuleScopeType.allSeries;
      case 1:
        return RuleScopeType.specificSeries;
      case 2:
        return RuleScopeType.tagBased;
      case 3:
        return RuleScopeType.formatType;
      default:
        return RuleScopeType.allSeries;
    }
  }

  @override
  void write(BinaryWriter writer, RuleScopeType obj) {
    switch (obj) {
      case RuleScopeType.allSeries:
        writer.writeByte(0);
        break;
      case RuleScopeType.specificSeries:
        writer.writeByte(1);
        break;
      case RuleScopeType.tagBased:
        writer.writeByte(2);
        break;
      case RuleScopeType.formatType:
        writer.writeByte(3);
        break;
    }
  }
}

class ProgressTriggerTypeAdapter extends TypeAdapter<ProgressTriggerType> {
  @override
  final int typeId = 11;

  @override
  ProgressTriggerType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ProgressTriggerType.none;
      case 1:
        return ProgressTriggerType.exactVolumesLeft;
      case 2:
        return ProgressTriggerType.leastRemainingVolumes;
      case 3:
        return ProgressTriggerType.completionPercentage;
      case 4:
        return ProgressTriggerType.gapFilling;
      default:
        return ProgressTriggerType.none;
    }
  }

  @override
  void write(BinaryWriter writer, ProgressTriggerType obj) {
    switch (obj) {
      case ProgressTriggerType.none:
        writer.writeByte(0);
        break;
      case ProgressTriggerType.exactVolumesLeft:
        writer.writeByte(1);
        break;
      case ProgressTriggerType.leastRemainingVolumes:
        writer.writeByte(2);
        break;
      case ProgressTriggerType.completionPercentage:
        writer.writeByte(3);
        break;
      case ProgressTriggerType.gapFilling:
        writer.writeByte(4);
        break;
    }
  }
}

class SortCriteriaAdapter extends TypeAdapter<SortCriteria> {
  @override
  final int typeId = 12;

  @override
  SortCriteria read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SortCriteria.earliestReleaseDate;
      case 1:
        return SortCriteria.lowestVolumeNumber;
      case 2:
        return SortCriteria.closestToCompletion;
      case 3:
        return SortCriteria.alphabetical;
      default:
        return SortCriteria.earliestReleaseDate;
    }
  }

  @override
  void write(BinaryWriter writer, SortCriteria obj) {
    switch (obj) {
      case SortCriteria.earliestReleaseDate:
        writer.writeByte(0);
        break;
      case SortCriteria.lowestVolumeNumber:
        writer.writeByte(1);
        break;
      case SortCriteria.closestToCompletion:
        writer.writeByte(2);
        break;
      case SortCriteria.alphabetical:
        writer.writeByte(3);
        break;
    }
  }
}

class RuleModelAdapter extends TypeAdapter<RuleModel> {
  @override
  final int typeId = 13;

  @override
  RuleModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RuleModel(
      id: fields[0] as String,
      name: fields[1] as String,
      isEnabled: fields[2] as bool,
      priorityOrder: fields[3] as int,
      scopeType: fields[4] as RuleScopeType,
      targetSeriesIds: (fields[5] as List?)?.cast<String>() ?? const [],
      targetTags: (fields[6] as List?)?.cast<String>() ?? const [],
      targetFormat: fields[7] as String?,
      progressTrigger: fields[8] as ProgressTriggerType,
      volumeThresholdValue: fields[9] as int?,
      percentageThreshold: fields[10] as double?,
      restockPriorityEnabled: fields[11] as bool,
      sortBy: fields[12] as SortCriteria,
    );
  }

  @override
  void write(BinaryWriter writer, RuleModel obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.isEnabled)
      ..writeByte(3)
      ..write(obj.priorityOrder)
      ..writeByte(4)
      ..write(obj.scopeType)
      ..writeByte(5)
      ..write(obj.targetSeriesIds)
      ..writeByte(6)
      ..write(obj.targetTags)
      ..writeByte(7)
      ..write(obj.targetFormat)
      ..writeByte(8)
      ..write(obj.progressTrigger)
      ..writeByte(9)
      ..write(obj.volumeThresholdValue)
      ..writeByte(10)
      ..write(obj.percentageThreshold)
      ..writeByte(11)
      ..write(obj.restockPriorityEnabled)
      ..writeByte(12)
      ..write(obj.sortBy);
  }
}
