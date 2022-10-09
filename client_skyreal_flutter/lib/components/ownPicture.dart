import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:skyreal/components/showTakeRealContainer.dart';
import 'package:skyreal/pages/take_real.dart';
import 'package:skyreal/services/dio_service.dart';

class OwnPicture extends StatelessWidget {
  final String backPath;
  final String frontPath;
  final double headerMaxWidth;
  final String accessToken;

  OwnPicture(
      this.backPath, this.frontPath, this.headerMaxWidth, this.accessToken);

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: EdgeInsets.symmetric(horizontal: headerMaxWidth * 0.3),
        child: Stack(alignment: Alignment.topCenter, children: [
          CachedNetworkImage(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height * 0.5,
              httpHeaders: {'Authorization': 'Bearer $accessToken'},
              errorWidget: (context, url, error) {
                return TakeRealButton();
              },
              imageUrl: DioService.serverUrl +
                  backPath +
                  '?t=' +
                  DateTime.now().millisecondsSinceEpoch.toString(),
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
                  httpHeaders: {'Authorization': 'Bearer ${accessToken}'},
                  imageUrl: DioService.serverUrl +
                      frontPath +
                      '?t=' +
                      DateTime.now().millisecondsSinceEpoch.toString(),
                  errorWidget: (context, url, error) {
                    return Container();
                  },
                  fit: BoxFit.cover),
            ),
          )
          // ),
        ]));
  }
}
