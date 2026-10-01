import 'package:bethechange/features/appointment/domain/book_online_topics.dart';
import 'package:bethechange/features/appointment/domain/models/book_online_catalog.dart';
import 'package:bethechange/features/appointment/domain/models/source_context.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('usesBookOnlinePicker', () {
    test('every service opens book-online (no slug allow/deny list)', () {
      for (final id in [
        'chemotherapy',
        'ion-foot-detox',
        'wellness-classes',
        'personalized-wellness-plans',
      ]) {
        expect(
          usesBookOnlinePicker(
            SourceContext(
              type: SourceContextType.service,
              id: id,
              name: id,
            ),
          ),
          isTrue,
          reason: id,
        );
      }
    });

    test('non-service sources skip the picker', () {
      expect(
        usesBookOnlinePicker(
          const SourceContext(
            type: SourceContextType.condition,
            id: 'diabetes',
            name: 'Diabetes',
          ),
        ),
        isFalse,
      );
    });
  });

  group('BookOnlineCatalog.categoryForCmsTopic', () {
    test('matches chemotherapy by category slug when topics are empty', () {
      // Live API shape for newly added chemotherapy offerings.
      final catalog = BookOnlineCatalog.fromJson(const {
        'categories': [
          {
            'slug': 'chemotherapy',
            'name': 'ChemoTherapy',
            'offerings': [
              {
                'slug': 'chemotherapy-1-session',
                'name': 'ChemoTherapy 1 session',
                'duration_minutes': 30,
                'price': 30.0,
                'appointment_topic': '',
                'category': 'chemotherapy',
              },
              {
                'slug': 'chemotherapy-3-sessions-1-hour-each',
                'name': 'ChemoTherapy 3 sessions (1 hour each)',
                'duration_minutes': 180,
                'price': 160.0,
                'appointment_topic': '',
                'category': 'chemotherapy',
              },
            ],
          },
        ],
      });

      final chemo = catalog.categoryForCmsTopic('chemotherapy');
      expect(chemo, isNotNull);
      expect(chemo!.name, 'ChemoTherapy');
      expect(chemo.offerings, hasLength(2));
    });
  });
}
