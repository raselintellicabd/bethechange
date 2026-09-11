import '../../../core/network/api_client.dart';
import '../../../core/network/api_paths.dart';
import '../../../core/network/api_result.dart';
import '../domain/models/doctor_profile.dart';

class DoctorRepository {
  DoctorRepository(this._client);

  final ApiClient _client;

  Future<ApiResult<DoctorProfile>> getDoctor(String slug) {
    return _client.get(
      '${ApiPaths.doctor(slug)}/',
      parser: (data) => DoctorProfile.fromJson(data as Map<String, dynamic>),
    );
  }
}
