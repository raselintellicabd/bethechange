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
      };
}

class ContactSubmissionResult {
  const ContactSubmissionResult({
    required this.id,
    this.status = 'received',
    this.name = '',
    this.email = '',
    this.phone = '',
    this.message = '',
  });

  final String id;
  final String status;
  final String name;
  final String email;
  final String phone;
  final String message;

  String get statusLabel {
    final value = status.trim().toLowerCase();
    if (value.isEmpty || value == 'received') return 'Received';
    return status.trim();
  }

  ContactSubmissionResult confirmedWith(ContactRequest request) {
    return ContactSubmissionResult(
      id: id,
      status: status,
      name: request.name,
      email: request.email,
      phone: request.phone,
      message: request.message,
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
