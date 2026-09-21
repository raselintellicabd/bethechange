import '../../features/appointment/domain/book_online_topics.dart';
import '../../features/appointment/domain/models/book_online_offering.dart';
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
  static const String membership = '/membership';
  static const String membershipCheckout = '/membership/checkout';
  static const String login = '/login';
  static const String signup = '/signup';

  static String loginPath({String? returnTo}) {
    if (returnTo == null || returnTo.isEmpty) return login;
    return Uri(
      path: login,
      queryParameters: {'returnTo': returnTo},
    ).toString();
  }

  static String signupPath({String? returnTo}) {
    if (returnTo == null || returnTo.isEmpty) return signup;
    return Uri(
      path: signup,
      queryParameters: {'returnTo': returnTo},
    ).toString();
  }

  static const String about = '/about';
  static const String aboutSection = '/about/:sectionId';
  static const String faq = '/faq';
  static const String chatbot = '/chatbot';
  static const String appointment = '/appointment';
  static const String bookOnline = '/book-online';

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

  /// Filtered book-online picker for a CMS service page.
  static String bookOnlinePath(SourceContext sourceContext) {
    final encoded = Uri.encodeQueryComponent(sourceContext.encode());
    return '$bookOnline?${AppConstants.sourceContextQueryParam}=$encoded';
  }

  /// Appointment must always be opened with a required [SourceContext].
  static String appointmentPath(
    SourceContext sourceContext, {
    BookOnlineOffering? offering,
  }) {
    final params = <String, String>{
      AppConstants.sourceContextQueryParam: sourceContext.encode(),
    };
    if (offering != null) {
      params[AppConstants.offeringQueryParam] = offering.encode();
    }
    return Uri(path: appointment, queryParameters: params).toString();
  }

  /// Service pages with a book-online category → picker; otherwise calendar.
  static String bookingEntryPath(SourceContext sourceContext) {
    if (usesBookOnlinePicker(sourceContext)) {
      return bookOnlinePath(sourceContext);
    }
    return appointmentPath(sourceContext);
  }

  static SourceContext get clinicSourceContext => const SourceContext(
        type: SourceContextType.other,
        id: '',
        name: 'Be The Change Wellness Center',
      );
}
