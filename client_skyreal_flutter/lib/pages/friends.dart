import 'package:dio/dio.dart';
import 'package:skyreal/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skyreal/services/dio_service.dart';

class FriendsPage extends StatefulWidget {
  @override
  _FriendsPageState createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  @override
  void initState() {
    super.initState();
  }

  TextEditingController _searchController = TextEditingController();

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
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        ElevatedButton(
                            child: Text("Send Request"),
                            onPressed: () async {
                              Dio dioService = DioService().getApi(state);
                              await dioService.post('friends/add', data: {
                                'recipient': _searchController.text
                              }).then((response) {
                                if (response.data['success']) {
                                  print(response.data['data']);
                                  // Show toast
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                    content: Text(response.data['data']),
                                    duration: Duration(seconds: 3),
                                  ));
                                } else {
                                  // Show toast
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                    content: Text(response.data['message']),
                                    duration: Duration(seconds: 3),
                                  ));
                                }
                              });
                            }),
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
