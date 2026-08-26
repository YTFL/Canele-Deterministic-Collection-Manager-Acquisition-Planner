import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/series_repository.dart';
import '../repositories/volume_repository.dart';
import '../repositories/transaction_repository.dart';
import '../repositories/rule_config_repository.dart';
import '../repositories/pass_repository.dart';
import '../repositories/rule_repository.dart';

final seriesRepositoryProvider = Provider<SeriesRepository>((ref) {
  return SeriesRepository();
});

final volumeRepositoryProvider = Provider<VolumeRepository>((ref) {
  return VolumeRepository();
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository();
});

final ruleConfigRepositoryProvider = Provider<RuleConfigRepository>((ref) {
  return RuleConfigRepository();
});

final passRepositoryProvider = Provider<PassRepository>((ref) {
  return PassRepository();
});

final ruleRepositoryProvider = Provider<RuleRepository>((ref) {
  return RuleRepository();
});

