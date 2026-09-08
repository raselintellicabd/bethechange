import '../../features/appointment/domain/models/source_context.dart';
import '../constants/app_constants.dart';

abstract final class AppRoutes {
  static const String about = '/about';
  static const String conditions = '/conditions';
  static const String conditionDetail = '/conditions/:conditionId';
  static const String services = '/services';
  static const String serviceDetail = '/services/:serviceId';
  static const String blog = '/blog';
  static const String blogDetail = '/blog/:articleId';
  static const String patient = '/patient';
  static const String appointment = '/appointment';
  static const String faq = '/faq';
  static const String chatbot = '/chatbot';
  static const String contact = '/contact';

  static String conditionDetailPath(String conditionId) =>
      '/conditions/$conditionId';

  static String serviceDetailPath(String serviceId) => '/services/$serviceId';

  static String blogDetailPath(String articleId) => '/blog/$articleId';

  /// Appointment must always be opened with a required [SourceContext].
  static String appointmentPath(SourceContext sourceContext) {
    final encoded = Uri.encodeQueryComponent(sourceContext.encode());
    return '$appointment?${AppConstants.sourceContextQueryParam}=$encoded';
  }
}
