import 'models/source_context.dart';

/// Service detail CTAs open the /book-online/ picker so offerings come from
/// the live catalog. Conditions, doctors, and other sources go to the calendar.
bool usesBookOnlinePicker(SourceContext context) {
  return context.type == SourceContextType.service;
}
