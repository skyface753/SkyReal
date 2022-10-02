import 'package:client_flutter/pages/friends.dart';
import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const CustomAppBar({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      centerTitle: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {},
        ),
      ],
      leading: IconButton(
        icon: Icon(Icons.people),
        onPressed: () {
          Navigator.push(
            context,
            // Slide from left to right
            PageRouteBuilder(
              pageBuilder: (context, animation1, animation2) => FriendsPage(),
              transitionsBuilder: (context, animation1, animation2, child) =>
                  SlideTransition(
                position: Tween(begin: Offset(-1, 0), end: Offset(0, 0))
                    .animate(animation1),
                child: child,
              ),
              transitionDuration: const Duration(milliseconds: 200),
            ),
          );
        },
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
