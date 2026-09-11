import 'condition.dart';

class ConditionsCatalog {
  const ConditionsCatalog({
    required this.conditions,
    this.title = '',
    this.content = '',
  });

  final String title;
  final String content;
  final List<Condition> conditions;

  Condition? byId(String id) {
    for (final condition in conditions) {
      if (condition.id == id || condition.slug == id) return condition;
    }
    return null;
  }

  factory ConditionsCatalog.fromJson(Map<String, dynamic> json) {
    final conditions = (json['conditions'] as List<dynamic>? ?? const [])
        .map((item) => Condition.fromJson(item as Map<String, dynamic>))
        .toList();
    return ConditionsCatalog(
      title: (json['title'] as String?)?.trim() ?? '',
      content: (json['content'] as String?)?.trim() ?? '',
      conditions: conditions,
    );
  }
}
