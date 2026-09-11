import 'package:bethechange/core/network/api_client.dart';
import 'package:bethechange/core/network/api_result.dart';
import 'package:bethechange/core/router/app_router.dart';
import 'package:bethechange/core/router/app_routes.dart';
import 'package:bethechange/core/utils/external_link_handler.dart';
import 'package:bethechange/features/clinic/domain/models/clinic_info.dart';
import 'package:bethechange/features/contact/domain/models/contact_page.dart';
import 'package:bethechange/features/contact/domain/models/contact_request.dart';
import 'package:bethechange/features/contact/presentation/providers/contact_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher/url_launcher.dart';

import 'helpers/mock_api_client.dart';

const _page = ContactPage(
  title: 'Interested in An Appointment?',
  content: 'Please text the clinic.',
  location: ContactLocation(
    title: 'Our Location',
    name: 'Be The Change Health & Wellness Center',
    addressLine1: '8808 Centre Park Drive, Suite 301',
    addressLine2: 'Columbia, MD 21045',
    phone: '301-970-9724',
    phoneTel: 'tel:3019709724',
    fax: '301-359-1986',
    hours: 'Mon–Fri: 10:00 AM – 5:00 PM',
    mapsUrl: 'https://maps.example.com/clinic',
  ),
  form: ContactFormContent(
    eyebrow: 'Contact',
    heading: 'Send Us A Message',
    submitLabel: 'Send Message',
    fields: [
      ContactFormField(name: 'name', label: 'Your Name', required: true),
      ContactFormField(name: 'email', label: 'Email Address', required: true),
      ContactFormField(name: 'phone', label: 'Phone Number', required: true),
      ContactFormField(name: 'message', label: 'Your Message', required: true),
    ],
  ),
);

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
    test('loads the contact page', () async {
      final result = await createMockContactRepository().getContactPage();
      expect(result, isA<ApiSuccess<ContactPage>>());
      final page = (result as ApiSuccess<ContactPage>).data;
      expect(page.title, 'Interested in An Appointment?');
      expect(page.form.submitLabel, 'Send Message');
      expect(page.location.phone, '301-970-9724');
    });

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
      expect(data.status, 'received');
      expect(data.statusLabel, 'Received');
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

    test('fromJson accepts the contact response', () {
      final page = ContactPage.fromJson({
        'title': 'Interested in An Appointment?',
        'content': 'Please text us.',
        'location': {
          'title': 'Our Location',
          'name': 'Be The Change Health & Wellness Center',
          'phone': '301-970-9724',
          'phoneTel': 'tel:3019709724',
          'mapsUrl': 'https://maps.example.com/clinic',
        },
        'form': {
          'heading': 'Send Us A Message',
          'submitLabel': 'Send Message',
          'fields': [
            {'name': 'name', 'label': 'Your Name', 'required': true},
          ],
        },
      });

      expect(page.title, 'Interested in An Appointment?');
      expect(page.location.directionsUrl, 'https://maps.example.com/clinic');
      expect(page.form.fields.single.label, 'Your Name');

      final result = ContactSubmissionResult.fromJson({
        'id': '14',
        'status': 'received',
      });

      expect(result.id, '14');
      expect(result.statusLabel, 'Received');
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
            contactPageProvider.overrideWith((ref) async => _page),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump();
      await tester.pump();
      router.go(AppRoutes.contact);
      await tester.pump();
      await tester.pump();
      await tester.pump();
    }

    Future<void> tapSend(WidgetTester tester) async {
      final send = find.widgetWithText(ElevatedButton, 'Send Message');
      await tester.ensureVisible(send);
      await tester.pump();
      await tester.tap(send);
      await tester.pump();
    }

    testWidgets('blocks invalid submit and shows clinic info', (tester) async {
      await openContact(tester);

      expect(find.text('Contact'), findsWidgets);
      expect(find.text(_page.location.name), findsOneWidget);
      expect(find.text(_page.location.phone), findsOneWidget);

      await tapSend(tester);

      expect(find.text('Your Name is required'), findsOneWidget);
      expect(find.text('Email Address is required'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1));
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
      expect(find.text('Received'), findsOneWidget);
      expect(find.text('Send another message'), findsOneWidget);
    });
  });
}
