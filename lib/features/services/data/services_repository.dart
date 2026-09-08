import '../../../core/network/api_client.dart';
import '../../../core/network/api_paths.dart';
import '../../../core/network/api_result.dart';
import '../domain/models/service.dart';
import '../domain/models/services_catalog.dart';

class ServicesRepository {
  ServicesRepository(this._client);

  final ApiClient _client;

  Future<ApiResult<ServicesCatalog>> getServices() {
    return _client.get(
      ApiPaths.services,
      parser: (data) => ServicesCatalog.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResult<Service>> getServiceById(String id) {
    return _client.get(
      ApiPaths.service(id),
      parser: (data) => Service.fromJson(data as Map<String, dynamic>),
    );
  }
}
