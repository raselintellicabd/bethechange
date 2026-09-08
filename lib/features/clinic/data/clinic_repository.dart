import '../../../core/network/api_client.dart';
import '../../../core/network/api_paths.dart';
import '../../../core/network/api_result.dart';
import '../domain/models/clinic_info.dart';

class ClinicRepository {
  ClinicRepository(this._client);

  final ApiClient _client;

  Future<ApiResult<ClinicInfo>> getClinicInfo() {
    return _client.get(
      ApiPaths.clinic,
      parser: (data) => ClinicInfo.fromJson(data as Map<String, dynamic>),
    );
  }
}
