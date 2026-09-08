class ContactRequest {
  const ContactRequest({
    required this.name,
    required this.email,
    required this.phone,
    required this.subject,
    required this.message,
  });

  final String name;
  final String email;
  final String phone;
  final String subject;
  final String message;

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'phone': phone,
        'subject': subject,
        'message': message,
      };

  factory ContactRequest.fromJson(Map<String, dynamic> json) {
    return ContactRequest(
      name: (json['name'] as String?)?.trim() ?? '',
      email: (json['email'] as String?)?.trim() ?? '',
      phone: (json['phone'] as String?)?.trim() ?? '',
      subject: (json['subject'] as String?)?.trim() ?? '',
      message: (json['message'] as String?)?.trim() ?? '',
    );
  }
}

class ContactSubmissionResult {
  const ContactSubmissionResult({
    required this.id,
    this.status = 'received',
  });

  final String id;
  final String status;

  factory ContactSubmissionResult.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] as String?)?.trim() ?? '';
    if (id.isEmpty) {
      throw const FormatException('ContactSubmissionResult id is required.');
    }
    return ContactSubmissionResult(
      id: id,
      status: (json['status'] as String?)?.trim() ?? 'received',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'status': status,
      };
}
