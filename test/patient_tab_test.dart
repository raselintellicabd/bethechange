import 'package:bethechange/core/constants/app_constants.dart';
import 'package:bethechange/core/router/app_router.dart';
import 'package:bethechange/core/router/app_routes.dart';
import 'package:bethechange/core/utils/external_link_handler.dart';
import 'package:bethechange/features/patient/presentation/screens/patient_tab_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ExternalLinkHandler', () {
    test('opens http(s) URLs with externalApplication mode', () async {
      Uri? launched;
      LaunchMode? usedMode;

      final handler = ExternalLinkHandler(
        canLaunch: (_) async => true,
        launch: (uri, {required LaunchMode mode}) async {
          launched = uri;
          usedMode = mode;
          return true;
        },
      );

      final ok = await handler.openExternal(AppConstants.patientPortalUrl);

      expect(ok, isTrue);
      expect(launched.toString(), AppConstants.patientPortalUrl);
      expect(usedMode, LaunchMode.externalApplication);
    });

    test('rejects non-http schemes', () async {
      final handler = ExternalLinkHandler(
        canLaunch: (_) async => true,
        launch: (_, {required LaunchMode mode}) async => true,
      );

      expect(await handler.openExternal('ftp://example.com'), isFalse);
      expect(await handler.openExternal('not a url'), isFalse);
    });

    test('returns false when canLaunch is false', () async {
      final handler = ExternalLinkHandler(
        canLaunch: (_) async => false,
        launch: (_, {required LaunchMode mode}) async => true,
      );

      expect(
        await handler.openExternal(AppConstants.shopSupplementsUrl),
        isFalse,
      );
    });
  });

  group('PatientTabScreen', () {
    testWidgets('shows exactly three cards and no membership', (tester) async {
      final router = createAppRouter();
      final opened = <String>[];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            externalLinkHandlerProvider.overrideWithValue(
              ExternalLinkHandler(
                canLaunch: (_) async => true,
                launch: (uri, {required LaunchMode mode}) async {
                  opened.add(uri.toString());
                  return true;
                },
              ),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump();

      router.go(AppRoutes.patient);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      for (final title in PatientTabScreen.cardTitles) {
        expect(find.text(title), findsOneWidget);
      }
      expect(PatientTabScreen.cardTitles, hasLength(3));

      expect(find.textContaining('Membership', findRichText: true), findsNothing);
      expect(find.textContaining('membership', findRichText: true), findsNothing);

      await tester.tap(find.text('Patient Portal'));
      await tester.pump();
      expect(opened, [AppConstants.patientPortalUrl]);

      await tester.tap(find.text('Shop Supplements'));
      await tester.pump();
      expect(opened, [
        AppConstants.patientPortalUrl,
        AppConstants.shopSupplementsUrl,
      ]);
    });

    testWidgets('Book a Service navigates to Services tab', (tester) async {
      final router = createAppRouter();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump();

      router.go(AppRoutes.patient);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.text('Book a Service'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(router.routeInformationProvider.value.uri.path, AppRoutes.services);
      expect(find.text('Services'), findsWidgets);
    });
  });
}
