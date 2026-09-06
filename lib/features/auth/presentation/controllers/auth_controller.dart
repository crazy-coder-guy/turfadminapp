import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/providers.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../shared/models/owner.dart';
import '../../data/auth_repository.dart';
import '../../domain/auth_state.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.read(apiClientProvider));
});

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(
    repository: ref.read(authRepositoryProvider),
    storage: ref.read(secureStorageProvider),
    ref: ref,
  );
});

class AuthController extends StateNotifier<AuthState> {
  AuthController({
    required AuthRepository repository,
    required SecureStorageService storage,
    required Ref ref,
  })  : _repository = repository,
        _storage = storage,
        _ref = ref,
        super(AuthState.bootstrapping) {
    _ref.read(apiClientProvider).onSessionExpired = _handleSessionExpired;
    _bootstrap();
  }

  final AuthRepository _repository;
  final SecureStorageService _storage;
  final Ref _ref;

  Future<void> _bootstrap() async {
    final accessToken = await _storage.readAccessToken();
    if (accessToken == null) {
      state = AuthState.unauthenticated;
      return;
    }
    try {
      final owner = await _repository.me();
      state = AuthState(status: AuthStatus.authenticated, owner: owner);
    } catch (_) {
      await _storage.clear();
      state = AuthState.unauthenticated;
    }
  }

  Future<Owner> register({
    required String fullName,
    required String phoneNumber,
    required String email,
    required String password,
    required String profileImageUrl,
    required String ownerType,
    required String businessName,
    required String panNumber,
    String? gstin,
  }) {
    return _repository.register(
      fullName: fullName,
      phoneNumber: phoneNumber,
      email: email,
      password: password,
      profileImageUrl: profileImageUrl,
      ownerType: ownerType,
      businessName: businessName,
      panNumber: panNumber,
      gstin: gstin,
    );
  }

  Future<void> login({required String email, required String password}) async {
    final (tokens, owner) = await _repository.login(email: email, password: password);
    await _storage.saveTokens(accessToken: tokens.accessToken, refreshToken: tokens.refreshToken);
    state = AuthState(status: AuthStatus.authenticated, owner: owner);
  }

  Future<void> refreshProfile() async {
    final owner = await _repository.me();
    state = state.copyWith(owner: owner);
  }

  Future<void> logout() async {
    final refreshToken = await _storage.readRefreshToken();
    if (refreshToken != null) {
      try {
        await _repository.logout(refreshToken);
      } catch (_) {
      }
    }
    await _storage.clear();
    state = AuthState.unauthenticated;
  }

  void _handleSessionExpired() {
    _storage.clear();
    state = AuthState.unauthenticated;
  }
}
