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
                // child: SafeArea(
                child: CustomScrollView(slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(
                            height:
                                Size.fromHeight(kToolbarHeight).height + 50),
                        // OwnPicture("URL", 200),
                        Text('Welcome ${state.authenticatedUser.username}'),
                        SizedBox(height: 200),
                        SizedBox(
                            height: 400,
                            width: double.infinity,
                            child: ListView.builder(
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: reals.length,
                              shrinkWrap: true,
                              itemBuilder: (context, index) {
                                return Container(
                                  // height: 100,
                                  // color: Colors.red,
                                  width: double.infinity,
                                  child: Column(children: [
                                    Stack(
                                      children: [
                                        CachedNetworkImage(
                                          imageUrl: DioService.serverUrl +
                                              reals[index].backPath,
                                          progressIndicatorBuilder: (context,
                                                  url, downloadProgress) =>
                                              CircularProgressIndicator(
                                                  value: downloadProgress
                                                      .progress),
                                          errorWidget: (context, url, error) =>
                                              Icon(Icons.error),
                                        ),
                                        SizedBox(
                                          height: 50,
                                          width: 100,
                                          child: Align(
                                            alignment: Alignment.topLeft,
                                            child: CachedNetworkImage(
                                              imageUrl: DioService.serverUrl +
                                                  reals[index].frontPath,
                                              placeholder: (context, url) =>
                                                  CircularProgressIndicator(),
                                              errorWidget:
                                                  (context, url, error) =>
                                                      Icon(Icons.error),
                                            ),
                                          ),
                                        )
                                      ],
                                    ),
                                    Text(reals[index].username),
                                  ]),
                                );
                              },
                            ))
                      ],
                    ),
                  )
                ]));
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
