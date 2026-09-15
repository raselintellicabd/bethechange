import 'package:bethechange/core/network/api_result.dart';
import 'package:bethechange/features/about/domain/models/doctor_profile.dart';
import 'package:bethechange/features/home/data/home_repository.dart';
import 'package:bethechange/features/home/domain/models/home_content.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/mock_api_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HomeContent', () {
    test('parses GET /api/v1/home payload into website sections', () async {
      final repository = HomeRepository(createMockApiClient());
      final result = await repository.getHomeContent();

      expect(result, isA<ApiSuccess<HomeContent>>());
      final content = (result as ApiSuccess<HomeContent>).data;

      expect(content.hero.text, isNotEmpty);
      expect(content.hero.ctaLabel, 'New Patient Questions');
      expect(content.approach.eyebrow.toLowerCase(), contains('approach'));
      expect(content.conditions.items, hasLength(8));
      expect(content.conditions.items.first.slug, 'diabetes');
      expect(content.therapies.items, hasLength(4));
      expect(content.therapies.ctaLabel, contains('Services'));
      expect(content.doctors.items, hasLength(2));
      expect(content.doctors.items.first.routeId, 'sultana-afrooz');
      expect(content.newsletter.headline, contains('Ion'));
      expect(content.reviews, isNotEmpty);
      expect(content.reviews.first.reviewerName, 'Elle');
      expect(content.reviews.first.rating, 5);
    });

    test('fromJson maps camelCase home fields', () {
      final content = HomeContent.fromJson({
        'hero': {
          'text': 'Root cause care.',
          'imageUrl': 'https://example.com/hero.jpg',
          'ctaLabel': 'FAQ',
          'ctaUrl': '/faq/',
        },
        'approach': {
          'eyebrow': 'our approach',
          'headline': 'We focus on the root cause.',
          'content': 'Holistic care.',
          'buttonLabel': 'Our Approach',
          'buttonUrl': '/about/',
        },
        'conditions': {
          'title': 'conditions we treat',
          'items': [
            {
              'slug': 'diabetes',
              'title': 'Diabetes',
              'summary': 'Support metabolism.',
              'linkUrl': '/diabetes/',
            },
          ],
        },
        'therapies': {
          'title': 'Featured Therapies',
          'ctaLabel': 'View services',
          'ctaUrl': '/services/',
          'items': [
            {
              'slug': 'ion-foot-detox',
              'title': 'Ion Foot Detox',
              'linkUrl': '/ion-foot-detox/',
            },
          ],
        },
        'doctors': {
          'title': 'Meet Our Doctors',
          'intro': 'Our team.',
          'items': [
            {
              'id': 2,
              'name': 'Jessica Needle, N.D.',
              'designation': 'Naturopathic Doctor',
              'slug': 'jessica-needle',
              'imageUrl': 'https://example.com/doc.jpg',
            },
          ],
        },
        'newsletter': {
          'headline': 'Free session',
          'subtext': 'Join our list.',
          'buttonLabel': '',
          'buttonUrl': '',
        },
        'reviews': [
          {
            'img-url': 'https://example.com/avatar.jpg',
            'name': 'Elle',
            'date': '2025-02-25',
            'star': 5,
            'comment': 'Great care.',
          },
        ],
      });

      expect(content.hero.ctaUrl, '/faq/');
      expect(content.conditions.items.single.title, 'Diabetes');
      expect(content.doctors.items.single.id, '2');
      expect(content.newsletter.buttonLabel, isNull);
      expect(content.reviews.single.imageUrl, 'https://example.com/avatar.jpg');
    });

    test('slugFromName strips credentials', () {
      expect(
        DoctorProfile.slugFromName('Sultana Afrooz, D.O.'),
        'sultana-afrooz',
      );
    });
  });
}
