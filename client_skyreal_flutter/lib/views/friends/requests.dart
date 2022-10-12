import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:skyreal/components/friendspage/aUserListTile.dart';
import 'package:skyreal/pages/friends.dart';

class FriendRequestsList extends StatefulWidget {
  final Dio dioService;

  FriendRequestsList({required this.dioService, Key? key}) : super(key: key);
  @override
  _FriendRequestsListState createState() => _FriendRequestsListState();
}

class _FriendRequestsListState extends State<FriendRequestsList> {
  Future<List<SearchUser>?> _getFriendRequests() async {
    var response = await widget.dioService.get('friends/requests');
    print(response.data);
    /*{
   {
    "success": true,
    "data": [
        {
            "id": 1,
            "username": "skyface",
            "friendship": "pendingIn"
        }
    ]
}*/
    if (response.data['success']) {
      List<SearchUser> friends = [];
      for (var friend in response.data['data']) {
        friends.add(SearchUser(
            id: friend['id'],
            username: friend['username'],
            status: friend['friendship'] == 'pendingIn'
                ? FriendStatus.pendingIncoming
                : FriendStatus.pendingOutgoing));
      }
      return friends;
    } else {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        child: FutureBuilder(
      future: _getFriendRequests(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data!.isEmpty) {
            return Center(
              child: Text('No friend requests'),
            );
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                return AUserListTile(
                    user: snapshot.data![index], dioService: widget.dioService);
              },
            );
          }
        } else {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    ));
  }
}
