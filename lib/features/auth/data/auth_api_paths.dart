/// Patient auth + membership payment paths.
abstract final class AuthApiPaths {
  static const String signup = '/api/v1/auth/patient/signup/';
  static const String login = '/api/v1/auth/patient/login/';
  static const String me = '/api/v1/auth/patient/me/';
  static const String logout = '/api/v1/auth/patient/logout/';
  static const String refresh = '/api/v1/auth/token/refresh/';

  static const String membershipPaymentSession =
      '/api/v1/memberships/payment/session/';
  static const String membershipPaymentConfirm =
      '/api/v1/memberships/payment/confirm/';
}
