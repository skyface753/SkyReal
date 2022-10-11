import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:skyreal/bloc/auth_bloc.dart';
import 'package:skyreal/components/friendspage/aUserListTile.dart';
import 'package:skyreal/pages/friends.dart';
import 'package:skyreal/services/dio_service.dart';

class FriendsSearchView extends StatefulWidget {
  final Dio dioService;
  final AuthState authState;
  FriendsSearchView({required this.dioService, required this.authState});
  @override
  _FriendsSearchViewState createState() => _FriendsSearchViewState();
}

class _FriendsSearchViewState extends State<FriendsSearchView> {
  TextEditingController _searchController = TextEditingController();
  List<SearchUser> searchUsers = [];
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          final headerMaxWidth = MediaQuery.of(context).size.width;

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
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        )),
                        SizedBox(width: 20),
                        ElevatedButton(
                            child: Text("Search"),
                            onPressed: () async {
                              setState(() {
                                loading = true;
                              });
                              Dio dioService =
                                  DioService().getApi(widget.authState);
                              try {
                                var response = await dioService
                                    .get(
                                        'search/user?query=${_searchController.text}')
                                    .catchError((error) {
                                  print(error);
                                  searchUsers = [];
                                  setState(() {
                                    loading = false;
                                  });
                                });

                                searchUsers.clear();
                                /*{
    "success": true,
    "data": []
}*/
                                if (response.data['success']) {
                                  if (response.data['data'] != null) {
                                    for (var user in response.data['data']) {
                                      searchUsers
                                          .add(SearchUser.fromJson(user));
                                    }
                                    setState(() {
                                      loading = false;
                                    });
                                    return;
                                  }
                                  searchUsers = [];
                                  setState(() {});
                                }
                              } catch (e) {
                                setState(() {
                                  loading = false;
                                });
                                print(e);
                              }
                            }),
                      ]))),
            ),
          ];
        },
        body: loading
            ? Center(child: CircularProgressIndicator())
            : searchUsers.length > 0
                ? ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: searchUsers.length,
                    itemBuilder: (context, index) {
                      return AUserListTile(
                          user: searchUsers[index],
                          dioService: widget.dioService);
                    })
                : Container());
  }
}
