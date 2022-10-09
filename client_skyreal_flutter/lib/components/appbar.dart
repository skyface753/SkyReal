import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_profile_picture/flutter_profile_picture.dart';
import 'package:skyreal/bloc/auth_bloc.dart';
import 'package:skyreal/pages/friends.dart';
import 'package:skyreal/pages/login.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:skyreal/pages/settings.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Authenticated authState;

  const CustomAppBar({Key? key, required this.title, required this.authState})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      centerTitle: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      actions: [
        InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SettingsPage(),
            ),
          ),
          child: ProfilePicture(
              name: authState.authenticatedUser.username,
              radius: 25,
              fontsize: 17),
        ),
        // IconButton(
        //   icon: const Icon(Icons.settings),
        //   onPressed: () {},
        // ),
        // Logout
        // IconButton(
        //   icon: const Icon(Icons.logout),
        //   onPressed: () async {
        //     BlocProvider.of<AuthBloc>(context).add(SignOutRequested());
        //   },
        // ),
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
