import 'package:bethechange/core/network/api_result.dart';
import 'package:bethechange/core/widgets/appointment_cta_bar.dart';
import 'package:bethechange/features/appointment/domain/models/source_context.dart';
import 'package:bethechange/features/conditions/data/conditions_repository.dart';
import 'package:bethechange/features/blog/domain/models/blog_html.dart';
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

    test('content_html sections keep lists, headings, and skip website links', () {
      final detail = Condition.fromJson({
        'id': 'diabetes',
        'name': 'Diabetes',
        'summary': 'Short summary',
        'heroHeading': 'diabetes',
        'headline':
            'We Provide Natural Remedies and Alternative Treatments for Diabetes',
        'content_html': '<p>Intro from HTML.</p>',
        'cta-label': 'New Patient – Request An Appointment',
        'cta-url': '/appointments/?source=%2Fdiabetes%2F&patient=new',
        'sections': [
          {
            'type': 'image_text',
            'layout': 'symptoms',
            'title': 'Common Symptoms Caused by Diabetes',
            'content_html':
                '<ul><li>Fatigue</li><li>Increased Hunger</li></ul><ul><li>Irritability</li></ul>',
            'img-url': 'http://example.com/symptoms.jpg',
          },
          {
            'type': 'image_text',
            'title': 'What is medical weight loss?',
            'content_html':
                '<p>What is medical weight loss?</p><ul><li>Hypertension</li><p>Heart disease</p><p>Stroke</p></ul>',
          },
          {
            'type': 'cards',
            'layout': 'treat_dark',
            'title': 'Ways We Can Treat Diabetes',
            'items': [
              {
                'title': 'Naturopathic & Integrative Medicine',
                'content_html': '<p>Options might include nutritional supplements.</p>',
                'link-url': '/contact/',
                'link-label': 'Request Appointment',
              },
              {
                'title': 'Wellness Classes',
                'content_html': '<p>Blood sugar balancing class.</p>',
                'link-url': '/wellness-classes/',
                'link-label': 'Explore Classes',
              },
              {
                'title': 'Choose A Membership',
                'content_html': '<p><em>Optional</em> membership text.</p>',
                'link-url': '/membership/',
              },
            ],
          },
        ],
      });

      expect(detail.contentHtml, contains('<p>'));
      expect(detail.heroHeading, 'diabetes');
      expect(
        detail.headline,
        'We Provide Natural Remedies and Alternative Treatments for Diabetes',
      );
      expect(detail.ctaLabel, contains('Request An Appointment'));
      expect(detail.sections, hasLength(3));
      final symptoms = blogContentBlocks(
        contentHtml: detail.sections.first.contentHtml,
      );
      expect(
        symptoms.whereType<BlogBulletList>().expand((list) => list.items),
        ['Fatigue', 'Increased Hunger', 'Irritability'],
      );

      final weight = blogContentBlocks(
        contentHtml: detail.sections[1].contentHtml,
        subtitle: detail.sections[1].title,
      );
      expect(weight.whereType<BlogParagraph>(), isEmpty);
      expect(
        weight.whereType<BlogBulletList>().single.items,
        ['Hypertension', 'Heart disease', 'Stroke'],
      );

      expect(detail.sections.last.items[0].inAppContactPath, '/contact');
      expect(detail.sections.last.items[1].inAppContactPath, isNull);
      expect(detail.sections.last.items[2].inAppContactPath, isNull);
    });

    test('diabetes detail is fully populated from the item endpoint', () async {
      final repository = ConditionsRepository(createMockApiClient());
      final diabetesResult = await repository.getConditionById('diabetes');
      final heartResult = await repository.getConditionById('heart-disease');
      final concussionResult = await repository.getConditionById('concussion');

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
      expect(heart.heroHeading, 'heart disease specialist');
      expect(heart.headline, contains('major risk factor'));
      expect(heart.contentHtml, isNotEmpty);
      expect(heart.quote, 'Feel Good, Live Better!');
      expect(heart.quoteBody, isNotEmpty);
      expect(heart.ctaLabel, contains('Request An Appointment'));
      expect(heart.symptoms, isEmpty);
      expect(heart.integrativeApproach, isNull);
      expect(heart.benefits, isEmpty);
      expect(heart.contributingFactors, hasLength(3));
      expect(heart.treatmentMethods, hasLength(7));
      expect(heart.sections, hasLength(3));
      expect(heart.sections.first.isDefaultLayout, isTrue);
      expect(heart.sections[1].isFactors, isTrue);
      expect(heart.sections.last.isTreatDark, isTrue);
      expect(heart.sections.last.items.where((i) => i.isLabelOnly), hasLength(6));
      expect(
        heart.sections.last.items.singleWhere((i) => !i.isLabelOnly).title,
        'Medical Testing',
      );
      expect(heart.reviews, isNotEmpty);

      expect(concussionResult, isA<ApiSuccess<Condition>>());
      final concussion = (concussionResult as ApiSuccess<Condition>).data;
      expect(concussion.heroHeading, 'concussion specialist');
      expect(concussion.headline, contains('second concussion'));
      expect(concussion.contentHtml, isNotEmpty);
      expect(concussion.quote, 'Feel Good, Live Better!');
      expect(concussion.quoteBody, contains('suspect'));
      expect(concussion.symptoms, hasLength(9));
      expect(concussion.contributingFactors, isEmpty);
      expect(concussion.integrativeApproach, isNull);
      expect(concussion.benefits, isEmpty);
      expect(concussion.treatmentMethods, hasLength(2));
      expect(concussion.sections, hasLength(3));
      expect(concussion.sections.first.isDefaultLayout, isTrue);
      expect(concussion.sections[1].isSymptoms, isTrue);
      expect(concussion.sections.last.isTreatDark, isTrue);
      expect(concussion.sections.last.items, hasLength(2));
      expect(
        concussion.sections.last.items.first.linkLabel,
        'Request Appointment',
      );
      expect(concussion.reviews, isNotEmpty);

      final fatigueResult =
          await repository.getConditionById('chronic-fatigue');
      expect(fatigueResult, isA<ApiSuccess<Condition>>());
      final fatigue = (fatigueResult as ApiSuccess<Condition>).data;
      expect(fatigue.heroHeading, 'chronic fatigue specialist');
      expect(fatigue.headline, contains('fibromyalgia'));
      expect(fatigue.contentHtml, isNotEmpty);
      expect(fatigue.quote, 'Feel Good, Live Better!');
      expect(fatigue.contributingFactors, isEmpty);
      expect(fatigue.integrativeApproach, isNull);
      expect(fatigue.benefits, isEmpty);
      expect(fatigue.treatmentMethods, hasLength(5));
      expect(fatigue.sections, hasLength(3));
      expect(fatigue.sections.where((s) => s.isSymptoms), hasLength(2));
      expect(fatigue.sections.last.isTreatDark, isTrue);
      expect(fatigue.sections.last.items, hasLength(5));
      expect(fatigue.sections.last.imageUrl, isNotEmpty);
      expect(fatigue.reviews, isNotEmpty);

      final obesityResult = await repository.getConditionById('obesity');
      expect(obesityResult, isA<ApiSuccess<Condition>>());
      final obesity = (obesityResult as ApiSuccess<Condition>).data;
      expect(obesity.heroHeading, 'obesity specialist');
      expect(obesity.headline, contains('lose weight'));
      expect(obesity.contentHtml, isNotEmpty);
      expect(obesity.symptoms, isEmpty);
      expect(obesity.integrativeApproach, isNull);
      expect(obesity.treatmentMethods, hasLength(6));
      expect(obesity.sections, hasLength(4));
      expect(obesity.sections.first.isDefaultLayout, isTrue);
      expect(obesity.sections[1].isTreatDark, isTrue);
      expect(obesity.sections[1].items, hasLength(6));
      expect(obesity.sections[2].type, 'text');
      expect(obesity.sections.last.isGettingStarted, isTrue);
      expect(obesity.sections.last.items, hasLength(3));
      expect(obesity.reviews, isNotEmpty);

      final painResult = await repository.getConditionById('chronic-pain');
      expect(painResult, isA<ApiSuccess<Condition>>());
      final pain = (painResult as ApiSuccess<Condition>).data;
      expect(pain.heroHeading, 'chronic pain specialist');
      expect(pain.headline, contains('less pain'));
      expect(pain.contentHtml, isNotEmpty);
      expect(pain.quote, 'Feel Good, Live Better!');
      expect(pain.quoteBody, contains('Frequency Specific Microcurrent'));
      expect(pain.symptoms, isEmpty);
      expect(pain.integrativeApproach, isNull);
      expect(pain.treatmentMethods, hasLength(13));
      expect(pain.sections, hasLength(3));
      expect(pain.sections.first.isDefaultLayout, isTrue);
      expect(pain.sections[1].isTreatDark, isTrue);
      expect(pain.sections[1].items, hasLength(13));
      expect(pain.sections.last.type, 'text');
      expect(pain.reviews, isNotEmpty);

      final toxinsResult = await repository.getConditionById('toxins');
      expect(toxinsResult, isA<ApiSuccess<Condition>>());
      final toxins = (toxinsResult as ApiSuccess<Condition>).data;
      expect(toxins.heroHeading, 'toxins specialist');
      expect(toxins.headline, contains('smoke inhalation'));
      expect(toxins.contentHtml, isNotEmpty);
      expect(toxins.quote, 'Feel Good, Live Better!');
      expect(toxins.quoteBody, contains('IonCleanse'));
      expect(toxins.symptoms, hasLength(6));
      expect(toxins.benefits, hasLength(8));
      expect(toxins.integrativeApproach, isNull);
      expect(toxins.treatmentMethods, hasLength(1));
      expect(toxins.sections, hasLength(4));
      expect(toxins.sections.first.isSymptoms, isTrue);
      expect(toxins.sections[2].isTreatDark, isTrue);
      expect(toxins.sections[2].items.single.title, 'IonCleanse Detoxification');
      expect(toxins.sections.last.items, hasLength(8));
      expect(toxins.reviews, isNotEmpty);
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
