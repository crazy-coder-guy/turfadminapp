import '../../../shared/models/owner.dart';

enum AuthStatus { bootstrapping, authenticated, unauthenticated }

class AuthState {
  const AuthState({required this.status, this.owner});

  final AuthStatus status;
  final Owner? owner;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  static const bootstrapping = AuthState(status: AuthStatus.bootstrapping);
  static const unauthenticated = AuthState(status: AuthStatus.unauthenticated);

  AuthState copyWith({Owner? owner}) => AuthState(status: status, owner: owner ?? this.owner);
}
