import 'package:dio/dio.dart';
import 'package:flutter_profile_picture/flutter_profile_picture.dart';
import 'package:skyreal/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skyreal/services/dio_service.dart';
import 'dart:math' as math;

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

  List<SearchUser> searchUsers = [];

  TextEditingController _searchController = TextEditingController();

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
                    child: NestedScrollView(
                        headerSliverBuilder:
                            (BuildContext context, bool innerBoxIsScrolled) {
                          final headerMaxWidth =
                              MediaQuery.of(context).size.width;

                          return <Widget>[
                            SliverAppBar(
                              stretch: true,
                              backgroundColor: Colors.transparent,
                              expandedHeight: 100,
                              automaticallyImplyLeading: false,
                              floating: true,
                              pinned: false,
                              snap: true,
                              flexibleSpace: FlexibleSpaceBar(
                                  centerTitle: true,
                                  stretchModes: [StretchMode.zoomBackground],
                                  background: Padding(
                                      padding: EdgeInsets.all(8),
                                      child: Row(children: [
                                        Expanded(
                                            child: TextField(
                                          controller: _searchController,
                                          decoration: InputDecoration(
                                            hintText: 'Search',
                                            prefixIcon: Icon(Icons.search),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                        )),
                                        SizedBox(width: 20),
                                        ElevatedButton(
                                            child: Text("Search"),
                                            onPressed: () async {
                                              Dio dioService =
                                                  DioService().getApi(state);
                                              try {
                                                var response = await dioService
                                                    .get(
                                                        'search/user?query=${_searchController.text}')
                                                    .catchError((error) {
                                                  print(error);
                                                  searchUsers = [];
                                                  setState(() {});
                                                });

                                                searchUsers.clear();
                                                /*{
    "success": true,
    "data": []
}*/
                                                if (response.data['success']) {
                                                  if (response.data['data'] !=
                                                      null) {
                                                    for (var user in response
                                                        .data['data']) {
                                                      searchUsers.add(
                                                          SearchUser.fromJson(
                                                              user));
                                                    }
                                                    setState(() {});
                                                    return;
                                                  }
                                                  searchUsers = [];
                                                  setState(() {});
                                                }
                                              } catch (e) {
                                                print(e);
                                              }
                                            }),
                                      ]))),
                            ),
                          ];
                        },
                        body: searchUsers.length > 0
                            ? ListView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: searchUsers.length,
                                itemBuilder: (context, index) {
                                  return SizedBox(
                                      // height: 100,
                                      child: ListTile(
                                          leading: ProfilePicture(
                                            name: searchUsers[index].username,
                                            radius: 25,
                                            fontsize: 17,
                                          ),
                                          title:
                                              Text(searchUsers[index].username),
                                          trailing: _buildSearchUserButton(
                                              dioService, searchUsers[index])
                                          // ElevatedButton(
                                          //     child: Text("Add"),
                                          //     onPressed: () async {
                                          //       Dio dioService =
                                          //           DioService().getApi(state);
                                          //       await dioService
                                          //           .post('friends/add', data: {
                                          //         'recipient':
                                          //             searchUsers[index].id
                                          //       }).then((response) {
                                          //         if (response.data['success']) {
                                          //           print(response.data['data']);
                                          //           // Show toast
                                          //           ScaffoldMessenger.of(context)
                                          //               .showSnackBar(SnackBar(
                                          //             content: Text(
                                          //                 response.data['data']),
                                          //             duration:
                                          //                 Duration(seconds: 3),
                                          //           ));
                                          //         } else {
                                          //           // Show toast
                                          //           ScaffoldMessenger.of(context)
                                          //               .showSnackBar(SnackBar(
                                          //             content: Text(response
                                          //                 .data['message']),
                                          //             duration:
                                          //                 Duration(seconds: 3),
                                          //           ));
                                          //         }
                                          //       });
                                          //     }),
                                          ));
                                })
                            : Container())));
          }
          return Center(
            child: Text('Something went wrong'),
          );
        },
      ),
    );
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
