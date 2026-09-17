import '../../../core/network/api_client.dart';
import '../../../core/network/api_paths.dart';
import '../../../core/network/api_result.dart';
import '../domain/models/membership_catalog.dart';

/// Membership packages via `GET /api/v1/memberships/`.
class MembershipRepository {
  MembershipRepository(this._client);

  final ApiClient _client;

  static const path = '${ApiPaths.memberships}/';

  Future<ApiResult<MembershipCatalog>> getMemberships() {
    return _client.get(
      path,
      parser: (data) =>
          MembershipCatalog.fromJson(data as Map<String, dynamic>),
    );
  }
}
