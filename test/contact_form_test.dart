import 'package:bethechange/core/network/api_client.dart';
import 'package:bethechange/core/network/api_result.dart';
import 'package:bethechange/core/router/app_router.dart';
import 'package:bethechange/core/router/app_routes.dart';
import 'package:bethechange/core/utils/external_link_handler.dart';
import 'package:bethechange/features/clinic/domain/models/clinic_info.dart';
import 'package:bethechange/features/clinic/presentation/providers/clinic_providers.dart';
import 'package:bethechange/features/contact/domain/models/contact_request.dart';
import 'package:bethechange/features/contact/presentation/providers/contact_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher/url_launcher.dart';

import 'helpers/mock_api_client.dart';

const _clinic = ClinicInfo(
  name: 'Be The Change Health & Wellness Center',
  addressLine1: '8808 Centre Park Drive, Suite 301',
  addressLine2: 'Columbia, MD 21045',
  phoneDisplay: '301-970-9724',
  phoneTel: 'tel:3019709724',
  faxDisplay: '301-359-1986',
  hours: 'Monday–Friday (call to confirm today’s hours)',
  patientPortalUrl: 'https://be-the-change-portal.md-hq.com/',
  shopSupplementsUrl: 'https://us.fullscript.com//welcome/safrooz',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ContactApiRepository', () {
    test('submits successfully and returns id', () async {
      final result = await createMockContactRepository().submit(
        const ContactRequest(
          name: 'Alex Patient',
          email: 'alex@example.com',
          phone: '3015551212',
          message: 'What time do you open on Fridays?',
        ),
      );

      expect(result, isA<ApiSuccess<ContactSubmissionResult>>());
      final data = (result as ApiSuccess<ContactSubmissionResult>).data;
      expect(data.id, isNotEmpty);
      expect(data.name, 'Alex Patient');
      expect(data.email, 'alex@example.com');
      expect(data.isRead, isFalse);
      expect(data.createdAt, isNotNull);
      expect(data.conversation, isNotNull);
    });

    test('force error in the message fails', () async {
      final result = await createMockContactRepository().submit(
        const ContactRequest(
          name: 'Alex Patient',
          email: 'alex@example.com',
          phone: '3015551212',
          message: 'Please force error this request for testing.',
        ),
      );

      expect(result, isA<ApiFailure>());
    });

    test('fromJson accepts the contact message response', () {
      final result = ContactSubmissionResult.fromJson({
        'id': 12,
        'name': 'Rasel Rahman',
        'email': 'rasel.intellicabd@gmail.com',
        'phone': '01703266722',
        'message': 'I, testing from swagger',
        'is_read': false,
        'created_at': '2026-09-11T06:54:04.655004Z',
        'conversation': 3,
      });

      expect(result.id, '12');
      expect(result.email, 'rasel.intellicabd@gmail.com');
      expect(result.isRead, isFalse);
      expect(result.conversation, 3);
      expect(result.receivedLabel, isNotEmpty);
      expect(result.statusLabel, 'Waiting for our team to reply');
    });
  });

  group('ExternalLinkHandler tel', () {
    test('allows tel scheme', () async {
      Uri? launched;
      final handler = ExternalLinkHandler(
        canLaunch: (_) async => true,
        launch: (uri, {required LaunchMode mode}) async {
          launched = uri;
          return true;
        },
      );

      final ok = await handler.openExternal(_clinic.phoneTel);
      expect(ok, isTrue);
      expect(launched?.scheme, 'tel');
    });
  });

  group('ContactScreen', () {
    Finder fieldAt(int index) => find.byType(TextFormField).at(index);

    Future<void> openContact(WidgetTester tester) async {
      final router = createAppRouter();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWithValue(createMockApiClient()),
            contactRepositoryProvider.overrideWithValue(
              createMockContactRepository(),
            ),
            clinicInfoProvider.overrideWith((ref) async => _clinic),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump();
      router.go(AppRoutes.contact);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
    }

    Future<void> tapSend(WidgetTester tester) async {
      final send = find.text('Send message');
      await tester.ensureVisible(send);
      await tester.pump();
      await tester.tap(send);
      await tester.pump();
    }

    testWidgets('blocks invalid submit and shows clinic info', (tester) async {
      await openContact(tester);

      expect(find.text('Contact'), findsWidgets);
      expect(find.text(_clinic.name), findsOneWidget);
      expect(find.text(_clinic.phoneDisplay), findsOneWidget);

      await tapSend(tester);

      expect(find.text('Name is required'), findsOneWidget);
      expect(find.text('Email is required'), findsOneWidget);
    });

    testWidgets('success clears form; failure shows retry', (tester) async {
      await openContact(tester);

      Future<void> fillForm({required String message}) async {
        await tester.enterText(fieldAt(0), 'Alex Patient');
        await tester.enterText(fieldAt(1), 'alex@example.com');
        await tester.enterText(fieldAt(2), '3015551212');
        await tester.enterText(fieldAt(3), message);
        await tester.pump();
      }

      await fillForm(message: 'Please force error this submission path.');
      await tapSend(tester);
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.textContaining('Unable to send your message'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await fillForm(message: 'What time do you open on Fridays?');
      await tapSend(tester);
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Message sent'), findsOneWidget);
      expect(find.textContaining('Thanks, Alex Patient'), findsOneWidget);
      expect(find.text('Waiting for our team to reply'), findsOneWidget);
      expect(find.text('Send another message'), findsOneWidget);
    });
  });
}
