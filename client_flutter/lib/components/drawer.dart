import 'package:client_flutter/bloc/auth_bloc.dart';
import 'package:client_flutter/pages/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DrawerWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
        child: BlocBuilder<AuthBloc, AuthState>(builder: (context, state) {
      return ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            child: state is Authenticated
                ? Column(
                    children: [
                      state.authenticatedUser.avatar != null
                          ? Image.network(
                              'http://localhost:5000/' +
                                  state.authenticatedUser.avatar!,
                              width: 100,
                              height: 100,
                            )
                          : Container(),
                      Text(
                        state.authenticatedUser.username,
                        style: TextStyle(color: Colors.white, fontSize: 25),
                      ),
                    ],
                  )
                : Text('Not logged in'),
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
          ),
          ListTile(
            title: Text('Item 1'),
            onTap: () {
              // Update the state of the app.
              // ...
              // Then close the drawer.
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Settings'),
            onTap: () {
              Navigator.push(context,
                      MaterialPageRoute(builder: (context) => SettingsPage()))
                  .then((value) => Navigator.pop(context));
              // Update the state of the app.
              // ...
              // Then close the drawer.
            },
          ),
        ],
      );
    }));
  }
}
