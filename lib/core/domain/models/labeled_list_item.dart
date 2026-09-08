/// A labeled row item (symptom, factor, treatment step, etc.).
class LabeledListItem {
  const LabeledListItem({
    required this.label,
    this.description,
    this.iconUrl,
  });

  final String label;
  final String? description;
  final String? iconUrl;

  factory LabeledListItem.fromJson(Map<String, dynamic> json) {
    final label = (json['label'] as String?)?.trim() ?? '';
    if (label.isEmpty) {
      throw const FormatException('LabeledListItem label is required.');
    }

    return LabeledListItem(
      label: label,
      description: json['description'] as String?,
      iconUrl: json['iconUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'label': label,
        if (description != null) 'description': description,
        if (iconUrl != null) 'iconUrl': iconUrl,
      };
}
