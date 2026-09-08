import '../../../core/network/api_client.dart';
import '../../../core/network/api_paths.dart';
import '../../../core/network/api_result.dart';
import '../domain/models/contact_request.dart';
import 'contact_repository.dart';

/// Contact form networking via `POST /contact`.
class ContactApiRepository implements ContactRepository {
  ContactApiRepository(this._client);

  final ApiClient _client;

  @override
  Future<ApiResult<ContactSubmissionResult>> submit(ContactRequest request) {
    return _client.post(
      ApiPaths.contact,
      data: request.toJson(),
      parser: (data) =>
          ContactSubmissionResult.fromJson(data as Map<String, dynamic>),
    );
  }
}
