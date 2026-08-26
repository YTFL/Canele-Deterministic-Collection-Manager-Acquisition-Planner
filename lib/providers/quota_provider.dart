import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/rule_config.dart';
import '../services/quota_engine.dart';
import 'database_provider.dart';
import 'series_provider.dart';

class RuleConfigNotifier extends StateNotifier<RuleConfig> {
  final Ref _ref;
  RuleConfigNotifier(this._ref) : super(RuleConfig.createDefault()) {
    load();
  }

  void load() {
    state = _ref.read(ruleConfigRepositoryProvider).getConfig();
  }

  Future<void> updateConfig(RuleConfig config) async {
    await _ref.read(ruleConfigRepositoryProvider).saveConfig(config);
    state = config;
  }
}

final ruleConfigNotifierProvider = StateNotifierProvider<RuleConfigNotifier, RuleConfig>((ref) {
  return RuleConfigNotifier(ref);
});

final quotaProvider = Provider<QuotaSummary>((ref) {
  final config = ref.watch(ruleConfigNotifierProvider);
  final transactions = ref.watch(transactionsNotifierProvider);

  return QuotaEngine.calculate(
    config: config,
    transactions: transactions,
  );
});
