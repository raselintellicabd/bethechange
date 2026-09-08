import '../../../core/network/api_client.dart';
import '../../../core/network/api_paths.dart';
import '../../../core/network/api_result.dart';
import '../domain/models/condition.dart';
import '../domain/models/conditions_catalog.dart';

class ConditionsRepository {
  ConditionsRepository(this._client);

  final ApiClient _client;

  Future<ApiResult<ConditionsCatalog>> getConditions() {
    return _client.get(
      ApiPaths.conditions,
      parser: (data) =>
          ConditionsCatalog.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResult<Condition>> getConditionById(String id) {
    return _client.get(
      ApiPaths.condition(id),
      parser: (data) => Condition.fromJson(data as Map<String, dynamic>),
    );
  }
}
