import 'package:bethechange/core/domain/models/content_block.dart';
import 'package:bethechange/core/domain/models/labeled_list_item.dart';
import 'package:bethechange/core/domain/models/recommended_book.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Shared content models', () {
    test('ContentBlock parses and rejects empty title', () {
      final block = ContentBlock.fromJson({
        'title': 'Our Integrative Approach',
        'body': 'Personalized care plan.',
        'imageUrl': 'https://example.com/image.jpg',
      });

      expect(block.title, 'Our Integrative Approach');
      expect(block.body, 'Personalized care plan.');
      expect(block.imageUrl, 'https://example.com/image.jpg');
      expect(
        () => ContentBlock.fromJson({'title': '  '}),
        throwsFormatException,
      );
    });

    test('LabeledListItem parses optional fields', () {
      final item = LabeledListItem.fromJson({
        'label': 'Fatigue',
        'description': 'Persistent low energy',
        'iconUrl': 'https://example.com/icon.png',
      });

      expect(item.label, 'Fatigue');
      expect(item.description, 'Persistent low energy');
      expect(item.iconUrl, 'https://example.com/icon.png');
      expect(
        () => LabeledListItem.fromJson({'label': ''}),
        throwsFormatException,
      );
    });

    test('RecommendedBook requires title and author', () {
      final book = RecommendedBook.fromJson({
        'title': 'The Diabetes Code',
        'author': 'Dr. Jason Fung',
        'coverUrl': 'https://example.com/cover.jpg',
        'purchaseUrl': 'https://example.com/buy',
      });

      expect(book.title, 'The Diabetes Code');
      expect(book.author, 'Dr. Jason Fung');
      expect(book.coverUrl, isNotNull);
      expect(book.purchaseUrl, isNotNull);
      expect(
        () => RecommendedBook.fromJson({'title': 'Only Title'}),
        throwsFormatException,
      );
    });
  });
}
