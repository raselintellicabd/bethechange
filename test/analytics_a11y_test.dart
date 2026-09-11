import 'package:bethechange/core/analytics/analytics_service.dart';
import 'package:bethechange/core/widgets/appointment_cta_bar.dart';
import 'package:bethechange/features/appointment/domain/models/patient_details.dart';
import 'package:bethechange/features/appointment/domain/models/source_context.dart';
import 'package:bethechange/features/appointment/presentation/providers/appointment_providers.dart';
import 'package:bethechange/features/chatbot/presentation/providers/chatbot_providers.dart';
import 'package:bethechange/features/contact/domain/models/contact_request.dart';
import 'package:bethechange/features/contact/presentation/providers/contact_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/mock_api_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('AnalyticsEvents does not include membership', () {
    for (final name in AnalyticsEvents.allowed) {
      expect(name.toLowerCase(), isNot(contains('membership')));
    }
  });

  test('appointment + contact + chatbot emit expected events', () async {
    final analytics = RecordingAnalyticsService();
    const source = SourceContext(
      type: SourceContextType.service,
      id: 'frequency-specific-microcurrent',
      name: 'FSM',
    );
    // Fixed Tuesday so mock availability includes the day.
    final now = DateTime(2026, 9, 8, 10);
    final repository = createMockAppointmentRepository(now: now);

    final appointment = AppointmentController(
      repository: repository,
      sourceContext: source,
      analytics: analytics,
      now: now,
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(analytics.hasEvent(AnalyticsEvents.appointmentStarted), isTrue);

    await appointment.selectDate(DateTime(2026, 9, 8));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(appointment.state.slots, isNotEmpty);
    appointment.selectSlot(appointment.state.slots.first);
    appointment.continueToDetails();
    appointment.submitPatientDetails(
      const PatientDetails(
        name: 'Alex',
        email: 'alex@example.com',
        phone: '3015551212',
      ),
    );
    await appointment.confirmBooking();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(analytics.hasEvent(AnalyticsEvents.appointmentCompleted), isTrue);

    final contact = ContactController(
      createMockContactRepository(),
      analytics,
    );
    await contact.submit(
      const ContactRequest(
        name: 'Alex',
        email: 'alex@example.com',
        phone: '3015551212',
        message: 'This is a detailed enough message.',
      ),
    );
    expect(analytics.hasEvent(AnalyticsEvents.contactSubmitted), isTrue);

    final chatbot = ChatbotController(
      createMockChatbotRepository(),
      analytics,
    );
    await chatbot.send('hello');
    expect(analytics.hasEvent(AnalyticsEvents.chatbotMessageSent), isTrue);
  });

  testWidgets('appointment CTA exposes accessible label', (tester) async {
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: AppointmentCtaBar(
              sourceContext: SourceContext(
                type: SourceContextType.condition,
                id: 'diabetes',
                name: 'Diabetes',
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Request an appointment'), findsOneWidget);
    expect(find.text('Reason: Diabetes'), findsOneWidget);
    final semantics = tester.getSemantics(find.byType(AppointmentCtaBar));
    expect(
      semantics.label,
      contains('Request an appointment for Diabetes'),
    );
    handle.dispose();
  });
}
