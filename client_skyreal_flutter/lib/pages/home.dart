import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:skyreal/bloc/auth_bloc.dart';
import 'package:skyreal/components/appbar.dart';
import 'package:skyreal/components/ownPicture.dart';
import 'package:skyreal/components/showReal.dart';
import 'package:skyreal/components/showTakeRealContainer.dart';
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

  bool userHasOwnReal = false;

  Future<OwnReal?> _ownReal(AuthState authState) async {
    Dio dioService = DioService().getApi(authState);
    Response response = await dioService.get('reals/own');
    /*{
    "success": true,
    "data": {
        "real": {
            "id": 25,
            "userFk": 1,
            "frontPath": "uploads/reals/uploadedImages-1665064972108.54.03.png",
            "backPath": "uploads/reals/uploadedImages-1665064972112.56.05.png",
            "createdAt": "2022-10-06T12:02:52.000Z",
            "timespan": 11570
        }
    }
}*/
    // print(response.data);
    if (response.data['success']) {
      print(response.data['data']['real']);
      if (response.data['data']['real'] != null) {
        try {
          OwnReal ownReal = OwnReal.fromJson(response.data['data']['real']);
          userHasOwnReal = true;
          return ownReal;
        } catch (e) {
          print(e);
          return null;
        }
        return OwnReal.fromJson(response.data['data']['real']);
      } else {
        return null;
      }
      // return OwnReal.fromJson(response.data['data']['real']);
    } else {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    authBloc = BlocProvider.of<AuthBloc>(context);
    _getReals();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is Loading) {
          // Showing the loading indicator while the user is signing in
          return Center(
            child: CircularProgressIndicator(),
          );
        }
        if (state is Authenticated) {
          return Scaffold(
              appBar: CustomAppBar(
                title: 'SkyReal',
                authState: state,
              ),
              extendBodyBehindAppBar: true,
              body: RefreshIndicator(
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
                        final headerMaxWidth =
                            MediaQuery.of(context).size.width;

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
                                      stretchModes: [
                                        StretchMode.zoomBackground
                                      ],
                                      background: FutureBuilder(
                                        future: _ownReal(state),
                                        builder: (context, snapshot) {
                                          if (snapshot.hasData) {
                                            print("has data");
                                            return OwnPicture(
                                                snapshot.data!.backPath,
                                                snapshot.data!.frontPath,
                                                headerMaxWidth,
                                                state.authenticatedUser
                                                    .accessToken);
                                          } else {
                                            return TakeRealButton();
                                          }
                                        },
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
                                  itemWidth: itemWidth,
                                  userhasOwnReal: userHasOwnReal);
                            },
                          )))));
        }
        if (state is UnAuthenticated) {
          Future.microtask(() => Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => LoginPage()),
              (route) => false));
        }
        return Center(
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                  context, MaterialPageRoute(builder: (context) => LoginPage()),
                  (r) {
                return false;
              });
            },
            child: Text('Login'),
          ),
        );
      },
    );
  }
}
