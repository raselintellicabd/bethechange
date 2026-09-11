/// Canonical REST paths used by repositories.
///
/// Mock mode serves these from local JSON via [MockApiInterceptor].
/// When Django DRF is ready, the same paths hit [EnvConfig.apiBaseUrl].
class ApiPaths {
  ApiPaths._();

  static const String about = '/about';
  static const String conditions = '/api/v1/conditions';
  static const String services = '/services';
  static const String blog = '/blog';
  static const String faq = '/faq';
  static const String clinic = '/clinic';
  static const String home = '/api/v1/home';
  static const String patients = '/patients';
  static const String contact = '/contact';
  static const String chatbotMessage = '/chatbot/message';
  static const String chatbotConfig = '/chatbot/config';
  static const String appointmentsAvailability = '/appointments/availability';
  static const String appointmentsSlots = '/appointments/slots';
  static const String appointments = '/appointments';

  static String condition(String id) => '$conditions/$id';
  static String service(String id) => '$services/$id';
  static String blogArticle(String id) => '$blog/$id';
}
