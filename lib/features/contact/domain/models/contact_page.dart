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
  });

  final String eyebrow;
  final String heading;
  final String submitLabel;
  final List<ContactFormField> fields;

  ContactFormField? fieldNamed(String name) {
    for (final field in fields) {
      if (field.name == name) return field;
    }
    return null;
  }

  factory ContactFormContent.fromJson(Map<String, dynamic> json) {
    final rawFields = json['fields'];
    return ContactFormContent(
      eyebrow: _text(json['eyebrow'], fallback: 'Contact'),
      heading: _text(json['heading'], fallback: 'Send Us A Message'),
      submitLabel: _text(json['submitLabel'], fallback: 'Send Message'),
      fields: rawFields is List
          ? rawFields.whereType<Map>().map((item) {
              return ContactFormField.fromJson(_map(item));
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
  });

  final String name;
  final String label;
  final bool required;

  factory ContactFormField.fromJson(Map<String, dynamic> json) {
    return ContactFormField(
      name: _text(json['name']),
      label: _text(json['label']),
      required: json['required'] == true,
    );
  }
}

String _text(Object? value, {String fallback = ''}) {
  if (value == null) return fallback;
  final text = '$value'.trim();
  return text.isEmpty ? fallback : text;
}

Map<String, dynamic> _map(Map<dynamic, dynamic> value) {
  return value.map((key, item) => MapEntry('$key', item));
}
