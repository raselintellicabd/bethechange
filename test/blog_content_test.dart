import 'dart:convert';

import 'package:bethechange/core/network/api_result.dart';
import 'package:bethechange/core/utils/asset_loader.dart';
import 'package:bethechange/features/blog/data/blog_repository.dart';
import 'package:bethechange/features/blog/domain/models/blog_article.dart';
import 'package:bethechange/features/blog/domain/models/blog_catalog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BlogCatalog', () {
    test('parses bundled blog.json with 5+ articles', () async {
      final repository = BlogRepository();
      final result = await repository.getArticles();

      expect(result, isA<ApiSuccess<BlogCatalog>>());
      final catalog = (result as ApiSuccess<BlogCatalog>).data;

      expect(catalog.articles.length, greaterThanOrEqualTo(5));
      expect(
        catalog.articles.map((a) => a.id).toList(),
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
        expect(article.body, isNotEmpty);
        expect(article.imageUrl, isNotEmpty);
      }
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
      expect(article.body, contains('Paragraph two'));
    });

    test('getArticleById returns failure for unknown id', () async {
      final result =
          await BlogRepository().getArticleById('does-not-exist');
      expect(result, isA<ApiFailure>());
    });

    test('repository surfaces asset load failures', () async {
      final repository = BlogRepository(
        assetLoader: AssetLoader(bundle: _MissingAssetBundle()),
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
