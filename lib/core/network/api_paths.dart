/// Canonical REST paths used by repositories.
///
/// Mock mode serves these from local JSON via [MockApiInterceptor].
/// When Django DRF is ready, the same paths hit [EnvConfig.apiBaseUrl].
class ApiPaths {
  ApiPaths._();

  static const String about = '/api/v1/about';
  static const String conditions = '/api/v1/conditions';
  static const String services = '/api/v1/services';
  static const String blog = '/api/v1/blog';
  static const String faq = '/api/v1/faq';
  static const String clinic = '/clinic';
  static const String home = '/api/v1/home';
  static const String doctors = '/api/v1/doctors';
  static const String patients = '/patients';
  static const String contact = '/api/v1/contact';
  static const String memberships = '/api/v1/memberships';
  static const String packages = '/api/v1/packages';
  static const String chatbotMessage = '/chatbot/message';
  static const String chatbotConfig = '/chatbot/config';

  /// Website calendar/slot map (same JSON as the public appointments page).
  static const String appointmentsAvailability = '/appointments/availability/';

  static String packageDetail(String slug) => '$packages/$slug/';
  static String packageQuote(String slug) => '$packages/$slug/quote/';
  static String packagePaymentSession(String slug) =>
      '$packages/$slug/payment/session/';
  static String packageBook(String slug) => '$packages/$slug/book/';

  /// Paid booking quote / pay / book (JWT optional for member discounts).
  static const String appointmentsQuote = '/api/v1/appointments/quote/';
  static const String appointmentsPaymentSession =
      '/api/v1/appointments/payment/session/';
  static const String appointmentsPaymentConfirm =
      '/api/v1/appointments/payment/confirm/';
  static const String appointmentsBook = '/api/v1/appointments/book/';
  static const String appointmentsHistory = '/api/v1/appointments/history/';

  /// Legacy unpaid create (staff / older clients). Prefer [appointmentsBook].
  static const String appointments = '/api/v1/appointments/';

  /// Book-online catalog (categories + offerings). Served from mock JSON;
  /// production can point at the same path when Django exposes it.
  static const String bookOnline = '/api/v1/book-online/';

  static String condition(String id) => '$conditions/$id';
  static String service(String id) => '$services/$id';
  static String blogArticle(String id) => '$blog/$id';
  static String doctor(String slug) => '$doctors/$slug';
  static String aboutPage(String slug) => '$about/$slug';
}
