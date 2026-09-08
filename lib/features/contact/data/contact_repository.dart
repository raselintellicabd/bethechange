import '../../../core/network/api_result.dart';
import '../domain/models/contact_request.dart';

/// Contact form networking contract. See `contact_api_contract.dart`.
abstract class ContactRepository {
  Future<ApiResult<ContactSubmissionResult>> submit(ContactRequest request);
}
