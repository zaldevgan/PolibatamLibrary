import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../data/auth_service.dart';
import '../data/user_profile.dart';

// authenticating = proses login dari form (layar login tetap tampil)
enum AuthStatus { initial, loading, authenticating, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final UserProfile? user;
  final String? errorMessage;

  AuthState({
    required this.status,
    this.user,
    this.errorMessage,
  });

  factory AuthState.initial() => AuthState(status: AuthStatus.initial);
  factory AuthState.loading() => AuthState(status: AuthStatus.loading);
  factory AuthState.authenticating() => AuthState(status: AuthStatus.authenticating);
  factory AuthState.authenticated(UserProfile user) =>
      AuthState(status: AuthStatus.authenticated, user: user);
  factory AuthState.unauthenticated() =>
      AuthState(status: AuthStatus.unauthenticated);
  factory AuthState.error(String msg) =>
      AuthState(status: AuthStatus.error, errorMessage: msg);
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(AuthState.initial()) {
    ApiClient.onUnauthorized = _onSessionExpired;
    checkCurrentSession();
  }

  Future<void> checkCurrentSession() async {
    state = AuthState.loading();
    try {
      final user = await _authService.getCurrentUser();
      if (user == null) {
        state = AuthState.unauthenticated();
        return;
      }
      state = AuthState.authenticated(user);
      _refreshProfileInBackground();
    } catch (_) {
      state = AuthState.unauthenticated();
    }
  }

  /// Sinkronkan profil dari server; tetap pakai profil tersimpan saat offline
  Future<void> _refreshProfileInBackground() async {
    try {
      final fresh = await _authService.refreshProfile();
      if (fresh != null && state.status == AuthStatus.authenticated) {
        state = AuthState.authenticated(fresh);
      }
    } catch (_) {}
  }

  Future<void> login({
    required String username,
    required String password,
  }) async {
    state = AuthState.authenticating();
    try {
      final user = await _authService.login(
        username: username,
        password: password,
      );
      state = AuthState.authenticated(user);
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  Future<void> _onSessionExpired() async {
    if (state.status != AuthStatus.authenticated) return;
    await _authService.clearLocalSession();
    state = AuthState.error('Sesi login Anda telah berakhir. Silakan login kembali.');
  }

  Future<void> logout() async {
    state = AuthState.loading();
    await _authService.logout();
    state = AuthState.unauthenticated();
  }
}

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final service = ref.watch(authServiceProvider);
  return AuthNotifier(service);
});
