import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/conditions_repository.dart';
import '../../domain/models/condition.dart';
import '../../domain/models/conditions_catalog.dart';

final conditionsRepositoryProvider = Provider<ConditionsRepository>((ref) {
  return ConditionsRepository();
});

final conditionsCatalogProvider = FutureProvider<ConditionsCatalog>((ref) async {
  final result = await ref.watch(conditionsRepositoryProvider).getConditions();
  return result.when(
    success: (data) => data,
    failure: (message, _) => throw Exception(message),
  );
});

final conditionByIdProvider =
    FutureProvider.family<Condition, String>((ref, id) async {
  final catalog = await ref.watch(conditionsCatalogProvider.future);
  final condition = catalog.byId(id);
  if (condition == null) {
    throw Exception('Condition "$id" was not found.');
  }
  return condition;
});
