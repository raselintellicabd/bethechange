import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/conditions_repository.dart';
import '../../domain/models/condition.dart';
import '../../domain/models/conditions_catalog.dart';

final conditionsRepositoryProvider = Provider<ConditionsRepository>((ref) {
  return ConditionsRepository(ref.watch(apiClientProvider));
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
  final result =
      await ref.watch(conditionsRepositoryProvider).getConditionById(id);
  return result.when(
    success: (data) => data,
    failure: (message, _) => throw Exception(message),
  );
});
