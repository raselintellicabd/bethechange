import 'dart:convert';

import 'package:bethechange/core/network/api_result.dart';
import 'package:bethechange/features/blog/data/blog_repository.dart';
import 'package:bethechange/features/blog/domain/models/blog_article.dart';
import 'package:bethechange/features/blog/domain/models/blog_catalog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/mock_api_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BlogCatalog', () {
    test('parses bundled blog.json with 5+ articles', () async {
      final repository = BlogRepository(createMockApiClient());
      final result = await repository.getArticles();

      expect(result, isA<ApiSuccess<BlogCatalog>>());
      final catalog = (result as ApiSuccess<BlogCatalog>).data;

      expect(catalog.title.toLowerCase(), 'be the change blog');
      expect(catalog.articles.length, greaterThanOrEqualTo(5));
      expect(
        catalog.articles.map((a) => a.routeId).toList(),
        containsAll([
          'what-is-frequency-specific-microcurrent-therapy',
          'what-is-hyperbaric-oxygen-therapy',
          'what-are-the-health-benefits-of-an-infrared-sauna',
          'how-is-an-ionic-foot-detox-supposed-to-work',
          'understanding-ozone-therapy',
        ]),
      );

      for (final article in catalog.articles) {
        expect(article.title, isNotEmpty);
        expect(article.subtitle, isNotEmpty);
        expect(article.imageUrl, isNotEmpty);
        expect(article.publishedAt, isNotEmpty);
        expect(article.body, isEmpty);
      }
    });

    test('loads article detail by slug', () async {
      final result = await BlogRepository(createMockApiClient()).getArticleById(
        'what-is-frequency-specific-microcurrent-therapy',
      );

      expect(result, isA<ApiSuccess<BlogArticle>>());
      final article = (result as ApiSuccess<BlogArticle>).data;
      expect(article.body, isNotEmpty);
      expect(article.author, isNotEmpty);
      expect(article.imageUrl, isNotEmpty);
    });

    test('fromJson maps article fields including optional author and date', () {
      const raw = '''
      {
        "articles": [
          {
            "id": "sample",
            "title": "Sample Title",
            "subtitle": "A short preview",
            "body": "Paragraph one.\\n\\nParagraph two.",
            "imageUrl": "https://example.com/image.jpg",
            "author": "Clinic Team",
            "date": "2024-08-01"
          }
        ]
      }
      ''';

      final catalog = BlogCatalog.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      final article = catalog.articles.single;

      expect(article.id, 'sample');
      expect(article.author, 'Clinic Team');
      expect(article.publishedAt, '2024-08-01');
      expect(article.publishedLabel, 'August 1, 2024');
      expect(article.body, contains('Paragraph two'));
    });

    test('fromJson accepts the list and detail field names', () {
      final catalog = BlogCatalog.fromJson({
        'title': 'be the change blog',
        'articles': [
          {
            'id': 'what-is-frequency-specific-microcurrent-therapy',
            'title': 'What Is Frequency-specific Microcurrent Therapy?',
            'subtitle': 'A short preview',
            'heroImage': 'http://example.com/fsm.jpg',
            'imageUrl': 'http://example.com/fsm.jpg',
            'publishedAt': '2025-02-24',
            'slug': 'what-is-frequency-specific-microcurrent-therapy',
          },
        ],
      });

      final listed = catalog.articles.single;
      expect(catalog.title, 'be the change blog');
      expect(listed.imageUrl, contains('fsm.jpg'));
      expect(listed.routeId, 'what-is-frequency-specific-microcurrent-therapy');
      expect(listed.body, isEmpty);

      final detail = BlogArticle.fromJson({
        'id': 'what-is-frequency-specific-microcurrent-therapy',
        'title': 'What Is Frequency-specific Microcurrent Therapy?',
        'subtitle': 'A short preview',
        'body': 'Full article body.',
        'heroImage': 'http://example.com/hero.jpg',
        'author': 'Be The Change Health & Wellness Center',
        'publishedAt': '2025-02-24',
        'slug': 'what-is-frequency-specific-microcurrent-therapy',
      });

      expect(detail.author, 'Be The Change Health & Wellness Center');
      expect(detail.body, 'Full article body.');
      expect(detail.publishedLabel, 'February 24, 2025');
    });

    test('getArticleById returns failure for unknown id', () async {
      final result = await BlogRepository(createMockApiClient())
          .getArticleById('does-not-exist');
      expect(result, isA<ApiFailure>());
    });

    test('repository surfaces asset load failures', () async {
      final repository = BlogRepository(
        createMockApiClient(bundle: _MissingAssetBundle()),
      );

      final result = await repository.getArticles();
      expect(result, isA<ApiFailure>());
    });
  });

  group('BlogArticle', () {
    test('requires id and title', () {
      expect(
        () => BlogArticle.fromJson({'id': '', 'title': 'x'}),
        throwsFormatException,
      );
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
