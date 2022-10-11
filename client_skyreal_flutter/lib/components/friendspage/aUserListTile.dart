import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_profile_picture/flutter_profile_picture.dart';
import 'package:skyreal/pages/friends.dart';

class AUserListTile extends StatefulWidget {
  SearchUser user;
  final Dio dioService;
  AUserListTile({required this.user, required this.dioService, Key? key})
      : super(key: key);

  @override
  _AUserListTileState createState() => _AUserListTileState();
}

class _AUserListTileState extends State<AUserListTile> {
  @override
  Widget build(BuildContext context) {
    return ListTile(
        leading: ProfilePicture(
          name: widget.user.username,
          radius: 25,
          fontsize: 17,
        ),
        title: Text(widget.user.username),
        trailing: _buildSearchUserButton(widget.dioService, widget.user));
  }

  ElevatedButton _buildSearchUserButton(Dio dioService, SearchUser searchUser) {
    Text buttonText;
    switch (searchUser.status) {
      case FriendStatus.none:
        buttonText = Text("Add");
        break;
      case FriendStatus.pendingIncoming:
        buttonText = Text("Accept");
        break;
      case FriendStatus.pendingOutgoing:
        buttonText = Text("Cancel");
        break;
      case FriendStatus.friends:
        buttonText = Text("Friends");
        break;
    }
    return ElevatedButton(
        child: buttonText,
        onPressed: () async {
          if (searchUser.status == FriendStatus.none ||
              searchUser.status == FriendStatus.pendingIncoming) {
            if (searchUser.status == FriendStatus.none) {
              setState(() {
                searchUser.status = FriendStatus.pendingOutgoing;
              });
            } else if (searchUser.status == FriendStatus.pendingIncoming) {
              setState(() {
                searchUser.status = FriendStatus.friends;
              });
            }
            await dioService.post('friends/add',
                data: {'recipient': searchUser.id}).then((response) {
              if (response.data['success']) {
                print(response.data['data']);
                // Show toast
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(response.data['data']),
                  duration: Duration(seconds: 3),
                ));
              } else {
                // Show toast
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(response.data['message']),
                  duration: Duration(seconds: 3),
                ));
              }
            });
          } else if (searchUser.status == FriendStatus.pendingOutgoing) {
            setState(() {
              searchUser.status = FriendStatus.none;
            });
            await dioService.post('friends/remove',
                data: {'recipient': searchUser.id}).then((response) {
              if (response.data['success']) {
                print(response.data['data']);
                // Show toast
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(response.data['data']),
                  duration: Duration(seconds: 3),
                ));
              } else {
                // Show toast
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(response.data['message']),
                  duration: Duration(seconds: 3),
                ));
              }
            });
          } else if (searchUser.status == FriendStatus.friends) {
            // Show Dialog
            showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text("Remove Friend"),
                    content: Text(
                        "Are you sure you want to remove ${searchUser.username} from your friends list?"),
                    actions: [
                      TextButton(
                          onPressed: () async {
                            setState(() {
                              searchUser.status = FriendStatus.none;
                            });
                            await dioService.post('friends/remove', data: {
                              'recipient': searchUser.id
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
                            Navigator.of(context).pop();
                          },
                          child: Text("Yes")),
                      TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text("No"))
                    ],
                  );
                });
          }
        });
  }
}
