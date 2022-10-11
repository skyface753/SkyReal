import 'package:dio/dio.dart';
import 'package:flutter_profile_picture/flutter_profile_picture.dart';
import 'package:skyreal/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skyreal/components/friendspage/aUserListTile.dart';
import 'package:skyreal/services/dio_service.dart';
import 'package:skyreal/views/friends/friendslist.dart';
import 'dart:math' as math;

import 'package:skyreal/views/friends/search.dart';

class FriendsPage extends StatefulWidget {
  @override
  _FriendsPageState createState() => _FriendsPageState();
}

enum FriendStatus { pendingOutgoing, pendingIncoming, friends, none }

FriendStatus friendStatusFromString(String status) {
  switch (status) {
    case 'pendingOut':
      return FriendStatus.pendingOutgoing;
    case 'pendingIn':
      return FriendStatus.pendingIncoming;
    case 'friends':
      return FriendStatus.friends;
    default:
      return FriendStatus.none;
  }
}

class SearchUser {
  int id;
  String username;
  FriendStatus status;

  SearchUser({required this.id, required this.username, required this.status});

  factory SearchUser.fromJson(Map<String, dynamic> json) {
    return SearchUser(
        id: json['id'],
        username: json['username'],
        status: friendStatusFromString(json['friendship']));
  }
}

class _FriendsPageState extends State<FriendsPage> {
  @override
  void initState() {
    super.initState();
  }

  int index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text('Friends'),
      // ),
      appBar: AppBar(
          title: Text("Friends"),
          automaticallyImplyLeading: false,
          actions: [
            // Back button
            IconButton(
                icon: Transform.rotate(
                    angle: 180 * math.pi / 180,
                    child: Icon(Icons.arrow_back_ios)),
                onPressed: () {
                  Navigator.pop(context);
                }),
          ]),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is Loading) {
            // Showing the loading indicator while the user is signing in
            return Center(
              child: CircularProgressIndicator(),
            );
          }
          if (state is Authenticated) {
            Dio dioService = DioService().getApi(state);
            return SafeArea(
                child: Stack(
              children: [
                _stackedContainers(dioService, state),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: _navigationButtons(),
                ),
              ],
            ));
          }
          return const Center(
            child: Text('Something went wrong'),
          );
        },
      ),
    );
  }

  Widget _navigationButtons() {
    return
        // Oval Container with 3 Buttons
        Container(
      height: 60,
      width: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 5,
            blurRadius: 7,
            offset: Offset(0, 3), // changes position of shadow
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Requests Button
          IconButton(
              icon: Icon(Icons.person_add),
              color: index == 0 ? Colors.blue : Colors.grey,
              onPressed: () {
                setState(() {
                  index = 0;
                });
              }),
          // Search Button
          IconButton(
              icon: Icon(Icons.search),
              color: index == 1 ? Colors.blue : Colors.grey,
              onPressed: () {
                setState(() {
                  index = 1;
                });
              }),
          // Friends Button

          IconButton(
              icon: Icon(Icons.people),
              color: index == 2 ? Colors.blue : Colors.grey,
              onPressed: () {
                setState(() {
                  index = 2;
                });
              }),
        ],
      ),
    );
  }

  Widget _stackedContainers(Dio dioService, AuthState authState) {
    return IndexedStack(
      index: index,
      children: <Widget>[
        Container(),
        FriendsSearchView(dioService: dioService, authState: authState),
        FriendsListView(dioService: dioService)
      ],
    );
  }
}
