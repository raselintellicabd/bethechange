import '../../../core/network/api_client.dart';
import '../../../core/network/api_result.dart';
import '../domain/models/patient_user.dart';
import 'auth_api_paths.dart';
import 'auth_token_store.dart';

class AuthRepository {
  AuthRepository(this._client, this._store);

  final ApiClient _client;
  final AuthTokenStore _store;

  AuthTokenStore get store => _store;

  Future<AuthSession?> restoreSession() => _store.readSession();

  Future<ApiResult<AuthSession>> signup({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
  }) {
    return _client.post(
      AuthApiPaths.signup,
      data: {
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'phone': phone,
        'password': password,
      },
      parser: _parseAuthResponse,
    );
  }

  Future<ApiResult<AuthSession>> login({
    required String email,
    required String password,
  }) {
    return _client.post(
      AuthApiPaths.login,
      data: {'email': email, 'password': password},
      parser: _parseAuthResponse,
    );
  }

  Future<ApiResult<PatientUser>> fetchMe() {
    return _client.get(
      AuthApiPaths.me,
      parser: (data) => PatientUser.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResult<void>> logout({String? refreshToken}) async {
    final refresh = refreshToken ?? await _store.readRefreshToken();
    final result = await _client.post(
      AuthApiPaths.logout,
      data: {if (refresh != null && refresh.isNotEmpty) 'refresh': refresh},
      parser: (_) {},
    );
    await _store.clear();
    return result;
  }

  Future<ApiResult<String>> refreshAccessToken(String refreshToken) {
    return _client.post(
      AuthApiPaths.refresh,
      data: {'refresh': refreshToken},
      parser: (data) {
        final map = data as Map<String, dynamic>;
        final access = (map['access'] as String?)?.trim() ?? '';
        if (access.isEmpty) {
          throw const FormatException('Missing access token');
        }
        return access;
      },
    );
  }

  Future<ApiResult<Map<String, dynamic>>> startMembershipPayment({
    required int tier,
  }) {
    return _client.post(
      AuthApiPaths.membershipPaymentSession,
      data: {'tier': tier},
      parser: (data) => Map<String, dynamic>.from(data as Map),
    );
  }

  Future<ApiResult<Map<String, dynamic>>> confirmMembershipPayment({
    required String paymentSessionId,
    required String clientSecret,
    required Map<String, dynamic> paymentMethod,
  }) {
    return _client.post(
      AuthApiPaths.membershipPaymentConfirm,
      data: {
        'payment_session_id': paymentSessionId,
        'client_secret': clientSecret,
        'payment_method': paymentMethod,
      },
      parser: (data) => Map<String, dynamic>.from(data as Map),
    );
  }

  AuthSession _parseAuthResponse(dynamic data) {
    final map = data as Map<String, dynamic>;
    final access = (map['access'] as String?)?.trim() ?? '';
    final refresh = (map['refresh'] as String?)?.trim() ?? '';
    final userRaw = map['user'];
    if (access.isEmpty || refresh.isEmpty || userRaw is! Map) {
      throw const FormatException('Invalid auth response');
    }
    return AuthSession(
      accessToken: access,
      refreshToken: refresh,
      user: PatientUser.fromJson(Map<String, dynamic>.from(userRaw)),
    );
  }
}
