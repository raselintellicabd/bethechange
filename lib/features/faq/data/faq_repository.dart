import '../../../core/network/api_client.dart';
import '../../../core/network/api_paths.dart';
import '../../../core/network/api_result.dart';
import '../domain/models/faq_catalog.dart';

class FaqRepository {
  FaqRepository(this._client);

  final ApiClient _client;

  Future<ApiResult<FaqCatalog>> getFaq() {
    return _client.get(
      '${ApiPaths.faq}/',
      parser: (data) => FaqCatalog.fromJson(data as Map<String, dynamic>),
    );
  }
}
