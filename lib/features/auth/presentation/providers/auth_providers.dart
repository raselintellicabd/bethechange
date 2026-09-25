import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_result.dart';
import '../../data/auth_repository.dart';
import '../../domain/models/patient_user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(authTokenStoreProvider),
  );
});

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  const AuthState({
    required this.status,
    this.user,
    this.accessToken,
    this.refreshToken,
    this.isBusy = false,
    this.errorMessage,
  });

  final AuthStatus status;
  final PatientUser? user;
  final String? accessToken;
  final String? refreshToken;
  final bool isBusy;
  final String? errorMessage;

  bool get isLoggedIn =>
      status == AuthStatus.authenticated && user != null;

  AuthState copyWith({
    AuthStatus? status,
    PatientUser? user,
    String? accessToken,
    String? refreshToken,
    bool? isBusy,
    String? errorMessage,
    bool clearUser = false,
    bool clearError = false,
    bool clearTokens = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : user ?? this.user,
      accessToken: clearTokens ? null : accessToken ?? this.accessToken,
      refreshToken: clearTokens ? null : refreshToken ?? this.refreshToken,
      isBusy: isBusy ?? this.isBusy,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});

final currentUserProvider = Provider<PatientUser?>((ref) {
  return ref.watch(authControllerProvider).user;
});

final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(authControllerProvider).isLoggedIn;
});

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repository)
      : super(const AuthState(status: AuthStatus.unknown)) {
    restore();
  }

  final AuthRepository _repository;

  Future<void> restore() async {
    final session = await _repository.restoreSession();
    if (session == null) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      return;
    }
    state = AuthState(
      status: AuthStatus.authenticated,
      user: session.user,
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    );
    final me = await _repository.fetchMe();
    if (me is ApiSuccess<PatientUser>) {
      await _repository.store.saveUser(me.data);
      state = state.copyWith(user: me.data);
    } else if (me is ApiFailure<PatientUser> && me.statusCode == 401) {
      await _repository.store.clear();
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isBusy: true, clearError: true);
    final result = await _repository.login(email: email, password: password);
    return _applyAuthResult(result);
  }

  Future<bool> signup({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
  }) async {
    state = state.copyWith(isBusy: true, clearError: true);
    final result = await _repository.signup(
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
      password: password,
    );
    return _applyAuthResult(result);
  }

  Future<void> logout() async {
    state = state.copyWith(isBusy: true, clearError: true);
    await _repository.logout(refreshToken: state.refreshToken);
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> refreshProfile() async {
    if (!state.isLoggedIn) return;
    final me = await _repository.fetchMe();
    if (me is ApiSuccess<PatientUser>) {
      await _repository.store.saveUser(me.data);
      state = state.copyWith(user: me.data);
    }
  }

  /// Updates the cached points balance after a claim (or other spend/earn).
  Future<void> applyPointsBalance(int points) async {
    final user = state.user;
    if (user == null) return;
    final updated = user.copyWith(points: points < 0 ? 0 : points);
    await _repository.store.saveUser(updated);
    state = state.copyWith(user: updated);
  }

  /// Adds earned loyalty points after a paid booking.
  Future<void> addPoints(int awarded) async {
    if (awarded <= 0 || state.user == null) return;
    await applyPointsBalance(state.user!.points + awarded);
  }

  Future<bool> updateProfile({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
  }) async {
    state = state.copyWith(isBusy: true, clearError: true);
    final result = await _repository.updateProfile(
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
    );
    if (result is ApiSuccess<PatientUser>) {
      await _repository.store.saveUser(result.data);
      state = state.copyWith(
        isBusy: false,
        user: result.data,
        clearError: true,
      );
      return true;
    }
    final failure = result as ApiFailure<PatientUser>;
    state = state.copyWith(isBusy: false, errorMessage: failure.message);
    return false;
  }

  Future<bool> _applyAuthResult(ApiResult<AuthSession> result) async {
    if (result is ApiSuccess<AuthSession>) {
      final session = result.data;
      await _repository.store.saveSession(session);
      state = AuthState(
        status: AuthStatus.authenticated,
        user: session.user,
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
      );
      return true;
    }
    final failure = result as ApiFailure<AuthSession>;
    state = state.copyWith(
      isBusy: false,
      status: AuthStatus.unauthenticated,
      clearUser: true,
      clearTokens: true,
      errorMessage: failure.message,
    );
    return false;
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}
