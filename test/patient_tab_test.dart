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
import 'package:go_router/go_router.dart';
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
  sectionSubtitle: 'Portal access, booking, supplements and answers.',
  headerSubtitle: 'Manage your care in one place',
  tiles: [
    PatientTileItem(
      id: 'portal',
      title: 'Patient portal',
      subtitle: 'Records and messages',
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
      icon: 'calendar_plus_outlined',
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
    PatientTileItem(
      id: 'membership',
      title: 'Membership',
      subtitle: 'Coming soon',
      icon: 'badge_outlined',
      action: PatientTileAction(
        type: PatientTileActionType.none,
      ),
    ),
    PatientTileItem(
      id: 'contact',
      title: 'Contact',
      subtitle: 'Reach the clinic',
      icon: 'mail_outline',
      action: PatientTileAction(
        type: PatientTileActionType.route,
        route: '/contact',
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

    Future<void> openPatients(
      WidgetTester tester, {
      required GoRouter router,
      required List<String> opened,
    }) async {
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
    }

    testWidgets('shows redesign chrome, rows, and Membership Soon badge',
        (tester) async {
      final router = createAppRouter();
      final opened = <String>[];
      await openPatients(tester, router: router, opened: opened);

      expect(find.text('Manage your care in one place'), findsOneWidget);
      expect(find.text('Log in'), findsOneWidget);
      expect(find.text('Patient resources'), findsNothing);
      expect(
        find.text('Portal access, booking, supplements and answers.'),
        findsNothing,
      );
      expect(find.text('Soon'), findsOneWidget);

      expect(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Contact'),
        ),
        findsNothing,
      );

      expect(_patients.tiles, hasLength(6));
      final scrollable = find.byType(Scrollable).first;
      for (final tile in _patients.tiles) {
        final title = find.text(tile.title);
        await tester.scrollUntilVisible(title, 80, scrollable: scrollable);
        await tester.pump();
        expect(title, findsOneWidget);
      }

      await tester.scrollUntilVisible(
        find.text('Patient portal'),
        -80,
        scrollable: scrollable,
      );
      await tester.pump();
      await tester.tap(find.text('Patient portal'));
      await tester.pump();
      expect(opened, [_clinic.patientPortalUrl]);

      final shop = find.text('Shop');
      await tester.scrollUntilVisible(shop, 80, scrollable: scrollable);
      await tester.pump();
      await tester.tap(shop);
      await tester.pump();
      expect(opened, [
        _clinic.patientPortalUrl,
        _clinic.shopSupplementsUrl,
      ]);
    });

    testWidgets('Log in toggles to avatar and Log out', (tester) async {
      final router = createAppRouter();
      await openPatients(tester, router: router, opened: <String>[]);

      expect(find.text('Log in'), findsOneWidget);
      await tester.tap(find.text('Log in'));
      await tester.pump();

      expect(find.text('JD'), findsOneWidget);
      expect(find.text('Log out'), findsOneWidget);
      expect(find.text('Log in'), findsNothing);

      await tester.tap(find.text('Log out'));
      await tester.pump();
      expect(find.text('Log in'), findsOneWidget);
    });

    testWidgets('Book a service navigates to Explore Services', (tester) async {
      final router = createAppRouter();
      await openPatients(tester, router: router, opened: <String>[]);

      await tester.tap(find.text('Book a service'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(
        router.routeInformationProvider.value.uri.path,
        AppRoutes.exploreServices,
      );
      expect(find.text('Services'), findsWidgets);
    });

    testWidgets('Contact tile opens Contact screen', (tester) async {
      final router = createAppRouter();
      await openPatients(tester, router: router, opened: <String>[]);

      final contactTile = find.text('Reach the clinic');
      await tester.scrollUntilVisible(
        contactTile,
        80,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();
      await tester.tap(contactTile);
      await tester.pumpAndSettle();

      expect(find.text('Send Us A Message'), findsOneWidget);
    });
  });
}
