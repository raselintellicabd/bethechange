import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Allowed analytics event names (Phase K.3).
///
/// Intentionally excludes any Membership-related events.
abstract final class AnalyticsEvents {
  static const appointmentStarted = 'appointment_started';
  static const appointmentCompleted = 'appointment_completed';
  static const contactSubmitted = 'contact_submitted';
  static const chatbotMessageSent = 'chatbot_message_sent';

  static const allowed = <String>{
    appointmentStarted,
    appointmentCompleted,
    contactSubmitted,
    chatbotMessageSent,
  };
}

/// Lightweight analytics / crash-reporting seam.
///
/// Swap [LoggingAnalyticsService] for Firebase/Sentry later without touching UI.
abstract class AnalyticsService {
  void logEvent(String name, {Map<String, Object?> parameters = const {}});
}

/// Debug-print sink used until a production analytics SDK is wired.
class LoggingAnalyticsService implements AnalyticsService {
  const LoggingAnalyticsService();

  @override
  void logEvent(String name, {Map<String, Object?> parameters = const {}}) {
    assert(
      AnalyticsEvents.allowed.contains(name),
      'Unexpected analytics event "$name". Membership events are not allowed.',
    );
    if (kDebugMode) {
      debugPrint('[analytics] $name $parameters');
    }
  }
}

/// In-memory recorder for widget/unit tests.
class RecordingAnalyticsService implements AnalyticsService {
  final List<AnalyticsEventRecord> events = [];

  @override
  void logEvent(String name, {Map<String, Object?> parameters = const {}}) {
    assert(AnalyticsEvents.allowed.contains(name));
    events.add(AnalyticsEventRecord(name: name, parameters: parameters));
  }

  bool hasEvent(String name) => events.any((e) => e.name == name);
}

class AnalyticsEventRecord {
  const AnalyticsEventRecord({
    required this.name,
    required this.parameters,
  });

  final String name;
  final Map<String, Object?> parameters;
}

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return const LoggingAnalyticsService();
});
