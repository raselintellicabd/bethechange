import 'package:bethechange/core/network/api_result.dart';
import 'package:bethechange/core/utils/external_link_handler.dart';
import 'package:bethechange/features/membership/data/membership_repository.dart';
import 'package:bethechange/features/membership/domain/models/membership_catalog.dart';
import 'package:bethechange/features/membership/presentation/providers/membership_providers.dart';
import 'package:bethechange/features/membership/presentation/screens/membership_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher/url_launcher.dart';

import 'helpers/mock_api_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MembershipCatalog', () {
    test('parses plans, price, and display benefits', () {
      final catalog = MembershipCatalog.fromJson({
        'title': 'Membership Packages',
        'content': 'Required enrollment.',
        'plans': [
          {
            'id': 7,
            'title': 'Standard Wellness Membership',
            'description': 'Membership Price \$25/ 4 Months',
            'heroImage': 'https://example.com/standard.jpg',
            'benefits': [
              '1% off All Appointments',
              'This Package Includes:',
              'Membership Price \$25/ 4 Months',
            ],
            'button-label': 'Join Now',
            'button-url': 'https://buy.stripe.com/test',
          },
        ],
        'reviews': [
          {
            'name': 'Elle',
            'comment': 'Great care.',
            'star': 5,
            'date': '2025-02-25',
          },
        ],
      });

      expect(catalog.title, 'Membership Packages');
      expect(catalog.plans, hasLength(1));
      expect(catalog.reviews, hasLength(1));

      final plan = catalog.plans.first;
      expect(plan.title, 'Standard Wellness Membership');
      expect(plan.priceLabel, 'Membership Price \$25/ 4 Months');
      expect(plan.displayBenefits, ['1% off All Appointments']);
      expect(plan.buttonUrl, 'https://buy.stripe.com/test');
    });
  });

  group('MembershipRepository', () {
    test('loads catalog from mock API', () async {
      final repo = MembershipRepository(createMockApiClient());
      final result = await repo.getMemberships();
      expect(result, isA<ApiSuccess<MembershipCatalog>>());
      final catalog = (result as ApiSuccess<MembershipCatalog>).data;
      expect(catalog.plans, isNotEmpty);
      expect(catalog.title.toLowerCase(), contains('membership'));
    });
  });

  group('MembershipScreen', () {
    testWidgets('shows plans and opens Stripe join URL', (tester) async {
      final opened = <String>[];
      final catalog = MembershipCatalog.fromJson({
        'title': 'Membership Packages',
        'content': 'Required enrollment.',
        'plans': [
          {
            'id': 7,
            'title': 'Standard Wellness Membership',
            'description': 'Membership Price \$25/ 4 Months',
            'benefits': [
              '1% off All Appointments',
              'Membership Price \$25/ 4 Months',
            ],
            'button-label': 'Join Now',
            'button-url': 'https://buy.stripe.com/test-standard',
          },
        ],
        'reviews': const [],
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            membershipCatalogProvider.overrideWith((ref) async => catalog),
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
          child: const MaterialApp(home: MembershipScreen()),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Membership Packages'), findsOneWidget);
      expect(find.text('Standard Wellness Membership'), findsOneWidget);
      expect(find.text('Join Now'), findsOneWidget);

      await tester.tap(find.text('Join Now'));
      await tester.pump();

      expect(opened, ['https://buy.stripe.com/test-standard']);
    });
  });
}
