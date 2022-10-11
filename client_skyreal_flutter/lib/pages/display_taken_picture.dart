import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skyreal/bloc/auth_bloc.dart';
import 'package:skyreal/components/showReal.dart';
import 'package:skyreal/pages/home.dart';
import 'package:skyreal/services/dio_service.dart';

class DisplayPictureScreen extends StatefulWidget {
  String backImagePath;
  String frontImagePath;
  bool? simulator;

  DisplayPictureScreen({
    super.key,
    required this.backImagePath,
    required this.frontImagePath,
    this.simulator,
  });

  @override
  DisplayPictureScreenState createState() => DisplayPictureScreenState();
}

class DisplayPictureScreenState extends State<DisplayPictureScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your SkyReal'),
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is Loading) {
            return Center(
              child: CircularProgressIndicator(),
            );
          } else if (state is Authenticated) {
            double itemWidth = MediaQuery.of(context).size.width;
            return Column(
              children: [
                ShowRealDragArea(
                    backImageChild: backImageWidget(),
                    itemWidth: itemWidth,
                    showFrontImage: showFrontImage,
                    child: frontImageWidget(itemWidth)),
                ElevatedButton(
                    onPressed: () async {
                      Dio dioService = DioService().getApi(state);
                      List<String> filePaths = [
                        widget.backImagePath,
                        widget.frontImagePath
                      ];
                      var formData = FormData();
                      for (var file in filePaths) {
                        formData.files.addAll([
                          MapEntry("uploadedImages",
                              await MultipartFile.fromFile(file)),
                        ]);
                      }
                      var response =
                          await dioService.put('reals/upload', data: formData);
                      print(response.data);
                      /*{success: true, data: {message: Real uploaded}}*/
                      if (response.data['success']) {
                        Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => HomePage()),
                            (route) => false);
                      }
                    },
                    child: Text("Upload"))
              ],
            );
          } else {
            return Center(
              child: Text("Something went wrong"),
            );
          }
        },
      ),
    );
  }

  bool showFrontImage = true;

  Widget backImageWidget() {
    return GestureDetector(
        onLongPress: () {
          setState(() {
            showFrontImage = false;
          });
        },
        onLongPressUp: () {
          setState(() {
            showFrontImage = true;
          });
        },
        child: widget.simulator == true
            ? Image.asset(widget.backImagePath)
            : Image.file(File(widget.backImagePath))
        // child: CachedNetworkImage(
        //   httpHeaders: {
        //     'Authorization':
        //         'Bearer ${widget.authState.authenticatedUser.accessToken}'
        //   },
        //   //TODO Remove dyn time to enable caching
        //   imageUrl: DioService.serverUrl + widget.real.backPath,
        //   imageBuilder: (context, imageProvider) => Container(
        //     // width: itemWidth,
        //     // height: 300,
        //     decoration: BoxDecoration(
        //       border: Border.all(width: 1),
        //       borderRadius: BorderRadius.circular(10),
        //     ),
        //     child: ClipRRect(
        //       borderRadius: BorderRadius.circular(10),
        //       child: Image(
        //         image: imageProvider,
        //         fit: BoxFit.cover,
        //       ),
        //     ),
        //   ),
        //   progressIndicatorBuilder: (context, url, downloadProgress) =>
        //       CircularProgressIndicator(value: downloadProgress.progress),
        //   errorWidget: (context, url, error) => Icon(Icons.error),
        // )
        );
  }

  Widget frontImageWidget(double itemWidth) {
    return SizedBox(
        width: itemWidth * 0.3,
        height: itemWidth * 0.3,
        child: GestureDetector(
            onTap: () {
              String backImageTemp = widget.backImagePath;
              setState(() {
                widget.backImagePath = widget.frontImagePath;
                widget.frontImagePath = backImageTemp;
              });
            },
            child: widget.simulator == true
                ? Image.asset(widget.frontImagePath)
                : Image.file(File(widget.frontImagePath))
            // child: CachedNetworkImage(
            //     // width: 300,
            //     // height: 300,
            //     httpHeaders: {
            //       'Authorization':
            //           'Bearer ${widget.authState.authenticatedUser.accessToken}'
            //     },
            //     imageUrl: DioService.serverUrl +
            //         widget.real.frontPath +
            //         '?t=' +
            //         onErrorCounter.toString(),
            //     imageBuilder: (context, imageProvider) => Container(
            //           decoration: BoxDecoration(
            //             border: Border.all(width: 5),
            //             borderRadius: BorderRadius.circular(20),
            //             image: DecorationImage(
            //               image: imageProvider,
            //               fit: BoxFit.cover,
            //             ),
            //           ),
            //         ),
            //     placeholder: (context, url) => CircularProgressIndicator(),
            //     errorWidget: (context, url, error) {
            //       onErrorCounter++;
            //       return Icon(Icons.error);
            //     }))
            ));
  }
}
