import 'package:bethechange/core/network/api_client.dart';
import 'package:bethechange/core/router/app_router.dart';
import 'package:bethechange/core/router/app_routes.dart';
import 'package:bethechange/core/utils/external_link_handler.dart';
import 'package:bethechange/features/auth/data/auth_repository.dart';
import 'package:bethechange/features/auth/domain/models/patient_user.dart';
import 'package:bethechange/features/auth/presentation/providers/auth_providers.dart';
import 'package:bethechange/features/clinic/domain/models/clinic_info.dart';
import 'package:bethechange/features/patient/domain/models/patients_content.dart';
import 'package:bethechange/features/patient/presentation/providers/patients_providers.dart';
import 'package:bethechange/features/patient/presentation/screens/patient_tab_screen.dart';
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
  sections: [
    PatientSection(
      id: 'my-account',
      title: 'My account',
      tiles: [
        PatientTileItem(
          id: 'profile',
          title: 'Profile',
          subtitle: 'Manage your details',
          icon: 'person_outline',
          action: PatientTileAction(
            type: PatientTileActionType.route,
            route: '/patients/profile',
          ),
        ),
        PatientTileItem(
          id: 'appointment-history',
          title: 'Appointment History',
          subtitle: 'Past & upcoming visits',
          icon: 'history',
          action: PatientTileAction(
            type: PatientTileActionType.route,
            route: '/patients/appointment-history',
          ),
        ),
      ],
    ),
    PatientSection(
      id: 'membership',
      title: 'Membership',
      tiles: [
        PatientTileItem(
          id: 'membership',
          title: 'Membership',
          subtitle: 'Plans and benefits',
          icon: 'badge_outlined',
          action: PatientTileAction(
            type: PatientTileActionType.route,
            route: '/membership',
          ),
        ),
      ],
    ),
    PatientSection(
      id: 'care',
      title: 'Care',
      tiles: [
        PatientTileItem(
          id: 'portal',
          title: 'Patient portal',
          subtitle: 'Records and messages',
          icon: 'assignment_outlined',
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
      ],
    ),
    PatientSection(
      id: 'support',
      title: 'Support',
      tiles: [
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
    ),
  ],
);

const _demoUser = PatientUser(
  id: 1,
  email: 'jd@example.com',
  firstName: 'Jane',
  lastName: 'Doe',
  phone: '5550001111',
  tier: 2,
  tierTitle: 'Wellness Plus',
  leftDays: 30,
  servicesTaken: 0,
  complimentaryUsed: 0,
  membershipActive: true,
  canBookForFamily: false,
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
      AuthState? authState,
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
        if (authState != null)
          authControllerProvider.overrideWith((ref) {
            final repo = AuthRepository(
              ref.watch(apiClientProvider),
              ref.watch(authTokenStoreProvider),
            );
            return _FixedAuthController(repo, authState);
          }),
      ];
    }

    Future<void> openPatients(
      WidgetTester tester, {
      required GoRouter router,
      required List<String> opened,
      AuthState? authState,
    }) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides(opened: opened, authState: authState),
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump();
      router.go(AppRoutes.patients);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
    }

    Finder patientsScrollable() {
      return find.descendant(
        of: find.byType(PatientTabScreen),
        matching: find.byType(Scrollable),
      ).first;
    }

    testWidgets('shows redesign chrome and sectioned tiles', (tester) async {
      final router = createAppRouter();
      final opened = <String>[];
      await openPatients(tester, router: router, opened: opened);

      expect(find.text('Manage your care in one place'), findsOneWidget);
      expect(find.text('Log in'), findsOneWidget);
      expect(find.text('Patient resources'), findsNothing);
      expect(find.text('Soon'), findsNothing);
      expect(_patients.tiles, hasLength(8));

      final scrollable = patientsScrollable();
      final expectedLabels = [
        'MY ACCOUNT',
        'Profile',
        'Appointment History',
        'MEMBERSHIP',
        'Plans and benefits',
        'CARE',
        'Patient portal',
        'Book a service',
        'Shop',
        'SUPPORT',
        'FAQ',
        'Contact',
      ];
      for (final label in expectedLabels) {
        final finder = find.text(label);
        await tester.scrollUntilVisible(finder, 100, scrollable: scrollable);
        await tester.pump();
        expect(finder, findsWidgets);
      }

      await tester.scrollUntilVisible(
        find.text('Patient portal'),
        -200,
        scrollable: scrollable,
      );
      await tester.pump();
      await tester.tap(find.text('Patient portal'));
      await tester.pump();
      expect(opened, [_clinic.patientPortalUrl]);

      final shop = find.text('Shop');
      await tester.scrollUntilVisible(shop, 100, scrollable: scrollable);
      await tester.pump();
      await tester.tap(shop);
      await tester.pump();
      expect(opened, [
        _clinic.patientPortalUrl,
        _clinic.shopSupplementsUrl,
      ]);
    });

    testWidgets('Membership tile opens Membership screen', (tester) async {
      final router = createAppRouter();
      await openPatients(tester, router: router, opened: <String>[]);

      final membership = find.text('Plans and benefits');
      await tester.scrollUntilVisible(
        membership,
        80,
        scrollable: patientsScrollable(),
      );
      await tester.pump();
      await tester.tap(membership);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Membership Packages'), findsOneWidget);
      expect(find.text('Join Now'), findsWidgets);
    });

    testWidgets('logged-in header shows profile card and Log out',
        (tester) async {
      final router = createAppRouter();
      await openPatients(
        tester,
        router: router,
        opened: <String>[],
        authState: const AuthState(
          status: AuthStatus.authenticated,
          user: _demoUser,
        ),
      );

      expect(find.text('Jane Doe'), findsOneWidget);
      expect(find.text('Wellness Plus member'), findsOneWidget);
      expect(find.text('JD'), findsOneWidget);
      expect(find.text('Log out'), findsOneWidget);
      expect(find.text('Log in'), findsNothing);

      await tester.tap(find.text('Log out'));
      await tester.pump();
      expect(find.text('Log in'), findsOneWidget);
      expect(find.text('Log out'), findsNothing);
    });

    testWidgets('Book a service navigates to Explore Services', (tester) async {
      final router = createAppRouter();
      await openPatients(tester, router: router, opened: <String>[]);

      final book = find.text('Book a service');
      await tester.scrollUntilVisible(
        book,
        80,
        scrollable: patientsScrollable(),
      );
      await tester.pump();
      await tester.tap(book);
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
        scrollable: patientsScrollable(),
      );
      await tester.pump();
      await tester.tap(contactTile);
      await tester.pumpAndSettle();

      expect(find.text('Send Us A Message'), findsOneWidget);
    });

    testWidgets('Profile tile opens Profile screen', (tester) async {
      final router = createAppRouter();
      await openPatients(tester, router: router, opened: <String>[]);

      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      expect(find.text('Log in to view your profile'), findsOneWidget);
    });

    testWidgets('Appointment History tile opens history screen',
        (tester) async {
      final router = createAppRouter();
      await openPatients(tester, router: router, opened: <String>[]);

      await tester.tap(find.text('Appointment History'));
      await tester.pumpAndSettle();

      expect(find.text('Log in to see appointment history'), findsOneWidget);
    });
  });
}

class _FixedAuthController extends AuthController {
  _FixedAuthController(AuthRepository repository, AuthState initial)
      : super(repository) {
    state = initial;
  }

  @override
  Future<void> restore() async {}

  @override
  Future<void> logout() async {
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}
