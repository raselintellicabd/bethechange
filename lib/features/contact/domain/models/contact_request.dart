import 'package:intl/intl.dart';

class ContactRequest {
  const ContactRequest({
    required this.name,
    required this.email,
    required this.phone,
    required this.message,
  });

  final String name;
  final String email;
  final String phone;
  final String message;

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'phone': phone,
        'message': message,
        'is_read': false,
      };

  factory ContactRequest.fromJson(Map<String, dynamic> json) {
    return ContactRequest(
      name: _text(json, 'name'),
      email: _text(json, 'email'),
      phone: _text(json, 'phone'),
      message: _text(json, 'message'),
    );
  }
}

class ContactSubmissionResult {
  const ContactSubmissionResult({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.message,
    this.isRead = false,
    this.createdAt,
    this.conversation,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final String message;
  final bool isRead;
  final DateTime? createdAt;
  final int? conversation;

  String get receivedLabel {
    final created = createdAt;
    if (created == null) return '';
    return DateFormat.yMMMd().add_jm().format(created.toLocal());
  }

  String get statusLabel =>
      isRead ? 'Our team has read this' : 'Waiting for our team to reply';

  factory ContactSubmissionResult.fromJson(Map<String, dynamic> json) {
    final id = _id(json['id']);
    if (id.isEmpty) {
      throw const FormatException('ContactSubmissionResult id is required.');
    }
    return ContactSubmissionResult(
      id: id,
      name: _text(json, 'name'),
      email: _text(json, 'email'),
      phone: _text(json, 'phone'),
      message: _text(json, 'message'),
      isRead: json['is_read'] == true || json['isRead'] == true,
      createdAt: _date(json['created_at'] ?? json['createdAt']),
      conversation: _int(json['conversation']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'message': message,
        'is_read': isRead,
        if (createdAt != null) 'created_at': createdAt!.toUtc().toIso8601String(),
        if (conversation != null) 'conversation': conversation,
      };
}

String _text(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return '';
  return '$value'.trim();
}

String _id(Object? value) {
  if (value == null) return '';
  return '$value'.trim();
}

int? _int(Object? value) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value.trim());
  return null;
}

DateTime? _date(Object? value) {
  if (value is! String || value.trim().isEmpty) return null;
  return DateTime.tryParse(value.trim());
}
