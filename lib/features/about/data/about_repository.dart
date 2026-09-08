import '../../../core/network/api_client.dart';
import '../../../core/network/api_paths.dart';
import '../../../core/network/api_result.dart';
import '../domain/models/about_content.dart';

class AboutRepository {
  AboutRepository(this._client);

  final ApiClient _client;

  Future<ApiResult<AboutContent>> getAboutContent() {
    return _client.get(
      ApiPaths.about,
      parser: (data) => AboutContent.fromJson(data as Map<String, dynamic>),
    );
  }
}
