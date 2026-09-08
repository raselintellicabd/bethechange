import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../../core/config/env_config.dart';
import '../../../core/network/api_result.dart';
import '../domain/models/chat_message.dart';
import 'chatbot_repository.dart';

/// In-memory mock of `POST /chatbot/message`.
///
/// Notes containing `force error` (case-insensitive) simulate API failure.
class MockChatbotRepository implements ChatbotRepository {
  MockChatbotRepository({
    String? apiKey,
    this._delay = const Duration(milliseconds: 350),
  }) : _apiKey = apiKey ?? _defaultApiKey();

  final String _apiKey;
  final Duration _delay;
  int _conversationCounter = 0;

  static String _defaultApiKey() {
    try {
      if (dotenv.isInitialized) {
        return EnvConfig.chatbotApiKey;
      }
    } catch (_) {
      // Fall through when env is unavailable (e.g. unit tests).
    }
    return 'placeholder';
  }

  @override
  Future<ApiResult<ChatbotReply>> sendMessage({
    required String message,
    String? conversationId,
  }) async {
    await Future<void>.delayed(_delay);

    if (_apiKey.trim().isEmpty) {
      return const ApiFailure(
        message: 'Chatbot API key is missing.',
        statusCode: 401,
      );
    }

    final trimmed = message.trim();
    if (trimmed.isEmpty) {
      return const ApiFailure(
        message: 'Message cannot be empty.',
        statusCode: 400,
      );
    }

    if (trimmed.toLowerCase().contains('force error')) {
      return const ApiFailure(
        message: 'Unable to reach the chatbot. Please try again.',
        statusCode: 503,
      );
    }

    final id = (conversationId != null && conversationId.isNotEmpty)
        ? conversationId
        : 'mock-convo-${++_conversationCounter}';

    return ApiSuccess(
      ChatbotReply(
        reply: _replyFor(trimmed),
        conversationId: id,
      ),
    );
  }

  String _replyFor(String message) {
    final lower = message.toLowerCase();

    if (_matches(lower, const ['hello', 'hi', 'hey'])) {
      return 'Hello! I can help with scheduling, insurance, location, '
          'therapies, and other clinic questions. What would you like to know?';
    }
    if (_matches(lower, const ['schedule', 'book', 'appointment', 'visit'])) {
      return 'To schedule, fill out the new patient form and our team will '
          'call or text you. The process usually takes about 5–10 minutes. '
          'You can also browse Services in the app and request an appointment '
          'from a specific service page.';
    }
    if (_matches(lower, const ['insurance', 'cover', 'reimburse'])) {
      return 'We are an out-of-network provider and do not bill insurance '
          'directly. After visits we provide an invoice with codes so you can '
          'submit for possible reimbursement. Coverage is not guaranteed.';
    }
    if (_matches(lower, const ['where', 'location', 'address', 'located'])) {
      return 'We are at 8808 Centre Park Drive, Suite 301, Columbia, MD 21045.';
    }
    if (_matches(lower, const ['hour', 'open', 'closed'])) {
      return 'Clinic hours can vary by day—please call 301-970-9724 or check '
          'with our front desk for the latest schedule.';
    }
    if (_matches(lower, const ['therap', 'service', 'fsm', 'sauna', 'hbot', 'ozone', 'iv'])) {
      return 'We offer therapies such as FSM, infrared sauna, HBOT, nutritional '
          'IVs, ozone therapy, ion foot detox, and more. Open the Services tab '
          'for details, or ask about a specific therapy.';
    }
    if (_matches(lower, const ['portal', 'login', 'records'])) {
      return 'Use the Patient tab → Patient Portal to open the secure portal '
          'in your browser.';
    }
    if (_matches(lower, const ['supplement', 'fullscript', 'shop'])) {
      return 'Recommended supplements are ordered through Fullscript. Open '
          'Patient → Shop Supplements to visit our dispensary.';
    }
    if (_matches(lower, const ['cost', 'price', 'fee', 'how much', 'pricing'])) {
      return 'Visit length and clinician affect pricing. See the FAQ for '
          'Dr. Afrooz and Dr. Needle appointment ranges, or ask our new '
          'patient team for a transparent quote when you schedule.';
    }
    if (_matches(lower, const ['doctor', 'afrooz', 'needle', 'physician'])) {
      return 'Our clinicians include Dr. Sultana Afrooz and Dr. Needle. See the '
          'About tab for practice background, or the FAQ for visit pricing.';
    }
    if (_matches(lower, const ['faq', 'question'])) {
      return 'You can browse the FAQ screen for common answers, or keep asking '
          'me here and I will do my best to help.';
    }

    return 'Thanks for your message. I am a clinic assistant and can help with '
        'scheduling, insurance, location, therapies, the patient portal, and '
        'supplements. Try rephrasing, or browse the FAQ for detailed answers.';
  }

  bool _matches(String lower, List<String> keywords) {
    for (final keyword in keywords) {
      if (lower.contains(keyword)) return true;
    }
    return false;
  }
}
