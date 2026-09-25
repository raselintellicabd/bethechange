import 'package:bethechange/features/points_offers/domain/models/point_offer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PointOfferCatalog', () {
    test('parses list payload', () {
      final catalog = PointOfferCatalog.fromJson({
        'ok': true,
        'points_balance': 120,
        'results': [
          {
            'id': 1,
            'service_id': 101,
            'service_slug': 'sauna',
            'service_name': 'Infrared Sauna',
            'category_name': 'Therapies',
            'duration_minutes': 30,
            'duration_display': '30 min',
            'slot_count': 1,
            'list_price': '65.00',
            'list_price_display': '\$65.00',
            'required_points': 50,
            'can_claim': true,
          },
        ],
      });

      expect(catalog.pointsBalance, 120);
      expect(catalog.results, hasLength(1));
      expect(catalog.results.first.requiredPoints, 50);
      expect(catalog.results.first.canClaim, isTrue);
    });
  });

  group('PointOfferClaimResult', () {
    test('parses claim response', () {
      final result = PointOfferClaimResult.fromJson({
        'ok': true,
        'id': 42,
        'status': 'pending',
        'points_spent': 50,
        'points_balance': 70,
        'message': 'Offer claimed.',
      });
      expect(result.id, 42);
      expect(result.pointsSpent, 50);
      expect(result.pointsBalance, 70);
    });
  });
}
