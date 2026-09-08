import '../../../core/network/api_result.dart';
import '../../../core/utils/asset_loader.dart';
import '../domain/models/service.dart';
import '../domain/models/services_catalog.dart';

class ServicesRepository {
  ServicesRepository({AssetLoader? assetLoader})
      : _assetLoader = assetLoader ?? AssetLoader();

  static const String assetPath = 'assets/data/services.json';

  final AssetLoader _assetLoader;

  Future<ApiResult<ServicesCatalog>> getServices() {
    return _assetLoader.loadJsonObject(
      assetPath,
      parser: ServicesCatalog.fromJson,
    );
  }

  Future<ApiResult<Service>> getServiceById(String id) async {
    final catalogResult = await getServices();
    return catalogResult.when(
      success: (catalog) {
        final service = catalog.byId(id);
        if (service == null) {
          return ApiFailure(message: 'Service "$id" was not found.');
        }
        return ApiSuccess(service);
      },
      failure: (message, statusCode) => ApiFailure(
        message: message,
        statusCode: statusCode,
      ),
    );
  }
}
