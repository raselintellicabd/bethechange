class ContactPage {
  const ContactPage({
    required this.title,
    required this.content,
    required this.location,
    required this.form,
  });

  final String title;
  final String content;
  final ContactLocation location;
  final ContactFormContent form;

  factory ContactPage.fromJson(Map<String, dynamic> json) {
    final location = json['location'];
    final form = json['form'];
    return ContactPage(
      title: _text(json['title']),
      content: _text(json['content']),
      location: location is Map
          ? ContactLocation.fromJson(_map(location))
          : const ContactLocation(),
      form: form is Map
          ? ContactFormContent.fromJson(_map(form))
          : const ContactFormContent(),
    );
  }
}

class ContactLocation {
  const ContactLocation({
    this.title = 'Our Location',
    this.name = '',
    this.addressLine1 = '',
    this.addressLine2 = '',
    this.phone = '',
    this.phoneTel = '',
    this.fax = '',
    this.hours = '',
    this.mapsUrl = '',
    this.mapUrl = '',
  });

  final String title;
  final String name;
  final String addressLine1;
  final String addressLine2;
  final String phone;
  final String phoneTel;
  final String fax;
  final String hours;
  final String mapsUrl;
  final String mapUrl;

  String get directionsUrl {
    if (mapsUrl.trim().isNotEmpty) return mapsUrl.trim();
    if (mapUrl.trim().isNotEmpty) return mapUrl.trim();
    return '';
  }

  String get dialUrl {
    final tel = phoneTel.trim();
    if (tel.isNotEmpty) return tel;
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    return digits.isEmpty ? '' : 'tel:$digits';
  }

  factory ContactLocation.fromJson(Map<String, dynamic> json) {
    return ContactLocation(
      title: _text(json['title'], fallback: 'Our Location'),
      name: _text(json['name']),
      addressLine1: _text(json['addressLine1']),
      addressLine2: _text(json['addressLine2']),
      phone: _text(json['phone']),
      phoneTel: _text(json['phoneTel']),
      fax: _text(json['fax']),
      hours: _text(json['hours']),
      mapsUrl: _text(json['mapsUrl']),
      mapUrl: _text(json['mapUrl']),
    );
  }
}

class ContactFormContent {
  const ContactFormContent({
    this.eyebrow = 'Contact',
    this.heading = 'Send Us A Message',
    this.submitLabel = 'Send Message',
    this.fields = const [],
    this.doctors = const [],
  });

  final String eyebrow;
  final String heading;
  final String submitLabel;
  final List<ContactFormField> fields;
  final List<ContactDoctorOption> doctors;

  ContactFormField? fieldNamed(String name) {
    for (final field in fields) {
      if (field.name == name) return field;
    }
    return null;
  }

  /// Doctors for the dropdown: prefer field choices, else top-level list.
  List<ContactDoctorOption> doctorsForPicker() {
    final field = fieldNamed('doctor_id');
    if (field != null && field.choices.isNotEmpty) {
      return [
        for (final choice in field.choices)
          if (choice.id != null)
            ContactDoctorOption(
              id: choice.id!,
              name: choice.label,
              slug: choice.slug,
            ),
      ];
    }
    return doctors;
  }

  factory ContactFormContent.fromJson(Map<String, dynamic> json) {
    final rawFields = json['fields'];
    final rawDoctors = json['doctors'];
    return ContactFormContent(
      eyebrow: _text(json['eyebrow'], fallback: 'Contact'),
      heading: _text(json['heading'], fallback: 'Send Us A Message'),
      submitLabel: _text(json['submitLabel'], fallback: 'Send Message'),
      fields: rawFields is List
          ? rawFields.whereType<Map>().map((item) {
              return ContactFormField.fromJson(_map(item));
            }).toList()
          : const [],
      doctors: rawDoctors is List
          ? rawDoctors.whereType<Map>().map((item) {
              return ContactDoctorOption.fromJson(_map(item));
            }).toList()
          : const [],
    );
  }
}

class ContactFormField {
  const ContactFormField({
    required this.name,
    required this.label,
    this.required = false,
    this.showWhen = '',
    this.choices = const [],
  });

  final String name;
  final String label;
  final bool required;

  /// e.g. `category=doctors` — empty means always visible.
  final String showWhen;
  final List<ContactFieldChoice> choices;

  bool isVisibleFor({required String category}) {
    final rule = showWhen.trim();
    if (rule.isEmpty) return true;
    final parts = rule.split('=');
    if (parts.length != 2) return true;
    final key = parts[0].trim();
    final value = parts[1].trim();
    if (key == 'category') return category == value;
    return true;
  }

  factory ContactFormField.fromJson(Map<String, dynamic> json) {
    final rawChoices = json['choices'];
    return ContactFormField(
      name: _text(json['name']),
      label: _text(json['label']),
      required: json['required'] == true,
      showWhen: _text(json['show_when']),
      choices: rawChoices is List
          ? rawChoices.whereType<Map>().map((item) {
              return ContactFieldChoice.fromJson(_map(item));
            }).toList()
          : const [],
    );
  }
}

class ContactFieldChoice {
  const ContactFieldChoice({
    required this.value,
    required this.label,
    this.id,
    this.slug = '',
  });

  final String value;
  final String label;
  final int? id;
  final String slug;

  factory ContactFieldChoice.fromJson(Map<String, dynamic> json) {
    final id = _int(json['id']);
    final value = _text(json['value']);
    final name = _text(json['name']);
    final label = _text(json['label'], fallback: name);
    return ContactFieldChoice(
      value: value.isNotEmpty ? value : (id != null ? '$id' : ''),
      label: label.isNotEmpty ? label : value,
      id: id,
      slug: _text(json['slug']),
    );
  }
}

class ContactDoctorOption {
  const ContactDoctorOption({
    required this.id,
    required this.name,
    this.slug = '',
  });

  final int id;
  final String name;
  final String slug;

  factory ContactDoctorOption.fromJson(Map<String, dynamic> json) {
    final id = _int(json['id']);
    if (id == null) {
      throw const FormatException('ContactDoctorOption id is required.');
    }
    return ContactDoctorOption(
      id: id,
      name: _text(json['name']),
      slug: _text(json['slug']),
    );
  }
}

String _text(Object? value, {String fallback = ''}) {
  if (value == null) return fallback;
  final text = '$value'.trim();
  return text.isEmpty ? fallback : text;
}

int? _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim());
  return null;
}

Map<String, dynamic> _map(Map<dynamic, dynamic> value) {
  return value.map((key, item) => MapEntry('$key', item));
}
