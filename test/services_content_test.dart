import 'package:bethechange/core/network/api_result.dart';
import 'package:bethechange/core/widgets/appointment_cta_bar.dart';
import 'package:bethechange/features/appointment/domain/models/source_context.dart';
import 'package:bethechange/features/services/data/services_repository.dart';
import 'package:bethechange/features/services/domain/models/service.dart';
import 'package:bethechange/features/services/domain/models/services_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/mock_api_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ServicesCatalog', () {
    test('parses all 8 services from bundled JSON', () async {
      final result = await ServicesRepository(createMockApiClient()).getServices();

      expect(result, isA<ApiSuccess<ServicesCatalog>>());
      final catalog = (result as ApiSuccess<ServicesCatalog>).data;

      expect(catalog.title.toLowerCase(), 'our services');
      expect(catalog.services, hasLength(8));
      expect(
        catalog.services.map((s) => s.id).toList(),
        [
          'frequency-specific-microcurrent',
          'infrared-sauna-therapy',
          'hyperbaric-oxygen-therapy',
          'iv-nutritional-infusions',
          'liquivida-iv-therapy',
          'ozone-therapy',
          'reflexology',
          'ion-foot-detox',
        ],
      );
    });

    test('FSM service is fully populated', () async {
      final result = await ServicesRepository(createMockApiClient())
          .getServiceById('frequency-specific-microcurrent');

      expect(result, isA<ApiSuccess<Service>>());
      final fsm = (result as ApiSuccess<Service>).data;
      expect(fsm.heroHeading, 'frequency specific microcurrent');
      expect(fsm.headline, contains('Frequency Specific Microcurrent Therapy'));
      expect(fsm.contentHtml, isNotEmpty);
      expect(fsm.ctaLabel, 'Request An Appointment');
      expect(fsm.addressedConcerns, hasLength(18));
      expect(fsm.sections, hasLength(5));
      expect(fsm.sections.first.type, 'image_text');
      expect(fsm.sections.first.imageUrl, isNotEmpty);
      expect(fsm.sections[1].type, 'image_text');
      expect(fsm.sections[1].title, isEmpty);
      expect(fsm.sections[1].imageUrl, contains('f2_'));
      expect(fsm.sections[2].isAddressedConcerns, isTrue);
      expect(fsm.sections[2].items, hasLength(18));
      expect(fsm.sections[3].isFeaturedTherapies, isTrue);
      expect(fsm.sections[3].items, hasLength(4));
      expect(fsm.sections.last.isGettingStarted, isTrue);
      expect(fsm.reviews, isNotEmpty);
      expect(fsm.quote, 'Feel Good, Live Better!');
    });

    test('Infrared Sauna service is fully populated', () async {
      final result = await ServicesRepository(createMockApiClient())
          .getServiceById('infrared-sauna-therapy');

      expect(result, isA<ApiSuccess<Service>>());
      final sauna = (result as ApiSuccess<Service>).data;
      expect(sauna.heroHeading, 'Infrared sauna therapy');
      expect(sauna.headline, contains('Infrared Sauna Therapy can help'));
      expect(sauna.contentHtml, isNotEmpty);
      expect(sauna.ctaLabel, 'Request An Appointment');
      expect(sauna.addressedConcerns, hasLength(9));
      expect(sauna.benefits, hasLength(8));
      expect(sauna.sections, hasLength(9));
      expect(sauna.sections.first.title, contains('struggle'));
      expect(sauna.sections[1].type, 'image_text');
      expect(sauna.sections[2].title, contains('Benefits'));
      expect(sauna.sections[3].title, contains('Options'));
      expect(sauna.sections[3].items, hasLength(3));
      expect(
        sauna.sections[3].items.every(
          (item) => item.imageUrl == null || item.imageUrl!.isEmpty,
        ),
        isTrue,
      );
      expect(sauna.sections[4].title, contains('Chromotherapy'));
      expect(sauna.sections[4].items, hasLength(6));
      expect(sauna.sections[5].title, isEmpty);
      expect(sauna.sections[5].imageUrl, contains('Sauna_RedLight2_01'));
      expect(sauna.sections[6].title, isEmpty);
      expect(sauna.sections[6].imageUrl, contains('Sauna_RedLight2_02'));
      expect(sauna.sections[7].title, contains('Frequently Asked'));
      expect(sauna.sections[7].items, hasLength(5));
      expect(sauna.sections.last.title, 'What To Expect');
      expect(sauna.sections.last.items, hasLength(3));
      expect(sauna.reviews, isNotEmpty);
    });

    test('Hyperbaric Oxygen service is fully populated', () async {
      final result = await ServicesRepository(createMockApiClient())
          .getServiceById('hyperbaric-oxygen-therapy');

      expect(result, isA<ApiSuccess<Service>>());
      final hbot = (result as ApiSuccess<Service>).data;
      expect(hbot.heroHeading, 'hyperbaric oxygen therapy');
      expect(hbot.headline, contains('Hyperbaric Oxygen Therapy'));
      expect(hbot.contentHtml, isNotEmpty);
      expect(hbot.ctaLabel, 'Request An Appointment');
      expect(hbot.addressedConcerns, hasLength(9));
      expect(hbot.sections, hasLength(13));
      expect(hbot.sections.first.type, 'image_text');
      expect(hbot.sections[1].title, contains('Which Conditions'));
      expect(hbot.sections[1].items, hasLength(9));
      expect(hbot.sections[2].title, contains('Autism'));
      expect(hbot.sections.where((s) => s.isFeaturedTherapies), hasLength(1));
      expect(hbot.sections.last.isGettingStarted, isTrue);
      expect(hbot.reviews, isNotEmpty);
    });

    test('IV Nutritional Infusions service is fully populated', () async {
      final result = await ServicesRepository(createMockApiClient())
          .getServiceById('iv-nutritional-infusions');

      expect(result, isA<ApiSuccess<Service>>());
      final iv = (result as ApiSuccess<Service>).data;
      expect(iv.heroHeading, 'iv nutritional infusions');
      expect(iv.headline, contains('THERAPEUTIC'));
      expect(iv.summary, contains('in-house IV Therapy'));
      expect(iv.contentHtml, contains('in-house IV Therapy'));
      expect(iv.ctaLabel, 'Request An Appointment');
      expect(iv.sections, hasLength(4));
      expect(iv.sections[0].title, contains('THERAPEUTIC'));
      expect(iv.sections[0].items, hasLength(3));
      expect(iv.sections[1].title, contains('NUTRITIONAL'));
      expect(iv.sections[1].items, hasLength(9));
      expect(iv.sections[1].items.first.content, contains(r'$150'));
      expect(iv.sections[1].items.last.content, contains(r'$80'));
      expect(iv.sections.where((s) => s.isFeaturedTherapies), hasLength(1));
      expect(iv.sections.last.isGettingStarted, isTrue);
      expect(iv.reviews, isNotEmpty);
    });

    test('Liquivida IV Therapy service is fully populated', () async {
      final result = await ServicesRepository(createMockApiClient())
          .getServiceById('liquivida-iv-therapy');

      expect(result, isA<ApiSuccess<Service>>());
      final liquivida = (result as ApiSuccess<Service>).data;
      expect(liquivida.heroHeading, 'liquivida iv therapy');
      expect(liquivida.contentHtml, contains('LIQUIVIDA IV Therapy'));
      expect(liquivida.ctaLabel, 'Request An Appointment');
      expect(liquivida.heroImageUrl, contains('The-Liquilift'));
      expect(liquivida.sections, hasLength(3));
      expect(liquivida.sections.first.title, contains('LIQUIVIDA'));
      expect(liquivida.sections.first.items, hasLength(8));
      expect(liquivida.sections.first.items.first.title, 'FOUNTAIN OF YOUTH');
      expect(liquivida.sections.where((s) => s.isFeaturedTherapies), hasLength(1));
      expect(liquivida.sections.last.isGettingStarted, isTrue);
      expect(liquivida.reviews, isNotEmpty);
    });

    test('Reflexology service is fully populated', () async {
      final result = await ServicesRepository(createMockApiClient())
          .getServiceById('reflexology');

      expect(result, isA<ApiSuccess<Service>>());
      final reflexology = (result as ApiSuccess<Service>).data;
      expect(reflexology.heroHeading, 'reflexology');
      expect(reflexology.headline, 'What is Reflexology?');
      expect(reflexology.contentHtml, contains('manual therapy'));
      expect(reflexology.ctaLabel, 'Request An Appointment');
      expect(reflexology.benefits, hasLength(5));
      expect(reflexology.sections, hasLength(7));
      expect(reflexology.sections.first.title, 'What is Reflexology?');
      expect(reflexology.sections.first.imageUrl, isNotEmpty);
      expect(reflexology.sections[1].title, contains('How does reflexology'));
      expect(reflexology.sections[1].items, hasLength(4));
      expect(reflexology.sections[2].title, 'Scientific Studies');
      expect(reflexology.sections[2].items, hasLength(4));
      expect(reflexology.sections[3].title, contains('Who benefits'));
      expect(reflexology.sections[4].title, 'Contraindications');
      expect(reflexology.sections[4].items, hasLength(2));
      expect(
        reflexology.sections.where((s) => s.isFeaturedTherapies),
        hasLength(1),
      );
      expect(reflexology.sections.last.isGettingStarted, isTrue);
      expect(reflexology.reviews, isNotEmpty);
    });

    test('Ozone Therapy service is fully populated', () async {
      final result = await ServicesRepository(createMockApiClient())
          .getServiceById('ozone-therapy');

      expect(result, isA<ApiSuccess<Service>>());
      final ozone = (result as ApiSuccess<Service>).data;
      expect(ozone.heroHeading, 'ozone therapy');
      expect(ozone.headline, 'What is ozone?');
      expect(ozone.contentHtml, contains('EBOO'));
      expect(ozone.ctaLabel, 'Request An Appointment');
      expect(ozone.benefits, hasLength(6));
      expect(ozone.benefits.first.description, contains('Herniated discs'));
      expect(ozone.howItWorks?.imageUrl, contains('Ozone-Sauna'));
      expect(ozone.sections, hasLength(6));
      expect(ozone.sections.first.title, 'What is ozone?');
      expect(ozone.sections.first.imageUrl, isNotEmpty);
      expect(ozone.sections[1].title, 'How does it work?');
      expect(ozone.sections[1].imageUrl, isNotEmpty);
      expect(ozone.sections[2].title, contains('Who benefits'));
      expect(ozone.sections[2].items, hasLength(6));
      expect(ozone.sections[3].title, 'For more information');
      expect(
        ozone.sections.where((s) => s.isFeaturedTherapies),
        hasLength(1),
      );
      expect(ozone.sections.last.isGettingStarted, isTrue);
      expect(ozone.reviews, isNotEmpty);
    });

    test('Ion Foot Detox service is fully populated', () async {
      final result = await ServicesRepository(createMockApiClient())
          .getServiceById('ion-foot-detox');

      expect(result, isA<ApiSuccess<Service>>());
      final detox = (result as ApiSuccess<Service>).data;
      expect(detox.heroHeading, 'ion foot detox');
      expect(detox.headline, 'Why Ion Foot Detox?');
      expect(detox.contentHtml, contains('IonCleanse'));
      expect(detox.ctaLabel, 'Request An Appointment');
      expect(detox.benefits, hasLength(6));
      expect(detox.addressedConcerns, hasLength(4));
      expect(detox.sections, hasLength(6));
      expect(detox.sections.first.title, 'Why Ion Foot Detox?');
      expect(detox.sections.first.imageUrl, isNotEmpty);
      expect(detox.sections[1].title, contains('Benefits'));
      expect(detox.sections[1].items, hasLength(6));
      expect(detox.sections[2].title, contains('Illnesses'));
      expect(detox.sections[2].items, hasLength(4));
      expect(detox.sections[3].title, 'Resources');
      expect(detox.sections[3].items, hasLength(3));
      expect(
        detox.sections.where((s) => s.isFeaturedTherapies),
        hasLength(1),
      );
      expect(detox.sections.last.isGettingStarted, isTrue);
      expect(detox.reviews, isNotEmpty);
    });

    test('getServiceById returns failure for unknown id', () async {
      final result = await ServicesRepository(createMockApiClient())
          .getServiceById('missing');
      expect(result, isA<ApiFailure>());
    });

    test('each service builds a unique appointment SourceContext', () async {
      final catalog =
          ((await ServicesRepository(createMockApiClient()).getServices())
                  as ApiSuccess<ServicesCatalog>)
              .data;

      final contexts = catalog.services.map((service) {
        return SourceContext(
          type: SourceContextType.service,
          id: service.id,
          name: service.name,
        );
      }).toList();

      expect(contexts.map((c) => c.id).toSet(), hasLength(8));

      for (final context in contexts) {
        final parsed = SourceContext.tryParse(
          Uri.parse(AppointmentCtaBar.locationFor(context))
              .queryParameters['sourceContext'],
        );
        expect(parsed, context);
        expect(parsed?.type, SourceContextType.service);
      }
    });
  });

  group('Service API payload', () {
    test('fromJson accepts the list and detail field names', () {
      final catalog = ServicesCatalog.fromJson({
        'title': 'our services',
        'content': '',
        'services': [
          {
            'id': 'frequency-specific-microcurrent',
            'title': 'Frequency Specific Microcurrent Therapy',
            'description': 'Gentle electromagnetic pulses.',
            'heroImage': 'http://example.com/fsm.jpg',
            'slug': 'frequency-specific-microcurrent',
          },
        ],
      });

      expect(catalog.title, 'our services');
      expect(catalog.services.single.name, 'Frequency Specific Microcurrent Therapy');
      expect(catalog.services.single.heroImageUrl, contains('fsm.jpg'));
      expect(catalog.services.single.routeId, 'frequency-specific-microcurrent');

      final detail = Service.fromJson({
        'id': 'frequency-specific-microcurrent',
        'name': 'Frequency Specific Microcurrent',
        'title': 'Frequency Specific Microcurrent Therapy',
        'heroHeading': 'frequency specific microcurrent',
        'headline': 'What is Frequency Specific Microcurrent Therapy?',
        'summary': 'Short summary',
        'articleBody': 'Long article',
        'content_html': '<p>Intro HTML</p>',
        'heroImageUrl': 'http://example.com/hero.jpg',
        'slug': 'frequency-specific-microcurrent',
        'quote': 'Feel Good, Live Better!',
        'quoteBody': 'It’s easy to get started as a new patient…',
        'quoteHtml': '<p>It’s easy to get started as a new patient…</p>',
        'cta-label': 'Request An Appointment',
        'reviews': [
          {'name': 'Elle', 'comment': 'Great', 'star': 5},
        ],
        'sections': [
          {
            'type': 'image_text',
            'title': 'What is Frequency Specific Microcurrent Therapy?',
            'content': 'Longer explanation.',
            'content_html': '<p>Frequency Specific Microcurrent uses gentle pulses.</p>',
            'img-url': 'http://example.com/freq.jpg',
            'image-side': 'left',
          },
          {
            'type': 'cards',
            'title': 'What Does Frequency Specific Microcurrent Address?',
            'content_html':
                '<p><strong>REFERENCES:</strong></p><ul><li>McMakin</li></ul>',
            'items': [
              {'title': 'Neuropathic pain'},
              {'title': 'Muscle pain and soreness'},
            ],
          },
          {
            'type': 'cards',
            'title': 'Featured Therapies',
            'items': [
              {
                'title': 'Ion Foot Detox',
                'img-url': 'http://example.com/detox.jpg',
                'link-url': '/ion-foot-detox/',
              },
            ],
          },
          {
            'type': 'cards',
            'title': 'Feel Good, Live Better!',
            'items': [
              {'title': 'Request An Appointment'},
            ],
          },
        ],
      });

      expect(detail.name, 'Frequency Specific Microcurrent Therapy');
      expect(detail.heroHeading, 'frequency specific microcurrent');
      expect(detail.headline, contains('What is'));
      expect(detail.contentHtml, contains('<p>'));
      expect(detail.heroImageUrl, contains('hero.jpg'));
      expect(detail.ctaLabel, 'Request An Appointment');
      expect(detail.quoteBody, isNotEmpty);
      expect(detail.reviews, hasLength(1));
      expect(detail.sections, hasLength(4));
      expect(detail.sections.first.imageUrl, contains('freq.jpg'));
      expect(detail.sections[1].isAddressedConcerns, isTrue);
      expect(detail.sections[1].items.map((i) => i.title), [
        'Neuropathic pain',
        'Muscle pain and soreness',
      ]);
      expect(detail.sections.first.contentHtml, contains('<p>'));
      expect(detail.sections[2].isFeaturedTherapies, isTrue);
      expect(detail.sections[2].items.single.linkSlug, 'ion-foot-detox');
      expect(detail.sections.last.isGettingStarted, isTrue);
      expect(
        const ServiceSectionItem(linkUrl: '/membership/').linkSlug,
        isNull,
      );
    });
  });
}
