import 'models/source_context.dart';

/// CMS service page slugs that open the filtered /book-online/ picker.
///
/// Unmapped services (wellness classes, personalized plans, constitutional
/// hydrotherapy) go straight to the calendar.
const Set<String> kBookOnlineCmsTopics = {
  'ion-foot-detox',
  'frequency-specific-microcurrent',
  'hyperbaric-oxygen-therapy',
  'iv-nutritional-infusions',
  'liquivida-iv-therapy',
  'infrared-sauna-therapy',
  'reflexology',
  'ozone-therapy',
};

bool usesBookOnlinePicker(SourceContext context) {
  return context.type == SourceContextType.service &&
      kBookOnlineCmsTopics.contains(context.id);
}
