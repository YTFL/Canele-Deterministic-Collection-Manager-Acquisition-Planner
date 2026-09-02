import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/rule_config.dart';
import '../services/quota_engine.dart';
import '../services/exchange_rate_service.dart';
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

class ExchangeRatesNotifier extends StateNotifier<ExchangeRates> {
  ExchangeRatesNotifier() : super(ExchangeRateService.loadFromStorage());

  /// Automatically triggered when viewing Stats: fetches only if >= 24h since last sync
  Future<bool> checkAndAutoFetch() async {
    if (!ExchangeRateService.canSync(rates: state)) {
      return false;
    }
    final fresh = await ExchangeRateService.fetchAndPersistLatestRates();
    if (fresh != null) {
      state = fresh;
      return true;
    }
    return false;
  }

  /// Manually triggered by user: respects the 24h limit / retry on failure
  Future<bool> manualSync() async {
    if (!ExchangeRateService.canSync(rates: state)) {
      return false;
    }
    final fresh = await ExchangeRateService.fetchAndPersistLatestRates(force: true);
    if (fresh != null) {
      state = fresh;
      return true;
    }
    return false;
  }
}

final exchangeRatesNotifierProvider = StateNotifierProvider<ExchangeRatesNotifier, ExchangeRates>((ref) {
  return ExchangeRatesNotifier();
});

final quotaProvider = Provider<QuotaSummary>((ref) {
  final config = ref.watch(ruleConfigNotifierProvider);
  final transactions = ref.watch(transactionsNotifierProvider);
  final allSeries = ref.watch(seriesNotifierProvider);
  final allVolumes = ref.watch(volumesNotifierProvider);
  final exchangeRates = ref.watch(exchangeRatesNotifierProvider);

  return QuotaEngine.calculate(
    config: config,
    transactions: transactions,
    allSeries: allSeries,
    allVolumes: allVolumes,
    exchangeRates: exchangeRates,
  );
});
