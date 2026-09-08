import 'package:bethechange/core/network/api_result.dart';
import 'package:bethechange/core/widgets/appointment_cta_bar.dart';
import 'package:bethechange/features/appointment/domain/models/source_context.dart';
import 'package:bethechange/features/conditions/data/conditions_repository.dart';
import 'package:bethechange/features/conditions/domain/models/conditions_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ConditionsCatalog', () {
    test('parses all 8 conditions from bundled JSON', () async {
      final repository = ConditionsRepository();
      final result = await repository.getConditions();

      expect(result, isA<ApiSuccess<ConditionsCatalog>>());
      final catalog = (result as ApiSuccess<ConditionsCatalog>).data;

      expect(catalog.conditions, hasLength(8));
      expect(
        catalog.conditions.map((c) => c.id).toList(),
        [
          'diabetes',
          'obesity',
          'heart-disease',
          'chronic-fatigue',
          'chronic-pain',
          'hormone-imbalance',
          'detoxification',
          'concussion',
        ],
      );
    });

    test('diabetes and heart-disease are fully populated', () async {
      final catalog =
          ((await ConditionsRepository().getConditions())
                  as ApiSuccess<ConditionsCatalog>)
              .data;

      final diabetes = catalog.byId('diabetes')!;
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

      final heart = catalog.byId('heart-disease')!;
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
      final result =
          await ConditionsRepository().getConditionById('does-not-exist');
      expect(result, isA<ApiFailure>());
    });

    test('each condition builds a unique appointment SourceContext', () async {
      final catalog =
          ((await ConditionsRepository().getConditions())
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
