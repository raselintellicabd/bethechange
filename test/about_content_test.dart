import 'dart:convert';

import 'package:bethechange/core/network/api_result.dart';
import 'package:bethechange/features/about/data/about_repository.dart';
import 'package:bethechange/features/about/domain/models/about_content.dart';
import 'package:bethechange/features/about/domain/models/doctor_profile.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/mock_api_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AboutContent', () {
    test('parses bundled about.json with 4 sections, doctors, and reviews',
        () async {
      final repository = AboutRepository(createMockApiClient());
      final result = await repository.getAboutContent();

      expect(result, isA<ApiSuccess<AboutContent>>());
      final content = (result as ApiSuccess<AboutContent>).data;

      expect(content.sections, hasLength(4));
      expect(
        content.sections.map((section) => section.id).toList(),
        [
          'our-practice',
          'naturopathic-medicine',
          'integrative-medicine',
          'our-process',
        ],
      );
      expect(content.doctors, hasLength(2));
      expect(content.doctors.first.name, contains('Sultana Afrooz'));
      expect(content.doctors.first.imageUrl, isNotNull);
      expect(content.doctors.first.detailParagraphs, isNotEmpty);
      expect(content.doctorById('jessica-needle')?.title, 'Naturopathic Doctor');
      expect(content.reviews, isNotEmpty);
      expect(content.reviewCount, 37);

      for (final section in content.sections) {
        expect(section.blocks, isNotEmpty);
        expect(section.title, isNotEmpty);
      }
    });

    test('doctorForRoute maps a numeric home id onto the about bio', () {
      final about = AboutContent.fromJson({
        'sections': [],
        'doctors': [
          {
            'id': 'sultana-afrooz',
            'name': 'Sultana Afrooz, D.O.',
            'title': 'Osteopathic Physician',
            'detailParagraphs': ['Bio'],
          },
        ],
        'reviews': [],
      });
      final homeDoctor = DoctorProfile.fromJson({
        'id': 1,
        'name': 'Sultana Afrooz, D.O.',
        'designation': 'Integrative Family Medicine Physician',
      });

      final resolved = about.doctorForRoute('1', homeDoctor: homeDoctor);

      expect(resolved?.id, 'sultana-afrooz');
      expect(resolved?.detailParagraphs, ['Bio']);
    });

    test('fromJson maps nested blocks', () {
      const raw = '''
      {
        "sections": [
          {
            "id": "our-practice",
            "title": "Our Practice",
            "showDoctors": true,
            "showReviews": false,
            "blocks": [
              { "type": "heading", "title": "Hello" },
              { "type": "bulletList", "title": "Values", "items": ["A", "B"] }
            ]
          }
        ],
        "doctors": [],
        "reviews": []
      }
      ''';

      final content = AboutContent.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );

      expect(content.sections.single.blocks, hasLength(2));
      expect(content.sections.single.showDoctors, isTrue);
      expect(content.sections.single.showReviews, isFalse);
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
