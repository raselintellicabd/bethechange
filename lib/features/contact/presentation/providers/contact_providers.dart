import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/analytics/analytics_service.dart';
import '../../../../core/network/api_client.dart';
import '../../data/contact_api_repository.dart';
import '../../data/contact_repository.dart';
import '../../domain/models/contact_request.dart';

final contactRepositoryProvider = Provider<ContactRepository>((ref) {
  return ContactApiRepository(ref.watch(apiClientProvider));
});

class ContactFormState {
  const ContactFormState({
    this.isSubmitting = false,
    this.errorMessage,
    this.submission,
  });

  final bool isSubmitting;
  final String? errorMessage;
  final ContactSubmissionResult? submission;

  bool get isSuccess => submission != null;

  ContactFormState copyWith({
    bool? isSubmitting,
    String? errorMessage,
    ContactSubmissionResult? submission,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return ContactFormState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      submission: clearSuccess ? null : (submission ?? this.submission),
    );
  }
}

class ContactController extends StateNotifier<ContactFormState> {
  ContactController(this._repository, this._analytics)
      : super(const ContactFormState());

  final ContactRepository _repository;
  final AnalyticsService _analytics;

  Future<bool> submit(ContactRequest request) async {
    if (state.isSubmitting) return false;

    state = state.copyWith(
      isSubmitting: true,
      clearError: true,
      clearSuccess: true,
    );

    final result = await _repository.submit(request);
    return result.when(
      success: (data) {
        _analytics.logEvent(
          AnalyticsEvents.contactSubmitted,
          parameters: {'id': data.id},
        );
        state = state.copyWith(
          isSubmitting: false,
          submission: data,
          clearError: true,
        );
        return true;
      },
      failure: (message, _) {
        state = state.copyWith(
          isSubmitting: false,
          errorMessage: message,
          clearSuccess: true,
        );
        return false;
      },
    );
  }

  void clearFeedback() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }
}

final contactControllerProvider =
    StateNotifierProvider.autoDispose<ContactController, ContactFormState>(
  (ref) => ContactController(
    ref.watch(contactRepositoryProvider),
    ref.watch(analyticsServiceProvider),
  ),
);
