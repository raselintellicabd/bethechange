import 'package:bethechange/core/network/api_result.dart';
import 'package:bethechange/features/about/data/about_repository.dart';
import 'package:bethechange/features/about/data/doctor_repository.dart';
import 'package:bethechange/features/about/domain/models/about_content.dart';
import 'package:bethechange/features/about/domain/models/about_page.dart';
import 'package:bethechange/features/about/domain/models/doctor_profile.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/mock_api_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AboutContent', () {
    test('parses catalog from GET /api/v1/about/', () async {
      final repository = AboutRepository(createMockApiClient());
      final result = await repository.getAboutContent();

      expect(result, isA<ApiSuccess<AboutContent>>());
      final content = (result as ApiSuccess<AboutContent>).data;

      expect(content.title, 'About');
      expect(content.pages, hasLength(4));
      expect(
        content.pages.map((page) => page.slug).toList(),
        [
          'practice',
          'naturopathic-medicine',
          'integrative-medicine',
          'our-process',
        ],
      );
      expect(content.pageBySlug('practice')?.kind, 'practice');
      expect(content.pageBySlug('practice')?.summary, isNotEmpty);
    });

    test('loads practice, naturopathic, integrative, and process pages',
        () async {
      final repository = AboutRepository(createMockApiClient());

      final practice =
          (await repository.getAboutPage('practice') as ApiSuccess<AboutPage>)
              .data;
      expect(practice.isPractice, isTrue);
      expect(practice.values, hasLength(3));
      expect(practice.quote, isNotEmpty);
      expect(practice.doctors?.items, hasLength(2));

      final naturopathic = (await repository
              .getAboutPage('naturopathic-medicine') as ApiSuccess<AboutPage>)
          .data;
      expect(naturopathic.isNaturopathic, isTrue);
      expect(naturopathic.principles?.items, contains('First do no harm'));
      expect(naturopathic.videoEmbedUrl, contains('youtube'));

      final integrative = (await repository
              .getAboutPage('integrative-medicine') as ApiSuccess<AboutPage>)
          .data;
      expect(integrative.isIntegrative, isTrue);
      expect(integrative.resources, hasLength(2));

      final process = (await repository.getAboutPage('our-process')
              as ApiSuccess<AboutPage>)
          .data;
      expect(process.isProcess, isTrue);
      expect(process.steps, hasLength(6));
      expect(process.steps.first.layout, 'cards');
      expect(process.cta?.phone, contains('301'));
    });

    test('fromJson maps catalog pages', () {
      final content = AboutContent.fromJson({
        'title': 'About',
        'pages': [
          {
            'slug': 'practice',
            'title': 'Our Practice',
            'path': '/about/',
            'kind': 'practice',
            'summary': 'Root cause care.',
          },
        ],
      });

      expect(content.pages.single.slug, 'practice');
      expect(content.pages.single.kind, 'practice');
    });

    test('loads a doctor detail by slug', () async {
      final result = await DoctorRepository(createMockApiClient())
          .getDoctor('sultana-afrooz');

      expect(result, isA<ApiSuccess<DoctorProfile>>());
      final doctor = (result as ApiSuccess<DoctorProfile>).data;
      expect(doctor.routeId, 'sultana-afrooz');
      expect(doctor.name, 'Sultana Afrooz, D.O.');
      expect(doctor.title, contains('Osteopathic Physician'));
      expect(doctor.imageUrl, contains('sa_Z58pbgb.jpg'));
      expect(doctor.detailParagraphs, isNotEmpty);
    });

    test('fromJson splits the doctors API description', () {
      final doctor = DoctorProfile.fromJson({
        'id': 1,
        'name': 'Sultana Afrooz, D.O.',
        'designation':
            'Integrative Family Medicine Physician& Osteopathic Physician',
        'image_url': 'http://192.168.1.160:8000/media/about/sa.jpg',
        'slug': 'sultana-afrooz',
        'description': 'First paragraph.\nSecond paragraph.',
      });

      expect(doctor.id, '1');
      expect(doctor.routeId, 'sultana-afrooz');
      expect(doctor.detailParagraphs, ['First paragraph.', 'Second paragraph.']);
    });

    test('repository surfaces asset load failures', () async {
      final repository = AboutRepository(
        createMockApiClient(bundle: _MissingAssetBundle()),
      );

      final result = await repository.getAboutContent();
      expect(result, isA<ApiFailure<AboutContent>>());
    });
  });
}

class _MissingAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    throw FlutterError('Unable to load asset: $key');
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    throw FlutterError('Unable to load asset: $key');
  }
}
