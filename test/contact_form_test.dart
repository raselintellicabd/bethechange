import 'package:bethechange/core/constants/app_constants.dart';
import 'package:bethechange/core/network/api_result.dart';
import 'package:bethechange/core/router/app_router.dart';
import 'package:bethechange/core/router/app_routes.dart';
import 'package:bethechange/core/utils/external_link_handler.dart';
import 'package:bethechange/features/contact/data/mock_contact_repository.dart';
import 'package:bethechange/features/contact/domain/models/contact_request.dart';
import 'package:bethechange/features/contact/presentation/providers/contact_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MockContactRepository', () {
    test('submits successfully and returns id', () async {
      final result = await MockContactRepository(delay: Duration.zero).submit(
        const ContactRequest(
          name: 'Alex Patient',
          email: 'alex@example.com',
          phone: '3015551212',
          subject: 'Question about hours',
          message: 'What time do you open on Fridays?',
        ),
      );

      expect(result, isA<ApiSuccess<ContactSubmissionResult>>());
      final data = (result as ApiSuccess<ContactSubmissionResult>).data;
      expect(data.id, isNotEmpty);
      expect(data.status, 'received');
    });

    test('force error in subject/message fails', () async {
      final result = await MockContactRepository(delay: Duration.zero).submit(
        const ContactRequest(
          name: 'Alex Patient',
          email: 'alex@example.com',
          phone: '3015551212',
          subject: 'force error',
          message: 'Please fail this request for testing.',
        ),
      );

      expect(result, isA<ApiFailure>());
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

      final ok = await handler.openExternal(AppConstants.clinicPhoneTel);
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
            contactRepositoryProvider.overrideWithValue(
              MockContactRepository(delay: Duration.zero),
            ),
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
      expect(find.text(AppConstants.clinicName), findsOneWidget);
      expect(
        find.text('Phone: ${AppConstants.clinicPhoneDisplay}'),
        findsOneWidget,
      );

      await tapSend(tester);

      expect(find.text('Name is required'), findsOneWidget);
      expect(find.text('Email is required'), findsOneWidget);
    });

    testWidgets('success clears form; failure shows retry', (tester) async {
      await openContact(tester);

      Future<void> fillForm({
        required String subject,
        required String message,
      }) async {
        await tester.enterText(fieldAt(0), 'Alex Patient');
        await tester.enterText(fieldAt(1), 'alex@example.com');
        await tester.enterText(fieldAt(2), '3015551212');
        await tester.enterText(fieldAt(3), subject);
        await tester.enterText(fieldAt(4), message);
        await tester.pump();
      }

      await fillForm(
        subject: 'force error',
        message: 'Please fail this submission path.',
      );
      await tapSend(tester);
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.textContaining('Unable to send your message'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await fillForm(
        subject: 'Hours question',
        message: 'What time do you open on Fridays?',
      );
      await tapSend(tester);
      await tester.pump(const Duration(milliseconds: 50));

      expect(
        find.text('Thanks — your message was sent successfully.'),
        findsOneWidget,
      );
      expect(tester.widget<TextFormField>(fieldAt(0)).controller?.text, isEmpty);
    });
  });
}
