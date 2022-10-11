import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_profile_picture/flutter_profile_picture.dart';
import 'package:skyreal/bloc/auth_bloc.dart';
import 'package:skyreal/components/showTakeRealContainer.dart';
import 'package:skyreal/models/reals.dart';
import 'package:skyreal/pages/take_real.dart';
import 'package:skyreal/services/dio_service.dart';

class ShowReal extends StatefulWidget {
  Real real;
  Authenticated authState;
  double itemWidth;
  bool userhasOwnReal;
  ShowReal(
      {Key? key,
      required this.real,
      required this.authState,
      required this.itemWidth,
      required this.userhasOwnReal})
      : super(key: key);

  @override
  _ShowRealState createState() => _ShowRealState();
}

class _ShowRealState extends State<ShowReal> {
  // bool backgroundImageHolded = false;
  bool showFrontImage = true;
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
          !widget.userhasOwnReal
              ? blurredImageWithButton()
              : ShowRealDragArea(
                  child: frontImageWidget(),
                  backImageChild: backImageWidget(),
                  itemWidth: widget.itemWidth,
                  showFrontImage: showFrontImage)
        ]));
  }

  Widget blurredImageWithButton() {
    return SizedBox(
      height: 200,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            DioService.serverUrl +
                widget.real.backPath +
                '?t=' +
                DateTime.now().millisecondsSinceEpoch.toString(),
            headers: {
              'Authorization':
                  'Bearer ${widget.authState.authenticatedUser.accessToken}'
            },
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey,
              );
            },
          ),
          ClipRRect(
            // Clip it cleanly.
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                  color: Colors.grey.withOpacity(0.1),
                  alignment: Alignment.center,
                  child: TakeRealButton()),
            ),
          ),
        ],
      ),
    );
  }

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
              CircularProgressIndicator(value: downloadProgress.progress),
          errorWidget: (context, url, error) => Icon(Icons.error),
        ));
  }

  Widget frontImageWidget() {
    return SizedBox(
        height: widget.itemWidth * 0.3,
        width: widget.itemWidth * 0.3,
        child: GestureDetector(
            onTap: () {
              String backImageTemp = widget.real.backPath;
              setState(() {
                widget.real.backPath = widget.real.frontPath;
                widget.real.frontPath = backImageTemp;
              });
            },
            child: CachedNetworkImage(
                // width: 300,
                // height: 300,
                httpHeaders: {
                  'Authorization':
                      'Bearer ${widget.authState.authenticatedUser.accessToken}'
                },
                imageUrl: DioService.serverUrl +
                    widget.real.frontPath +
                    '?t=' +
                    onErrorCounter.toString(),
                imageBuilder: (context, imageProvider) => Container(
                      decoration: BoxDecoration(
                        border: Border.all(width: 5),
                        borderRadius: BorderRadius.circular(20),
                        image: DecorationImage(
                          image: imageProvider,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                placeholder: (context, url) => CircularProgressIndicator(),
                errorWidget: (context, url, error) {
                  onErrorCounter++;
                  return Icon(Icons.error);
                })));
  }
}

class ShowRealDragArea extends HookWidget {
  final Widget child;
  final Widget backImageChild;
  final double itemWidth;
  final bool showFrontImage;

  const ShowRealDragArea(
      {Key? key,
      required this.child,
      required this.backImageChild,
      required this.itemWidth,
      required this.showFrontImage})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final position = useState(Offset(10, 10));
    // final prevScale = useState(1.0);
    // final scale = useState(1.0);
    return SizedBox(
        height: itemWidth,
        width: itemWidth,
        child: GestureDetector(
          // onScaleUpdate: (details) =>
          //     scale.value = prevScale.value * details.scale,
          // onScaleEnd: (_) => prevScale.value = scale.value,
          child: Stack(
            children: [
              backImageChild,
              showFrontImage
                  ? Positioned(
                      left: position.value.dx,
                      top: position.value.dy,
                      child: Draggable(
                        maxSimultaneousDrags: 1,
                        feedback: child,
                        childWhenDragging: Opacity(opacity: .3, child: null),
                        onDragEnd: (details) {
                          RenderBox? renderBox =
                              context.findRenderObject() as RenderBox?;
                          Offset newOffset =
                              renderBox!.globalToLocal(details.offset);
                          print(itemWidth.toString() +
                              " " +
                              newOffset.toString());
                          if (newOffset.dx < 0) {
                            newOffset = Offset(0, newOffset.dy);
                          }
                          if (newOffset.dy < 0) {
                            newOffset = Offset(newOffset.dx, 0);
                          }
                          if (newOffset.dx > itemWidth) {
                            newOffset = Offset(itemWidth, newOffset.dy);
                          }
                          if (newOffset.dy > itemWidth) {
                            newOffset = Offset(newOffset.dx, itemWidth);
                          }
                          position.value = newOffset;
                        },
                        child: child,
                      ),
                    )
                  : Container()
            ],
          ),
        ));
  }
}
