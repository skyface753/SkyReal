part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  @override
  List<Object> get props => [];
}

// When the user signing in with email and password this event is called and the [AuthRepository] is called to sign in the user
class SignInRequested extends AuthEvent {
  final String username;
  final String password;
  final String? totpCode;
  SignInRequested(this.username, this.password, {this.totpCode});
}

// When the user signing up with email and password this event is called and the [AuthRepository] is called to sign up the user
class SignUpRequested extends AuthEvent {
  final String email;
  final String password;
  final String username;
  SignUpRequested(this.email, this.password, this.username);
}

// When the user signing in with google this event is called and the [AuthRepository] is called to sign in the user
// class GoogleSignInRequested extends AuthEvent {}

// When the user signing out this event is called and the [AuthRepository] is called to sign out the user
class SignOutRequested extends AuthEvent {}

class AppStarted extends AuthEvent {}

class ChangeAvatarRequested extends AuthEvent {
  final String avatar;
  ChangeAvatarRequested(this.avatar);
}

class CancleOTP extends AuthEvent {}
