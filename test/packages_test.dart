import 'package:bethechange/features/appointment/domain/models/availability_window.dart';
import 'package:bethechange/features/packages/domain/models/package_bundle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PackageCatalog', () {
    test('parses list payload', () {
      final catalog = PackageCatalog.fromJson({
        'ok': true,
        'viewer_tier': 1,
        'package_window_days': 180,
        'results': [
          {
            'id': 1,
            'name': 'Wellness Reset',
            'slug': 'wellness-reset',
            'description': 'Two services',
            'items': [
              {
                'item_id': 11,
                'service_id': 101,
                'service_slug': 'sauna',
                'service_name': 'Infrared Sauna',
                'duration_minutes': 30,
                'slot_count': 1,
                'price_display': '\$65',
                'duration_display': '30 min',
              },
            ],
            'quote': {
              'list_amount_cents': 18500,
              'discount_cents': 1850,
              'payable_cents': 16650,
              'discount_percent': 10,
              'pricing_note': '10% off',
              'list_amount_display': '\$185',
              'discount_display': '\$18.50',
              'payable_display': '\$166.50',
            },
          },
        ],
      });

      expect(catalog.packageWindowDays, 180);
      expect(catalog.results, hasLength(1));
      expect(catalog.results.first.slug, 'wellness-reset');
      expect(catalog.results.first.items.first.itemId, 11);
      expect(catalog.results.first.quote.payableCents, 16650);
    });
  });

  group('PackageSelection', () {
    test('serializes date and time', () {
      final selection = PackageSelection(
        itemId: 11,
        date: DateTime(2026, 10, 5),
        timeMinutes: 600,
      );
      expect(selection.toJson(), {
        'item_id': 11,
        'date': '2026-10-05',
        'time_minutes': 600,
      });
    });
  });

  group('AvailabilityWindow package horizon', () {
    test('uses window_days 180 for package calendars', () {
      final today = DateTime(2026, 9, 25);
      final days = <String, List<Map<String, dynamic>>>{};
      for (var i = 0; i < 180; i++) {
        final d = today.add(Duration(days: i));
        final key =
            '${d.year.toString().padLeft(4, '0')}-'
            '${d.month.toString().padLeft(2, '0')}-'
            '${d.day.toString().padLeft(2, '0')}';
        days[key] = [
          {'time_minutes': 600, 'state': 'available'},
        ];
      }

      final window = AvailabilityWindow.fromJson({
        'service': 'Infrared Sauna',
        'timezone': 'America/New_York',
        'today': '2026-09-25',
        'window_days': 180,
        'slot_minutes': 30,
        'days': days,
      });

      expect(window.windowDays, 180);
      expect(
        window.windowEnd,
        DateTime(2026, 9, 25).add(const Duration(days: 179)),
      );
      expect(window.bookableDates.length, greaterThan(100));
    });
  });

  group('different-day rule', () {
    test('PackageSelection date keys differ per service day', () {
      final a = PackageSelection(
        itemId: 1,
        date: DateTime(2026, 10, 1),
        timeMinutes: 600,
      );
      final b = PackageSelection(
        itemId: 2,
        date: DateTime(2026, 10, 2),
        timeMinutes: 630,
      );
      expect(a.dateKey == b.dateKey, isFalse);
    });
  });
}
