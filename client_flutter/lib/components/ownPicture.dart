import 'package:flutter/material.dart';

class OwnPicture extends StatelessWidget {
  final String url;
  final double size;

  OwnPicture(this.url, this.size);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        image: DecorationImage(
          fit: BoxFit.fill,
          image: NetworkImage(url),
        ),
      ),
    );
  }
}
