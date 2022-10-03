import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:client_flutter/bloc/auth_bloc.dart';
import 'package:client_flutter/components/appbar.dart';
import 'package:client_flutter/components/ownPicture.dart';
import 'package:client_flutter/pages/login.dart';
import 'package:client_flutter/services/dio_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:client_flutter/models/reals.dart';
import 'package:flutter_profile_picture/flutter_profile_picture.dart';

class HomePage extends StatefulWidget {
  static String routeName = '/home';
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Dio dio = DioService().getApi();
  List<Real> reals = [];
  Future<void> _getReals() async {
    dio.get('reals').then((response) {
      print(response.data);
      /*{
    "success": true,
    "data": {
        "reals": [] // array of reals
	    }
	}*/
      if (response.data['success']) {
        setState(() {
          reals = response.data['data']['reals']
              .map<Real>((real) => Real.fromJson(real))
              .toList();
          for (var real in reals) {
            print(real.frontPath);
          }
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _getReals();
  }

  Future<void> _loadData() async {
    await dio.get('auth/status').then((value) {
      final Map responseMap = value.data;
      if (responseMap['success']) {
        print(responseMap['data']);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'SkyReal',
      ),
      extendBodyBehindAppBar: true,
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
                onRefresh: _getReals,
                notificationPredicate: (notification) {
                  // with NestedScrollView local(depth == 2) OverscrollNotification are not sent
                  return notification.depth == 1;
                },
                displacement: 100,
                // child: SafeArea(
                child: NestedScrollView(
                    headerSliverBuilder:
                        (BuildContext context, bool innerBoxIsScrolled) {
                      return <Widget>[
                        SliverPadding(
                            padding: EdgeInsets.only(
                                top: Size.fromHeight(kToolbarHeight).height +
                                    50),
                            sliver: SliverAppBar(
// Own Real
                                // expandedHeight: 200.0,
                                floating: false,
                                pinned: false,
                                flexibleSpace: FlexibleSpaceBar(
                                    centerTitle: true,
                                    background: Padding(
                                      padding:
                                          EdgeInsets.fromLTRB(50, 10, 50, 10),
                                      child: Stack(children: [
                                        CachedNetworkImage(
                                            httpHeaders: {
                                              'Authorization':
                                                  'Bearer ${state.authenticatedUser.accessToken}'
                                            },
                                            imageUrl: DioService.serverUrl +
                                                'reals/own/front',
                                            fit: BoxFit.cover),
                                        Align(
                                          alignment: Alignment.topLeft,
                                          child: Container(
                                            height: 50,
                                            width: 50,
                                            child: CachedNetworkImage(
                                                httpHeaders: {
                                                  'Authorization':
                                                      'Bearer ${state.authenticatedUser.accessToken}'
                                                },
                                                imageUrl: DioService.serverUrl +
                                                    'reals/own/back',
                                                fit: BoxFit.cover),
                                          ),
                                        ),
                                      ]),
                                    )

                                    // imageUrl:
                                    // 'https://picsum.photos/250?image=9',
                                    // fit: BoxFit.cover,
                                    // placeholder: (context, url) =>
                                    // CircularProgressIndicator(),
                                    // errorWidget: (context, url, error) =>
                                    // Icon(Icons.error),
                                    // )),
                                    )))
                      ];
                    },
                    body: ListView.builder(
                      itemCount: reals.length,
                      itemBuilder: (context, index) {
                        return Padding(
                            padding: EdgeInsets.only(top: 20),
                            child: Column(children: [
                              Align(
                                  alignment: Alignment.centerLeft,
                                  child: Padding(
                                      padding:
                                          EdgeInsets.only(left: 10, bottom: 10),
                                      child: Row(children: [
                                        ProfilePicture(
                                          name: reals[index].username,
                                          radius: 25,
                                          fontsize: 17,
                                        ),
                                        Padding(
                                            padding: EdgeInsets.only(left: 10),
                                            child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                children: [
                                                  Text(reals[index].username),
                                                  Text(reals[index].createdAt)
                                                ]))
                                      ]))),
                              Stack(
                                children: [
                                  CachedNetworkImage(
                                    httpHeaders: {
                                      'Authorization':
                                          'Bearer ${state.authenticatedUser.accessToken}'
                                    },
                                    imageUrl: DioService.serverUrl +
                                        reals[index].backPath +
                                        '?v=' +
                                        DateTime.now()
                                            .millisecondsSinceEpoch
                                            .toString(),
                                    progressIndicatorBuilder: (context, url,
                                            downloadProgress) =>
                                        CircularProgressIndicator(
                                            value: downloadProgress.progress),
                                    errorWidget: (context, url, error) =>
                                        Icon(Icons.error),
                                  ),
                                  SizedBox(
                                    height: 50,
                                    width: 100,
                                    child: Align(
                                      alignment: Alignment.topLeft,
                                      child: CachedNetworkImage(
                                        httpHeaders: {
                                          'Authorization':
                                              'Bearer ${state.authenticatedUser.accessToken}'
                                        },
                                        imageUrl: DioService.serverUrl +
                                            reals[index].frontPath +
                                            '?${DateTime.now().millisecondsSinceEpoch.toString()}',
                                        placeholder: (context, url) =>
                                            CircularProgressIndicator(),
                                        errorWidget: (context, url, error) =>
                                            Icon(Icons.error),
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ]));
                      },
                    )));
          }

          // print(state);
          return Center(
            child: Text("Not Authenticated - ERROR"),
          );
        },
      ),
    );
  }
}
