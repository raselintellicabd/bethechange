import '../../../core/network/api_client.dart';
import '../../../core/network/api_paths.dart';
import '../../../core/network/api_result.dart';
import '../domain/models/home_content.dart';

class HomeRepository {
  HomeRepository(this._client);

  final ApiClient _client;

  Future<ApiResult<HomeContent>> getHomeContent() {
    return _client.get(
      ApiPaths.home,
      parser: (data) => HomeContent.fromJson(data as Map<String, dynamic>),
    );
  }
}
