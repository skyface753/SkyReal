import 'package:client_flutter/bloc/auth_bloc.dart';
import 'package:client_flutter/data/repositories/auth_repository.dart';
import 'package:client_flutter/pages/home.dart';
import 'package:client_flutter/pages/login.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (context) => AuthRepository(),
      child: BlocProvider(
        create: (context) => AuthBloc(
          authRepository: RepositoryProvider.of<AuthRepository>(context),
        )..add(AppStarted()),
        child: MaterialApp(
            themeMode: ThemeMode.dark,
            darkTheme: ThemeData.dark(),
            theme: ThemeData.light(),
            // home: const App(),

            home: LoginPage()),
      ),
    );
  }
}
