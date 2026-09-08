import 'condition.dart';

class ConditionsCatalog {
  const ConditionsCatalog({required this.conditions});

  final List<Condition> conditions;

  Condition? byId(String id) {
    for (final condition in conditions) {
      if (condition.id == id) return condition;
    }
    return null;
  }

  factory ConditionsCatalog.fromJson(Map<String, dynamic> json) {
    final conditions = (json['conditions'] as List<dynamic>? ?? const [])
        .map((item) => Condition.fromJson(item as Map<String, dynamic>))
        .toList();
    return ConditionsCatalog(conditions: conditions);
  }
}
