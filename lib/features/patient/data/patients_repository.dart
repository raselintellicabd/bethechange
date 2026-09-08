import '../../../core/network/api_client.dart';
import '../../../core/network/api_paths.dart';
import '../../../core/network/api_result.dart';
import '../domain/models/patients_content.dart';

class PatientsRepository {
  PatientsRepository(this._client);

  final ApiClient _client;

  Future<ApiResult<PatientsContent>> getPatientsContent() {
    return _client.get(
      ApiPaths.patients,
      parser: (data) => PatientsContent.fromJson(data as Map<String, dynamic>),
    );
  }
}
