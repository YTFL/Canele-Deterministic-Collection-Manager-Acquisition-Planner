import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/rule_evaluator.dart';
import 'rule_provider.dart';
import 'series_provider.dart';

final recommendationSlotsProvider = Provider<List<RecommendationSlot>>((ref) {
  final rules = ref.watch(rulesNotifierProvider);
  final series = ref.watch(seriesNotifierProvider);
  final volumes = ref.watch(volumesNotifierProvider);

  return RuleEvaluator.evaluate(
    rules: rules,
    seriesList: series,
    volumesList: volumes,
    maxSlots: 4,
  );
});
