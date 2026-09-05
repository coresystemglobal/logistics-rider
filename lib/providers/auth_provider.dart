import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/rider_service.dart';
import '../core/api/token_storage.dart';

enum AuthStatus { unknown, loading, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? error;
  final bool isPendingRider;

  const AuthState({
    required this.status,
    this.user,
    this.error,
    this.isPendingRider = false,
  });

  const AuthState.unknown()
      : status = AuthStatus.unknown,
        user = null,
        error = null,
        isPendingRider = false;

  const AuthState.loading()
      : status = AuthStatus.loading,
        user = null,
        error = null,
        isPendingRider = false;

  AuthState.authenticated(UserModel this.user, {bool pending = false})
      : status = AuthStatus.authenticated,
        error = null,
        isPendingRider = pending;

  const AuthState.unauthenticated([this.error])
      : status = AuthStatus.unauthenticated,
        user = null,
        isPendingRider = false;

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isRider => user?.isRider ?? false;
  bool get isCustomer => user?.isUser ?? false;
  bool get isEmailVerified => user?.emailVerified ?? false;
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final RiderService _riderService;

  AuthNotifier(this._authService, this._riderService) : super(const AuthState.unknown()) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      final hasTokens = await TokenStorage.hasTokens();
      if (!hasTokens) {
        state = const AuthState.unauthenticated();
        return;
      }
      final user = await _authService.getMe();
      if (user.isRider) {
        try {
          final profile = await _riderService.getProfile();
          if (profile.verificationStatus == 'PENDING') {
            state = AuthState.authenticated(user, pending: true);
            return;
          }
        } catch (_) {}
      }
      state = AuthState.authenticated(user);
    } catch (_) {
      await TokenStorage.clearTokens();
      state = const AuthState.unauthenticated();
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      await _authService.login(email: email, password: password);
      final user = await _authService.getMe();
      state = AuthState.authenticated(user);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> registerCustomer({
    required String firstName,
    required String surname,
    required String email,
    required String phone,
    required String password,
  }) async {
    await _authService.registerCustomer(
      firstName: firstName,
      surname: surname,
      email: email,
      phone: phone,
      password: password,
    );
    final user = await _authService.getMe();
    state = AuthState.authenticated(user);
  }

  Future<void> registerRider({
    required String firstName,
    required String surname,
    required String email,
    required String phone,
    required String password,
    required String vehicleType,
    String? licenseNumber,
    String? vehiclePlate,
    String? licensePhoto,
    String? vehiclePhoto,
    String? referralCode,
  }) async {
    state = const AuthState.loading();
    try {
      await _authService.registerRider(
        firstName: firstName,
        surname: surname,
        email: email,
        phone: phone,
        password: password,
        vehicleType: vehicleType,
        licenseNumber: licenseNumber,
        vehiclePlate: vehiclePlate,
        licensePhoto: licensePhoto,
        vehiclePhoto: vehiclePhoto,
        referralCode: referralCode,
      );
      // Fetch user so router can check email_verified and redirect correctly
      final user = await _authService.getMe();
      state = AuthState.authenticated(user, pending: true);
    } catch (e) {
      final msg = e.toString()
          .replaceFirst(RegExp(r'ApiException\(\d+\): '), '');
      state = AuthState.unauthenticated(msg);
    }
  }

  Future<void> registerBusiness({
    required String businessName,
    required String email,
    required String phone,
    required String address,
    required String cacNumber,
    required String password,
  }) async {
    await _authService.registerBusiness(
      businessName: businessName,
      email: email,
      phone: phone,
      address: address,
      cacNumber: cacNumber,
      password: password,
    );
    final user = await _authService.getMe();
    state = AuthState.authenticated(user);
  }

  Future<void> logout() async {
    await _authService.logout();
    state = const AuthState.unauthenticated();
  }

  Future<void> refreshUser() async {
    try {
      final user = await _authService.getMe();
      state = AuthState.authenticated(user);
    } catch (_) {}
  }
}

// Providers
final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final riderServiceProvider = Provider<RiderService>((ref) => RiderService());

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authServiceProvider), ref.read(riderServiceProvider));
});
