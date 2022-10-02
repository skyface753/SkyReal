import 'package:client_flutter/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FriendsPage extends StatefulWidget {
  @override
  _FriendsPageState createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Friends'),
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
            return RefreshIndicator(
                onRefresh: () async {
                  // await DioService().getApi().get('auth/status').then((value) {
                  //   final Map responseMap = value.data;
                  //   if (responseMap['success']) {
                  //     print(responseMap['data']);
                  //   }
                  // });
                },
                child: SafeArea(
                    child: CustomScrollView(slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(height: 20),
                        Text('Welcome ${state.authenticatedUser.username}'),
                        SizedBox(height: 2000),
                        Container(
                          height: 50,
                          color: Colors.red,
                          // Full width
                          width: double.infinity,
                        )
                      ],
                    ),
                  )
                ])));
          }
          return Center(
            child: Text('Something went wrong'),
          );
        },
      ),
    );
  }
}
