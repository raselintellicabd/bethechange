import 'package:bethechange/core/network/api_result.dart';
import 'package:bethechange/features/about/domain/models/about_content_block.dart';
import 'package:bethechange/features/about/domain/models/doctor_profile.dart';
import 'package:bethechange/features/home/data/home_repository.dart';
import 'package:bethechange/features/home/domain/models/home_content.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/mock_api_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HomeContent', () {
    test('parses GET /api/v1/home payload into home sections', () async {
      final repository = HomeRepository(createMockApiClient());
      final result = await repository.getHomeContent();

      expect(result, isA<ApiSuccess<HomeContent>>());
      final content = (result as ApiSuccess<HomeContent>).data;

      expect(
        content.sections.map((section) => section.id).toList(),
        [
          'our-practice',
          'naturopathic-medicine',
          'integrative-medicine',
          'our-process',
        ],
      );
      expect(content.segmentLabel('our-practice', 'Our Practice'), 'Practice');
      expect(
        content.sectionImageUrl('our-practice'),
        contains('approach_'),
      );

      final practice = content.sections.first;
      expect(practice.blocks.any((block) => block.type == AboutBlockType.quote), isTrue);
      expect(
        practice.blocks.any((block) => block.title == 'Our Vision'),
        isTrue,
      );
      expect(
        practice.blocks.any((block) => block.title == 'Our Core Values'),
        isTrue,
      );

      final naturopathic = content.sections[1];
      expect(
        naturopathic.blocks.any(
          (block) =>
              block.type == AboutBlockType.bulletList &&
              block.items.contains('First do no harm'),
        ),
        isTrue,
      );

      expect(content.doctors, hasLength(2));
      expect(content.doctors.first.id, '1');
      expect(content.doctors.first.routeId, 'sultana-afrooz');
      expect(content.doctors.first.title, contains('Osteopathic Physician'));
      expect(content.doctors.first.imageUrl, isNotNull);

      expect(content.reviews, isNotEmpty);
      expect(content.reviews.first.reviewerName, 'Elle');
      expect(content.reviews.first.rating, 5);
      expect(content.reviews.first.imageUrl, isNotNull);
    });

    test('fromJson maps hyphenated doctor and review fields', () {
      final content = HomeContent.fromJson({
        'practice': {
          'img-url': 'https://example.com/practice.jpg',
          'title': 'about our practice',
          'content': 'Hello body.\n\nSecond paragraph.',
          'quote': '"Stay well."\n\n-Be The Change',
        },
        'naturopathic': {
          'title': 'naturopathic medicine',
          'content': 'What is Naturopathic Medicine?\n\nA paragraph.',
          'quote': '',
        },
        'Integrative-medicine': {
          'title': 'integrative medicine',
          'content': 'Integrative care.',
        },
        'our-process': {
          'title': 'Our Process',
          'content': 'STEP #1: CONSULTATION\n\nConsultation\nWe listen.',
          'quote': 'Feel Good, Live Better!',
        },
        'doctors': [
          {
            'id': 2,
            'img-url': 'https://example.com/doc.jpg',
            'name': 'Jessica Needle, N.D.',
            'designation': 'Naturopathic Doctor',
          },
        ],
        'reviews': [
          {
            'img-url': 'https://example.com/avatar.jpg',
            'name': 'Elle',
            'date': '2025-02-25',
            'star': 5,
            'comment': 'Great care.',
          },
        ],
        'our-vision': 'Vision text',
        'our-goal': 'Goal text',
        'core-values': 'Value A\nValue B',
      });

      expect(content.doctors.single.id, '2');
      expect(content.reviews.single.dateLabel, '2025-02-25');
      expect(content.reviews.single.imageUrl, 'https://example.com/avatar.jpg');

      final process = content.sections.singleWhere((s) => s.id == 'our-process');
      expect(
        process.blocks.any(
          (block) =>
              block.type == AboutBlockType.heading &&
              (block.title?.contains('STEP #1') ?? false),
        ),
        isTrue,
      );
      expect(
        process.blocks.any(
          (block) =>
              block.type == AboutBlockType.quote &&
              block.text == 'Feel Good, Live Better!',
        ),
        isTrue,
      );
    });

    test('slugFromName strips credentials', () {
      expect(
        DoctorProfile.slugFromName('Sultana Afrooz, D.O.'),
        'sultana-afrooz',
      );
    });
  });
}
