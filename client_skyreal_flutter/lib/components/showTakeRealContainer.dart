import 'package:flutter/material.dart';
import 'package:skyreal/pages/display_taken_picture.dart';
import 'package:skyreal/pages/take_real.dart';

class TakeRealButton extends StatelessWidget {
  const TakeRealButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: 100,
        height: 100,
        child: Center(
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => TakePictureScreen()));
            },
            onLongPress: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => DisplayPictureScreen(
                            backImagePath: 'assets/images/simulator-1.png',
                            frontImagePath: 'assets/images/simulator-2.png',
                            simulator: true,
                          )));
            },
            child: Text('Post your Real'),
          ),
        ));
  }
}
