import 'models/book_online_offering.dart';
import 'models/source_context.dart';

/// Display labels aligned with Django `SERVICES` in `appointment_context.py`.
const Map<String, String> kAppointmentServiceLabels = {
  'frequency-specific-microcurrent': 'Frequency Specific Microcurrent',
  'infrared-sauna-therapy': 'Infrared Sauna Therapy',
  'hyperbaric-oxygen-therapy': 'Hyperbaric Oxygen Therapy',
  'iv-nutritional-infusions': 'IV Nutritional Infusions',
  'liquivida-iv-therapy': 'Liquivida IV Therapy',
  'reflexology': 'Reflexology',
  'ozone-therapy': 'Ozone Therapy',
  'ion-foot-detox': 'Ion Foot Detox',
  'wellness-classes': 'Wellness Classes',
  'personalized-wellness-plans': 'Personalized Wellness Plans',
  'constitutional-hydrotherapy': 'Constitutional Hydrotherapy',
};

const String kGeneralAppointmentLabel = 'General appointment';

/// Booking `service` value for availability + create (Django `normalize_booking_label`).
String bookingServiceLabel(
  SourceContext context, {
  BookOnlineOffering? offering,
}) {
  if (offering != null && offering.name.trim().isNotEmpty) {
    return offering.name.trim();
  }
  switch (context.type) {
    case SourceContextType.service:
      final fromSlug = kAppointmentServiceLabels[context.id];
      if (fromSlug != null) return fromSlug;
      final name = context.name.trim();
      return name.isEmpty ? kGeneralAppointmentLabel : name;
    case SourceContextType.condition:
      final name = context.name.trim();
      if (name.isEmpty) return kGeneralAppointmentLabel;
      return 'Consultation regarding $name';
    case SourceContextType.doctor:
      // Website: /appointments/sultana-afrooz/ → service "Sultana Afrooz".
      // API rejects credential suffixes ("…, D.O.") as General appointment.
      final name = doctorBookingName(context.name);
      return name.isEmpty ? kGeneralAppointmentLabel : name;
    case SourceContextType.blog:
    case SourceContextType.other:
      return kGeneralAppointmentLabel;
  }
}

/// Website booking label for a doctor (name without credentials).
String doctorBookingName(String rawName) {
  return rawName.split(',').first.trim();
}

/// Website-style reason line: "Appointment for …".
String appointmentForLabel(
  SourceContext context, {
  BookOnlineOffering? offering,
}) {
  return 'Appointment for ${bookingServiceLabel(context, offering: offering)}';
}
