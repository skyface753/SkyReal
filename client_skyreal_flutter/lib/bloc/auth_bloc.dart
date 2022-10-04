import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:skyreal/data/repositories/auth_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:meta/meta.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;
  AuthBloc({required this.authRepository}) : super(UnAuthenticated()) {
    // When User Presses the SignIn Button, we will send the SignInRequested Event to the AuthBloc to handle it and emit the Authenticated State if the user is authenticated
    on<SignInRequested>((event, emit) async {
      emit(Loading());
      try {
        await authRepository
            .signIn(
                email: event.email,
                password: event.password,
                totpCode: event.totpCode)
            .then((value) => {
                  print("Emitted Authenticated"),
                  print(value),
                  if (value == "2FA")
                    {emit(OTPRequired())}
                  else
                    {emit(Authenticated(authenticatedUser: value as UserState))}
                });
      } catch (e) {
        emit(AuthError(e.toString()));
        emit(UnAuthenticated());
      }
    });
    // When User Presses the SignUp Button, we will send the SignUpRequest Event to the AuthBloc to handle it and emit the Authenticated State if the user is authenticated
    on<SignUpRequested>((event, emit) async {
      emit(Loading());
      try {
        await authRepository
            .signUp(
                email: event.email,
                password: event.password,
                username: event.username)
            .then((value) => {
                  print("Emitted Register Authenticated"),
                  print(value),
                  emit(Authenticated(authenticatedUser: value!))
                });
      } catch (e) {
        emit(AuthError(e.toString()));
        emit(UnAuthenticated());
      }
    });
    // When User Presses the SignOut Button, we will send the SignOutRequested Event to the AuthBloc to handle it and emit the UnAuthenticated State
    on<SignOutRequested>((event, emit) async {
      emit(Loading());
      await authRepository.signOut();
      emit(UnAuthenticated());
    });
    // When the App Starts, we will send the OnStartUp Event to the AuthBloc to handle it and emit the Authenticated State if the user is authenticated
    on<AppStarted>((event, emit) async {
      emit(Loading());
      UserState? userState = await authRepository.isSignedIn();
      if (userState != null) {
        emit(Authenticated(authenticatedUser: userState));
      } else {
        emit(UnAuthenticated());
      }
    });

    on<ChangeAvatarRequested>((event, emit) async {
      emit(Loading());
      try {
        await authRepository.changeAvatar(event.avatar);
        UserState? userState = await authRepository.isSignedIn();
        if (userState != null) {
          emit(Authenticated(authenticatedUser: userState));
        } else {
          print("UserState is null");
        }
      } catch (e) {
        print(e);
        emit(AuthError(e.toString()));
        emit(UnAuthenticated());
      }
    });
  }
}
