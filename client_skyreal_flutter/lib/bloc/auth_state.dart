part of 'auth_bloc.dart';

@immutable
abstract class AuthState extends Equatable {}

// When the user presses the signin or signup button the state is changed to loading first and then to Authenticated.
class Loading extends AuthState {
  @override
  List<Object?> get props => [];
}

// When the user is authenticated the state is changed to Authenticated.
class Authenticated extends AuthState {
  final UserState authenticatedUser;
  Authenticated({required this.authenticatedUser});

  bool changeAvatar(String avatar) {
    authenticatedUser.avatar = avatar;
    const FlutterSecureStorage storage = FlutterSecureStorage();
    storage.write(key: "avatar", value: avatar);
    return true;
  }

  bool updateAccessToken(String accessToken) {
    authenticatedUser.accessToken = accessToken;
    const FlutterSecureStorage storage = FlutterSecureStorage();
    storage.write(key: "accessToken", value: accessToken);
    return true;
  }

  @override
  List<Object?> get props => [authenticatedUser];
}

// This is the initial state of the bloc. When the user is not authenticated the state is changed to Unauthenticated.
class UnAuthenticated extends AuthState {
  @override
  List<Object?> get props => [];
}

// If any error occurs the state is changed to AuthError.
class AuthError extends AuthState {
  final String error;

  AuthError(this.error);
  @override
  List<Object?> get props => [error];
}

class OTPRequired extends AuthState {
  @override
  List<Object?> get props => [];
}
