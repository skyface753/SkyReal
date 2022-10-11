import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:skyreal/components/friendspage/aUserListTile.dart';
import 'package:skyreal/pages/friends.dart';

class FriendsListView extends StatefulWidget {
  final Dio dioService;

  FriendsListView({required this.dioService, Key? key}) : super(key: key);

  @override
  _FriendsListViewState createState() => _FriendsListViewState();
}

class _FriendsListViewState extends State<FriendsListView> {
  Future<List<SearchUser>> _getFriends() async {
    var response = await widget.dioService.get('friends/all');
    print(response.data);
    /*{
    "success": true,
    "data": [
        {
            "id": 1,
            "username": "skyface",
            "friendship": "friends"
        }
    ]
}*/
    if (response.data['success']) {
      List<SearchUser> friends = [];
      for (var friend in response.data['data']) {
        friends.add(SearchUser(
            id: friend['id'],
            username: friend['username'],
            status: friend['friendship'] == 'friends'
                ? FriendStatus.friends
                : FriendStatus.pendingOutgoing));
      }
      return friends;
    } else {
      return [];
    }
    List<SearchUser> friends = [];

    for (var user in response.data) {
      friends.add(SearchUser.fromJson(user));
    }
    for (var friend in friends) {
      print(friend.username);
    }
    return friends;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _getFriends(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data!.isEmpty) {
              return Center(child: Text("You have no friends yet"));
            }
            return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  return AUserListTile(
                      user: snapshot.data![index],
                      dioService: widget.dioService);
                });
          } else {
            return Center(child: CircularProgressIndicator());
          }
        });
  }
}
