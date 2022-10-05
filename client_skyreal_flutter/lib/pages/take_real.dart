// A screen that allows users to take a picture using a given camera.
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:skyreal/pages/display_taken_picture.dart';

class TakePictureScreen extends StatefulWidget {
  const TakePictureScreen({
    super.key,
  });

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  int currentCamIndex = 0;
  bool hasTwoCameras = false;
  List<CameraDescription> camerasList = [];

  Future<void>? _initializeControllerFuture;
  CameraController? _controller;

  _initCurrentCam() async {
    if (!hasTwoCameras || camerasList.isEmpty) {
      return;
    }
    CameraDescription currentCameraDescription = camerasList[currentCamIndex];
    _controller = CameraController(
        currentCameraDescription, ResolutionPreset.medium,
        imageFormatGroup: ImageFormatGroup.jpeg);
    _initializeControllerFuture = _controller!.initialize();
  }

  _camsFirstInit() async {
    final cameras = await availableCameras();
    if (cameras.length > 1) {
      setState(() {
        hasTwoCameras = true;
        camerasList = cameras;
        _initCurrentCam();
      });
    } else {
      setState(() {
        hasTwoCameras = false;
        camerasList = [];
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _camsFirstInit();
  }

  @override
  Widget build(BuildContext context) {
    // Fill this out in the next steps.
    return Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            try {
              await _initializeControllerFuture;
              final firstImage = await _controller!.takePicture();
              CameraDescription? nextCam;
              if (currentCamIndex == 1) {
                nextCam = camerasList[0];
              } else {
                nextCam = camerasList[1];
              }
              _controller = CameraController(nextCam, ResolutionPreset.medium,
                  imageFormatGroup: ImageFormatGroup.jpeg);
              _initializeControllerFuture = _controller!.initialize();
              await _initializeControllerFuture;
              // Ensure Light
              await Future.delayed(Duration(seconds: 2));
              final secondImage = await _controller!.takePicture();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DisplayPictureScreen(
                    backImagePath: firstImage.path,
                    frontImagePath: secondImage.path,
                  ),
                ),
              );
            } catch (e) {
              print(e);
            }
//           try {
//             // Ensure that the camera is initialized.
//             await _backInitializeControllerFuture;
//             // await _frontInitializeControllerFuture;

// // Attempt to take a picture and get the file `image`
// // where it was saved.
//             final backImage = await _backController.takePicture();
//             // final frontImage = await _frontController.takePicture();

// // If the picture was taken, display it on a new screen.
//             if (!mounted) return;
//             Navigator.push(
//               context,
//               MaterialPageRoute(
//                 builder: (context) => DisplayPictureScreen(
// // Pass the automatically generated path to
// // the DisplayPictureScreen widget.
//                   backImagePath: backImage.path,
//                   // frontImagePath: frontImage.path,
//                 ),
//               ),
//             );
//           } catch (e) {
// // If an error occurs, log the error to the console.
//             print(e);
//           }
          },
          child: Icon(Icons.camera_alt),
        ),
        body: FutureBuilder<void>(
          future: _initializeControllerFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              if (!hasTwoCameras ||
                  camerasList.isEmpty ||
                  _controller == null) {
                return Center(child: Text('No cameras found'));
              }
              // If the Future is complete, display the preview.
              return CameraPreview(_controller!);
            } else {
              // Otherwise, display a loading indicator.
              return const Center(child: CircularProgressIndicator());
            }
          },
        ));
  }
}
