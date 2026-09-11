import '../../../core/network/api_result.dart';
import '../domain/models/contact_page.dart';
import '../domain/models/contact_request.dart';

/// Contact screen networking contract.
abstract class ContactRepository {
  Future<ApiResult<ContactPage>> getContactPage();

  Future<ApiResult<ContactSubmissionResult>> submit(ContactRequest request);
}
