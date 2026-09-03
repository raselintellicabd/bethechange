import 'dart:convert';

/// Origin of an appointment request. Required to open `/appointment`.
enum SourceContextType {
  condition,
  service,
  blog,
  other;

  static SourceContextType? tryParse(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final type in SourceContextType.values) {
      if (type.name == value) return type;
    }
    return null;
  }
}

/// Context carried into the Appointment flow from a content screen.
///
/// Encoded into the `sourceContext` query param — there is no other valid
/// entry point to `/appointment`.
class SourceContext {
  const SourceContext({
    required this.type,
    required this.id,
    required this.name,
  });

  final SourceContextType type;

  /// Stable content id (e.g. `diabetes`, `fsm`). May be empty for [SourceContextType.other].
  final String id;

  /// Human-readable label shown in the appointment header.
  final String name;

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'id': id,
        'name': name,
      };

  factory SourceContext.fromJson(Map<String, dynamic> json) {
    final type = SourceContextType.tryParse(json['type'] as String?);
    final id = json['id'] as String? ?? '';
    final name = (json['name'] as String?)?.trim() ?? '';

    if (type == null) {
      throw FormatException('Invalid SourceContext type: ${json['type']}');
    }
    if (name.isEmpty) {
      throw const FormatException('SourceContext name is required.');
    }
    if (type != SourceContextType.other && id.trim().isEmpty) {
      throw FormatException('SourceContext id is required for type ${type.name}.');
    }

    return SourceContext(type: type, id: id.trim(), name: name);
  }

  /// Compact JSON payload for query params.
  String encode() => jsonEncode(toJson());

  /// Returns null when [raw] is missing or invalid (router should redirect).
  static SourceContext? tryParse(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return SourceContext.fromJson(decoded);
    } on FormatException {
      return null;
    } on Object {
      return null;
    }
  }

  @override
  bool operator ==(Object other) {
    return other is SourceContext &&
        other.type == type &&
        other.id == id &&
        other.name == name;
  }

  @override
  int get hashCode => Object.hash(type, id, name);

  @override
  String toString() => 'SourceContext(type: ${type.name}, id: $id, name: $name)';
}
