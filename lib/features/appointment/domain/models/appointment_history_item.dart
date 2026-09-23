class AppointmentHistoryItem {
  const AppointmentHistoryItem({
    required this.id,
    required this.whenLabel,
    required this.service,
    required this.mode,
    required this.status,
    required this.amountLabel,
    this.statusKey,
  });

  final int id;
  final String whenLabel;
  final String service;
  final String mode;
  final String status;
  final String? statusKey;
  final String amountLabel;

  factory AppointmentHistoryItem.fromJson(Map<String, dynamic> json) {
    final amount = (json['amount'] as String?)?.trim();
    return AppointmentHistoryItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      whenLabel: (json['when'] as String?)?.trim() ?? '',
      service: (json['service'] as String?)?.trim() ?? '',
      mode: (json['mode'] as String?)?.trim() ?? '',
      status: (json['status'] as String?)?.trim() ?? '',
      statusKey: (json['status_key'] as String?)?.trim(),
      amountLabel: (amount == null || amount.isEmpty) ? '—' : amount,
    );
  }
}
