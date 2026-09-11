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
      expect(fsm.howItWorks, isNotNull);
      expect(fsm.benefits, isNotEmpty);
      expect(fsm.addressedConcerns, isNotEmpty);
      expect(fsm.whatToExpect, isNotNull);
      expect(fsm.recommendedBooks, isNotEmpty);
      expect(fsm.benefitsTitle, contains('Frequency Specific Microcurrent'));
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
        'summary': 'Short summary',
        'articleBody': 'Long article',
        'heroImageUrl': 'http://example.com/hero.jpg',
        'slug': 'frequency-specific-microcurrent',
        'quote': 'Feel Good, Live Better!',
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
            'items': [
              {
                'content': 'Neuropathic pain\nMuscle pain and soreness',
                'content_html': '<ul><li>Neuropathic pain</li><li>Muscle pain and soreness</li></ul>',
              },
            ],
          },
          {
            'type': 'cards',
            'title': 'Featured Therapies',
            'items': [
              {
                'img-url': 'http://example.com/detox.jpg',
                'link-url': '/ion-foot-detox/',
              },
            ],
          },
        ],
      });

      expect(detail.name, 'Frequency Specific Microcurrent Therapy');
      expect(detail.heroImageUrl, contains('hero.jpg'));
      expect(detail.ctaLabel, 'Request An Appointment');
      expect(detail.sections, hasLength(3));
      expect(detail.sections.first.imageUrl, contains('freq.jpg'));
      expect(detail.sections[1].items.single.lines, [
        'Neuropathic pain',
        'Muscle pain and soreness',
      ]);
      expect(detail.sections.first.contentHtml, contains('<p>'));
      expect(detail.sections[1].items.single.contentHtml, contains('<ul>'));
      expect(detail.sections.last.items.single.linkSlug, 'ion-foot-detox');
      expect(
        const ServiceSectionItem(linkUrl: '/membership/').linkSlug,
        isNull,
      );
    });
  });
}
