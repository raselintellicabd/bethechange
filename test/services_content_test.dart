import 'package:bethechange/core/network/api_result.dart';
import 'package:bethechange/core/widgets/appointment_cta_bar.dart';
import 'package:bethechange/features/appointment/domain/models/source_context.dart';
import 'package:bethechange/features/services/data/services_repository.dart';
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
      final catalog =
          ((await ServicesRepository(createMockApiClient()).getServices())
                  as ApiSuccess<ServicesCatalog>)
              .data;

      final fsm = catalog.byId('frequency-specific-microcurrent')!;
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
}
