import 'faq_item.dart';

class FaqCatalog {
  const FaqCatalog({required this.items});

  final List<FaqItem> items;

  factory FaqCatalog.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>? ?? const [])
        .map((item) => FaqItem.fromJson(item as Map<String, dynamic>))
        .toList();
    return FaqCatalog(items: items);
  }
}
