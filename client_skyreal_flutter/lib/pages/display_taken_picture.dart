import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skyreal/bloc/auth_bloc.dart';
import 'package:skyreal/pages/home.dart';
import 'package:skyreal/services/dio_service.dart';

class DisplayPictureScreen extends StatefulWidget {
  final String backImagePath;
  final String frontImagePath;

  const DisplayPictureScreen({
    super.key,
    required this.backImagePath,
    required this.frontImagePath,
  });

  @override
  DisplayPictureScreenState createState() => DisplayPictureScreenState();
}

class DisplayPictureScreenState extends State<DisplayPictureScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Display the Picture'),
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is Loading) {
            return Center(
              child: CircularProgressIndicator(),
            );
          } else if (state is Authenticated) {
            return Column(
              children: [
                Expanded(
                  child: Image.file(File(widget.backImagePath)),
                ),
                Expanded(
                  child: Image.file(File(widget.frontImagePath)),
                ),
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
}
