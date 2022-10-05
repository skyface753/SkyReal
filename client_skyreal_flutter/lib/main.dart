import 'package:skyreal/bloc/auth_bloc.dart';
import 'package:skyreal/data/repositories/auth_repository.dart';
import 'package:skyreal/pages/home.dart';
import 'package:skyreal/pages/login.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  //Remove this method to stop OneSignal Debugging
  // OneSignal.shared.setLogLevel(OSLogLevel.verbose, OSLogLevel.none);

  OneSignal.shared.setAppId("01c10689-c5cd-4691-986b-c8f8be9040c3");

// The promptForPushNotificationsWithUserResponse function will show the iOS or Android push notification prompt. We recommend removing the following code and instead using an In-App Message to prompt for notification permission
  OneSignal.shared.promptUserForPushNotificationPermission().then((accepted) {
    print("Accepted permission: $accepted");
  });
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
