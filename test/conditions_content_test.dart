import 'package:bethechange/core/network/api_result.dart';
import 'package:bethechange/core/widgets/appointment_cta_bar.dart';
import 'package:bethechange/features/appointment/domain/models/source_context.dart';
import 'package:bethechange/features/conditions/data/conditions_repository.dart';
import 'package:bethechange/features/conditions/domain/models/condition.dart';
import 'package:bethechange/features/conditions/domain/models/conditions_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/mock_api_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ConditionsCatalog', () {
    test('parses the conditions list payload and loads detail by slug', () async {
      final repository = ConditionsRepository(createMockApiClient());
      final result = await repository.getConditions();

      expect(result, isA<ApiSuccess<ConditionsCatalog>>());
      final catalog = (result as ApiSuccess<ConditionsCatalog>).data;

      expect(catalog.title.toLowerCase(), 'conditions we treat');
      expect(catalog.conditions, hasLength(8));
      expect(
        catalog.conditions.map((c) => c.routeId).toList(),
        [
          'diabetes',
          'obesity',
          'heart-disease',
          'chronic-fatigue',
          'chronic-pain',
          'hormone-imbalance',
          'toxins',
          'concussion',
        ],
      );
      expect(catalog.conditions.first.name, 'Diabetes');
      expect(catalog.conditions.first.summary, isNotEmpty);
    });

    test('fromJson accepts the list and detail field names', () {
      final catalog = ConditionsCatalog.fromJson({
        'title': 'conditions we treat',
        'content': '',
        'conditions': [
          {
            'id': 'diabetes',
            'title': 'Diabetes',
            'description': 'Balance blood sugar.',
            'heroImage': 'http://example.com/diabetes.jpg',
            'slug': 'diabetes',
          },
        ],
      });

      expect(catalog.conditions.single.name, 'Diabetes');
      expect(catalog.conditions.single.heroImageUrl, contains('diabetes.jpg'));
      expect(catalog.conditions.single.routeId, 'diabetes');

      final detail = Condition.fromJson({
        'id': 'diabetes',
        'name': 'Diabetes',
        'summary': 'Short summary',
        'articleBody': 'Long article',
        'heroImageUrl': 'http://example.com/hero.jpg',
        'slug': 'diabetes',
        'quote': 'Feel Good, Live Better!',
        'cta-label': 'New Patient – Request An Appointment',
        'symptoms': [
          {'label': 'Fatigue'},
        ],
        'treatmentMethods': [
          {'label': 'Naturopathic Medicine'},
        ],
        'sections': [
          {
            'layout': 'now_control',
            'img-url': 'http://example.com/types.jpg',
          },
          {
            'layout': 'symptoms',
            'img-url': 'http://example.com/symptoms.jpg',
          },
          {
            'layout': 'treat_dark',
            'items': [
              {'img-url': 'http://example.com/treat.jpg'},
            ],
          },
        ],
        'reviews': [
          {
            'name': 'Elle',
            'date': '2025-02-25',
            'star': 5,
            'comment': 'Great care.',
          },
        ],
      });

      expect(detail.ctaLabel, contains('Request An Appointment'));
      expect(detail.reviews.single.reviewerName, 'Elle');
      expect(detail.symptoms.single.label, 'Fatigue');
      expect(
        detail.overviewImageUrl,
        'http://example.com/types.jpg',
      );
      expect(detail.symptomsImageUrl, 'http://example.com/symptoms.jpg');
      expect(detail.treatmentMethods.single.iconUrl, 'http://example.com/treat.jpg');
    });

    test('diabetes detail is fully populated from the item endpoint', () async {
      final repository = ConditionsRepository(createMockApiClient());
      final diabetesResult = await repository.getConditionById('diabetes');
      final heartResult = await repository.getConditionById('heart-disease');

      expect(diabetesResult, isA<ApiSuccess<Condition>>());
      final diabetes = (diabetesResult as ApiSuccess<Condition>).data;
      expect(diabetes.symptoms, isNotEmpty);
      expect(diabetes.contributingFactors, isNotEmpty);
      expect(diabetes.integrativeApproach, isNotNull);
      expect(diabetes.benefits, isNotEmpty);
      expect(diabetes.treatmentMethods, isNotEmpty);
      expect(diabetes.recommendedBooks, hasLength(2));
      expect(
        diabetes.integrativeApproachTitle,
        'Our Integrative Approach to Diabetes',
      );

      expect(heartResult, isA<ApiSuccess<Condition>>());
      final heart = (heartResult as ApiSuccess<Condition>).data;
      expect(heart.symptoms, isNotEmpty);
      expect(heart.contributingFactors, isNotEmpty);
      expect(heart.integrativeApproach, isNotNull);
      expect(heart.treatmentMethods, isNotEmpty);
      expect(
        heart.benefitsTitle,
        'Benefits of Integrative Medicine for Heart Disease',
      );
    });

    test('getConditionById returns failure for unknown id', () async {
      final result = await ConditionsRepository(createMockApiClient())
          .getConditionById('does-not-exist');
      expect(result, isA<ApiFailure>());
    });

    test('each condition builds a unique appointment SourceContext', () async {
      final catalog =
          ((await ConditionsRepository(createMockApiClient()).getConditions())
                  as ApiSuccess<ConditionsCatalog>)
              .data;

      final contexts = catalog.conditions.map((condition) {
        return SourceContext(
          type: SourceContextType.condition,
          id: condition.id,
          name: condition.name,
        );
      }).toList();

      expect(contexts.map((c) => c.id).toSet(), hasLength(8));

      for (final context in contexts) {
        final parsed = SourceContext.tryParse(
          Uri.parse(AppointmentCtaBar.locationFor(context))
              .queryParameters['sourceContext'],
        );
        expect(parsed, context);
      }
    });
  });
}
