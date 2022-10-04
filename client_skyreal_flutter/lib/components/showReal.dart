import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_profile_picture/flutter_profile_picture.dart';
import 'package:skyreal/bloc/auth_bloc.dart';
import 'package:skyreal/models/reals.dart';
import 'package:skyreal/services/dio_service.dart';

class ShowReal extends StatefulWidget {
  Real real;
  Authenticated authState;
  double itemWidth;
  ShowReal(
      {Key? key,
      required this.real,
      required this.authState,
      required this.itemWidth})
      : super(key: key);

  @override
  _ShowRealState createState() => _ShowRealState();
}

class _ShowRealState extends State<ShowReal> {
  bool backgroundImageHolded = false;
  bool frontImageHolded = false;

  int onErrorCounter =
      0; // Incremented when an error occurs -> Refreshes the image

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.only(top: 20),
        child: Column(children: [
          Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                  padding: EdgeInsets.only(left: 10, bottom: 10),
                  child: Row(children: [
                    ProfilePicture(
                      name: widget.real.username,
                      radius: 25,
                      fontsize: 17,
                    ),
                    Padding(
                        padding: EdgeInsets.only(left: 10),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(widget.real.username),
                              Text(widget.real.createdAt)
                            ]))
                  ]))),
          Stack(
            children: [
              GestureDetector(
                onLongPress: () {
                  setState(() {
                    backgroundImageHolded = true;
                  });
                },
                onLongPressUp: () {
                  setState(() {
                    backgroundImageHolded = false;
                  });
                },
                child: CachedNetworkImage(
                  httpHeaders: {
                    'Authorization':
                        'Bearer ${widget.authState.authenticatedUser.accessToken}'
                  },
                  //TODO Remove dyn time to enable caching
                  imageUrl: DioService.serverUrl + widget.real.backPath,
                  imageBuilder: (context, imageProvider) => Container(
                    // width: itemWidth,
                    // height: 300,
                    decoration: BoxDecoration(
                      border: Border.all(width: 1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image(
                        image: imageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  progressIndicatorBuilder: (context, url, downloadProgress) =>
                      CircularProgressIndicator(
                          value: downloadProgress.progress),
                  errorWidget: (context, url, error) => Icon(Icons.error),
                ),
              ),
              !backgroundImageHolded
                  ? SizedBox(
                      height: widget.itemWidth * 0.3,
                      width: widget.itemWidth * 0.3,
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(10, 10, 0, 0),
                          child: CachedNetworkImage(
                              httpHeaders: {
                                'Authorization':
                                    'Bearer ${widget.authState.authenticatedUser.accessToken}'
                              },
                              imageUrl: DioService.serverUrl +
                                  widget.real.frontPath +
                                  '?t=' +
                                  onErrorCounter.toString(),
                              imageBuilder: (context, imageProvider) =>
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(width: 5),
                                      borderRadius: BorderRadius.circular(20),
                                      image: DecorationImage(
                                        image: imageProvider,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                              placeholder: (context, url) =>
                                  CircularProgressIndicator(),
                              errorWidget: (context, url, error) {
                                onErrorCounter++;
                                return Icon(Icons.error);
                              }),
                        ),
                      ))
                  : Container()
            ],
          ),
        ]));
  }
}
