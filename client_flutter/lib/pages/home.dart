import 'package:client_flutter/bloc/auth_bloc.dart';
import 'package:client_flutter/components/drawer.dart';
import 'package:client_flutter/pages/login.dart';
import 'package:client_flutter/services/dio_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomePage extends StatefulWidget {
  static String routeName = '/home';
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  _testApi() async {
    print("Test api auth status");
    Response response = await dio.get('auth/status');
    print(response.data);
    final Map responseMap = response.data;
    if (responseMap['success']) {
      authStatus = "Authenticated";
    } else {
      authStatus = "Not Authenticated";
    }
    setState(() {});
  }

  Dio dio = DioService().getApi();
  String authStatus = "Loading";
  @override
  void initState() {
    super.initState();
    _testApi();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: DrawerWidget(),
      appBar: AppBar(
        title: Text('Home'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              // TODO LOGOUT
              BlocProvider.of<AuthBloc>(context).add(SignOutRequested());
              Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                  (route) => false);
            },
          ),
          //Refresh Button
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              _testApi();
            },
          ),
        ],
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is Loading) {
            // Showing the loading indicator while the user is signing in
            return Center(
              child: CircularProgressIndicator(),
            );
          }
          if (state is Authenticated) {
            return Center(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Authenticated"),
                Text("User: ${state.authenticatedUser.email}"),
                Text("AuthState: $authStatus"),
              ],
            ));
          }
          // print(state);
          return Center(
            child: Text(authStatus),
          );
        },
      ),
    );
  }
}
