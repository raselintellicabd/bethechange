import '../../../core/network/api_result.dart';
import '../domain/models/contact_request.dart';
import 'contact_repository.dart';

/// In-memory mock of `POST /contact` until the backend endpoint exists.
///
/// Put `force error` in the subject or message (case-insensitive) to simulate
/// a network/server failure.
class MockContactRepository implements ContactRepository {
  MockContactRepository({
    this.delay = const Duration(milliseconds: 400),
  });

  final Duration delay;
  int _counter = 0;

  @override
  Future<ApiResult<ContactSubmissionResult>> submit(
    ContactRequest request,
  ) async {
    await Future<void>.delayed(delay);

    final haystack =
        '${request.subject} ${request.message}'.trim().toLowerCase();
    if (haystack.contains('force error')) {
      return const ApiFailure(
        message: 'Unable to send your message. Please try again.',
        statusCode: 503,
      );
    }

    if (request.name.isEmpty ||
        request.email.isEmpty ||
        request.phone.isEmpty ||
        request.subject.isEmpty ||
        request.message.isEmpty) {
      return const ApiFailure(
        message: 'All contact fields are required.',
        statusCode: 400,
      );
    }

    return ApiSuccess(
      ContactSubmissionResult(
        id: 'contact-${++_counter}',
        status: 'received',
      ),
    );
  }
}
