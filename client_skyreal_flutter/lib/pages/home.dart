import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:skyreal/bloc/auth_bloc.dart';
import 'package:skyreal/components/appbar.dart';
import 'package:skyreal/components/ownPicture.dart';
import 'package:skyreal/components/showReal.dart';
import 'package:skyreal/pages/login.dart';
import 'package:skyreal/pages/take_real.dart';
import 'package:skyreal/services/dio_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skyreal/models/reals.dart';
import 'package:flutter_profile_picture/flutter_profile_picture.dart';

class HomePage extends StatefulWidget {
  static String routeName = '/home';
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DioService dioService = DioService();
  AuthBloc? authBloc;
  List<Real> reals = [];

  Future<void> _getReals() async {
    if (authBloc != null) {
      Dio dio = dioService.getApi(authBloc!.state);
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
  }

  @override
  void initState() {
    super.initState();
    authBloc = BlocProvider.of<AuthBloc>(context);
    _getReals();
  }

  // Future<void> _loadData() async {
  //   await dio.get('auth/status').then((value) {
  //     final Map responseMap = value.data;
  //     if (responseMap['success']) {
  //       print(responseMap['data']);
  //     }
  //   });
  // }
  //TODO ADD Function
  bool ownRealEmpty = true;

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
                      final headerMaxWidth = MediaQuery.of(context).size.width;

                      return <Widget>[
                        SliverPadding(
                            padding: EdgeInsets.only(
                                top: Size.fromHeight(kToolbarHeight).height +
                                    50),
                            sliver: SliverAppBar(
                                stretch: true,
                                backgroundColor: Colors.transparent,
                                // expandedHeight: 200.0,
                                floating: false,
                                pinned: false,
                                snap: false,
                                flexibleSpace: FlexibleSpaceBar(
                                    centerTitle: true,
                                    stretchModes: [StretchMode.zoomBackground],
                                    background: Container(
                                      margin: EdgeInsets.symmetric(
                                          horizontal: headerMaxWidth * 0.3),
                                      child: Stack(
                                          alignment: Alignment.topCenter,
                                          children: [
                                            CachedNetworkImage(
                                                width: MediaQuery.of(context)
                                                    .size
                                                    .width,
                                                httpHeaders: {
                                                  'Authorization':
                                                      'Bearer ${state.authenticatedUser.accessToken}'
                                                },
                                                errorWidget:
                                                    (context, url, error) {
                                                  ownRealEmpty = true;
                                                  return Container(
                                                      width: 100,
                                                      height: 100,
                                                      child: Center(
                                                        child: ElevatedButton(
                                                          onPressed: () {
                                                            Navigator.push(
                                                                context,
                                                                MaterialPageRoute(
                                                                    builder:
                                                                        (context) =>
                                                                            TakePictureScreen()));
                                                          },
                                                          child:
                                                              Text('Add Real'),
                                                        ),
                                                      ));
                                                },
                                                imageUrl: DioService.serverUrl +
                                                    'reals/own/back' +
                                                    '?t=' +
                                                    DateTime.now()
                                                        .millisecondsSinceEpoch
                                                        .toString(),
                                                fit: BoxFit.fill),
                                            // Positioned(
                                            //   top: 0,
                                            //   left: 0,
                                            //   child:

                                            // child: Container(

                                            Positioned(
                                              left: 0,
                                              top: 0,
                                              child: Container(
                                                height: 50,
                                                width: 50,
                                                child: CachedNetworkImage(
                                                    httpHeaders: {
                                                      'Authorization':
                                                          'Bearer ${state.authenticatedUser.accessToken}'
                                                    },
                                                    imageUrl: DioService
                                                            .serverUrl +
                                                        'reals/own/front' +
                                                        '?t=' +
                                                        DateTime.now()
                                                            .millisecondsSinceEpoch
                                                            .toString(),
                                                    errorWidget:
                                                        (context, url, error) {
                                                      ownRealEmpty = true;
                                                      return Container();
                                                    },
                                                    fit: BoxFit.cover),
                                              ),
                                            )
                                            // ),
                                          ]),
                                    ))))
                      ];
                    },
                    body: MediaQuery.removePadding(
                        removeTop: true,
                        context: context,
                        child: ListView.builder(
                          itemCount: reals.length,
                          itemBuilder: (context, index) {
                            final double itemWidth =
                                MediaQuery.of(context).size.width;
                            return ShowReal(
                                real: reals[index],
                                authState: state,
                                itemWidth: itemWidth);
                          },
                        ))));
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
