import 'package:bethechange/core/network/api_client.dart';
import 'package:bethechange/core/router/app_router.dart';
import 'package:bethechange/core/router/app_routes.dart';
import 'package:bethechange/core/utils/external_link_handler.dart';
import 'package:bethechange/features/clinic/domain/models/clinic_info.dart';
import 'package:bethechange/features/patient/domain/models/patients_content.dart';
import 'package:bethechange/features/patient/presentation/providers/patients_providers.dart';
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

const _patients = PatientsContent(
  sectionTitle: 'Patient resources',
  sectionSubtitle: 'Portal access, booking, supplements, and answers.',
  tiles: [
    PatientTileItem(
      id: 'portal',
      title: 'Patient Portal',
      subtitle: 'Records & messages',
      icon: 'account_circle_outlined',
      action: PatientTileAction(
        type: PatientTileActionType.externalUrlKey,
        urlKey: 'patientPortalUrl',
      ),
    ),
    PatientTileItem(
      id: 'book-service',
      title: 'Book a service',
      subtitle: 'Browse therapies',
      icon: 'medical_services_outlined',
      action: PatientTileAction(
        type: PatientTileActionType.route,
        route: '/explore/services',
      ),
    ),
    PatientTileItem(
      id: 'shop',
      title: 'Shop',
      subtitle: 'Fullscript shop',
      icon: 'shopping_bag_outlined',
      action: PatientTileAction(
        type: PatientTileActionType.externalUrlKey,
        urlKey: 'shopSupplementsUrl',
      ),
    ),
    PatientTileItem(
      id: 'faq',
      title: 'FAQ',
      subtitle: 'Common questions',
      icon: 'help_outline',
      action: PatientTileAction(
        type: PatientTileActionType.route,
        route: '/faq',
      ),
    ),
  ],
);

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

      final ok = await handler.openExternal(_clinic.patientPortalUrl);

      expect(ok, isTrue);
      expect(launched.toString(), _clinic.patientPortalUrl);
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
        await handler.openExternal(_clinic.shopSupplementsUrl),
        isFalse,
      );
    });
  });

  group('PatientTabScreen', () {
    List<Override> overrides({
      required List<String> opened,
    }) {
      return [
        apiClientProvider.overrideWithValue(createMockApiClient()),
        patientClinicLinksProvider.overrideWith((ref) async => _clinic),
        patientsContentProvider.overrideWith((ref) async => _patients),
        externalLinkHandlerProvider.overrideWithValue(
          ExternalLinkHandler(
            canLaunch: (_) async => true,
            launch: (uri, {required LaunchMode mode}) async {
              opened.add(uri.toString());
              return true;
            },
          ),
        ),
      ];
    }

    testWidgets('shows exactly four tiles and no membership', (tester) async {
      final router = createAppRouter();
      final opened = <String>[];

      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides(opened: opened),
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump();

      router.go(AppRoutes.patients);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      for (final tile in _patients.tiles) {
        expect(find.text(tile.title), findsOneWidget);
      }
      expect(_patients.tiles, hasLength(4));

      expect(find.textContaining('Membership', findRichText: true), findsNothing);
      expect(find.textContaining('membership', findRichText: true), findsNothing);

      await tester.tap(find.text('Patient Portal'));
      await tester.pump();
      expect(opened, [_clinic.patientPortalUrl]);

      final shop = find.text('Shop');
      await tester.ensureVisible(shop);
      await tester.pump();
      await tester.tap(shop);
      await tester.pump();
      expect(opened, [
        _clinic.patientPortalUrl,
        _clinic.shopSupplementsUrl,
      ]);
    });

    testWidgets('Book a service navigates to Explore Services', (tester) async {
      final router = createAppRouter();

      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides(opened: <String>[]),
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump();

      router.go(AppRoutes.patients);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.text('Book a service'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(
        router.routeInformationProvider.value.uri.path,
        AppRoutes.exploreServices,
      );
      expect(find.text('Services'), findsWidgets);
    });
  });
}
