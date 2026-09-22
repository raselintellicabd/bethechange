class ContactRequest {
  const ContactRequest({
    required this.name,
    required this.email,
    required this.phone,
    required this.message,
    this.category = ContactCategory.services,
    this.doctorId,
    this.doctorName = '',
  });

  final String name;
  final String email;
  final String phone;
  final String message;
  final String category;
  final int? doctorId;
  final String doctorName;

  bool get isDoctors => category == ContactCategory.doctors;

  String get topicLabel {
    if (isDoctors) {
      final name = doctorName.trim();
      return name.isEmpty ? 'Doctors' : 'Doctors · $name';
    }
    return 'Services';
  }

  Map<String, dynamic> toJson() {
    final payload = <String, dynamic>{
      'name': name,
      'email': email,
      'phone': phone,
      'category': category,
      'message': message,
    };
    if (isDoctors && doctorId != null) {
      payload['doctor_id'] = doctorId;
    }
    return payload;
  }
}

abstract final class ContactCategory {
  static const String services = 'services';
  static const String doctors = 'doctors';
}

class ContactSubmissionResult {
  const ContactSubmissionResult({
    required this.id,
    this.status = 'received',
    this.name = '',
    this.email = '',
    this.phone = '',
    this.message = '',
    this.category = ContactCategory.services,
    this.doctorName = '',
  });

  final String id;
  final String status;
  final String name;
  final String email;
  final String phone;
  final String message;
  final String category;
  final String doctorName;

  String get statusLabel {
    final value = status.trim().toLowerCase();
    if (value.isEmpty || value == 'received') return 'Received';
    return status.trim();
  }

  String get topicLabel {
    if (category == ContactCategory.doctors) {
      final doctor = doctorName.trim();
      return doctor.isEmpty ? 'Doctors' : 'Doctors · $doctor';
    }
    return 'Services';
  }

  ContactSubmissionResult confirmedWith(ContactRequest request) {
    return ContactSubmissionResult(
      id: id,
      status: status,
      name: request.name,
      email: request.email,
      phone: request.phone,
      message: request.message,
      category: request.category,
      doctorName: request.doctorName,
    );
  }

  factory ContactSubmissionResult.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final idText = id == null ? '' : '$id'.trim();
    if (idText.isEmpty) {
      throw const FormatException('ContactSubmissionResult id is required.');
    }
    return ContactSubmissionResult(
      id: idText,
      status: _text(json['status'], fallback: 'received'),
    );
  }
}

String _text(Object? value, {String fallback = ''}) {
  if (value == null) return fallback;
  final text = '$value'.trim();
  return text.isEmpty ? fallback : text;
}
