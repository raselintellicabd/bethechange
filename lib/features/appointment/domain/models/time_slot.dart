class TimeSlot {
  const TimeSlot({
    required this.id,
    required this.label,
    required this.dateTime,
  });

  final String id;
  final String label;
  final DateTime dateTime;

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      id: json['id'] as String,
      label: json['label'] as String,
      dateTime: DateTime.parse(json['dateTime'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'dateTime': dateTime.toIso8601String(),
      };

  @override
  bool operator ==(Object other) =>
      other is TimeSlot && other.id == id && other.dateTime == dateTime;

  @override
  int get hashCode => Object.hash(id, dateTime);
}
