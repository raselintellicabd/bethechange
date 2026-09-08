import '../../../core/network/api_result.dart';
import '../../../core/utils/asset_loader.dart';
import '../domain/models/condition.dart';
import '../domain/models/conditions_catalog.dart';

class ConditionsRepository {
  ConditionsRepository({AssetLoader? assetLoader})
      : _assetLoader = assetLoader ?? AssetLoader();

  static const String assetPath = 'assets/data/conditions.json';

  final AssetLoader _assetLoader;

  Future<ApiResult<ConditionsCatalog>> getConditions() {
    return _assetLoader.loadJsonObject(
      assetPath,
      parser: ConditionsCatalog.fromJson,
    );
  }

  Future<ApiResult<Condition>> getConditionById(String id) async {
    final catalogResult = await getConditions();
    return catalogResult.when(
      success: (catalog) {
        final condition = catalog.byId(id);
        if (condition == null) {
          return ApiFailure(message: 'Condition "$id" was not found.');
        }
        return ApiSuccess(condition);
      },
      failure: (message, statusCode) => ApiFailure(
        message: message,
        statusCode: statusCode,
      ),
    );
  }
}
