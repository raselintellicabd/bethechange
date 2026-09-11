import '../../../core/network/api_client.dart';
import '../../../core/network/api_paths.dart';
import '../../../core/network/api_result.dart';
import '../domain/models/contact_page.dart';
import '../domain/models/contact_request.dart';
import 'contact_repository.dart';

/// Contact screen via `GET` / `POST /api/v1/contact/`.
class ContactApiRepository implements ContactRepository {
  ContactApiRepository(this._client);

  final ApiClient _client;

  static const path = '${ApiPaths.contact}/';

  @override
  Future<ApiResult<ContactPage>> getContactPage() {
    return _client.get(
      path,
      parser: (data) => ContactPage.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<ApiResult<ContactSubmissionResult>> submit(ContactRequest request) {
    return _client.post(
      path,
      data: request.toJson(),
      parser: (data) =>
          ContactSubmissionResult.fromJson(data as Map<String, dynamic>),
    );
  }
}
