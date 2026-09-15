/// Matches Django `Appointment.ConsultationMode`.
enum ConsultationMode {
  virtual('virtual', 'Virtual'),
  inOffice('in_office', 'In-Office');

  const ConsultationMode(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static ConsultationMode? tryParse(String? raw) {
    final value = raw?.trim().toLowerCase() ?? '';
    for (final mode in ConsultationMode.values) {
      if (mode.apiValue == value) return mode;
    }
    return null;
  }
}
