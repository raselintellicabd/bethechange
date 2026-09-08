import '../../features/appointment/domain/models/source_context.dart';
import '../constants/app_constants.dart';

abstract final class AppRoutes {
  static const String home = '/home';
  static const String explore = '/explore';
  static const String exploreConditions = '/explore/conditions';
  static const String exploreServices = '/explore/services';
  static const String blog = '/blog';
  static const String blogDetail = '/blog/:articleId';
  static const String patients = '/patients';
  static const String contact = '/contact';

  static const String about = '/about';
  static const String aboutSection = '/about/:sectionId';
  static const String faq = '/faq';
  static const String chatbot = '/chatbot';
  static const String appointment = '/appointment';

  // Legacy paths kept for redirects / deep-link compatibility.
  static const String conditions = '/conditions';
  static const String services = '/services';
  static const String patient = '/patient';

  static String conditionDetailPath(String conditionId) =>
      '/explore/conditions/$conditionId';

  static String serviceDetailPath(String serviceId) =>
      '/explore/services/$serviceId';

  static String blogDetailPath(String articleId) => '/blog/$articleId';

  static String aboutSectionPath(String sectionId) => '/about/$sectionId';

  static String doctorDetailPath(String doctorId) => '/about/$doctorId';

  /// Appointment must always be opened with a required [SourceContext].
  static String appointmentPath(SourceContext sourceContext) {
    final encoded = Uri.encodeQueryComponent(sourceContext.encode());
    return '$appointment?${AppConstants.sourceContextQueryParam}=$encoded';
  }

  static SourceContext get clinicSourceContext => const SourceContext(
        type: SourceContextType.other,
        id: '',
        name: 'Be The Change Wellness Center',
      );
}
