import 'package:skyreal/bloc/auth_bloc.dart';
import 'package:skyreal/pages/twofactor_settings.dart';
import 'package:skyreal/services/dio_service.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsData {
  String username;
  String email;
  String? avatar;
  bool twoFactorEnabled;

  SettingsData(this.username, this.email, this.avatar, this.twoFactorEnabled);
}

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  AuthBloc? authBloc;

  @override
  void initState() {
    super.initState();
    authBloc = BlocProvider.of<AuthBloc>(context);
    _loadSettings();
  }

  SettingsData? settingsData;

  _loadSettings() async {
    await DioService()
        .getApi(authBloc!.state)
        .get('user/settings')
        .then((value) {
      final Map responseMap = value.data;
      if (responseMap['success']) {
        setState(() {
          settingsData = SettingsData(
              responseMap['data']['username'],
              responseMap['data']['email'],
              responseMap['data']['avatar'],
              responseMap['data']['twoFactorEnabled']);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: settingsData == null
          ? Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                ListTile(
                  title: Text('Username'),
                  subtitle: Text(settingsData!.username),
                ),
                ListTile(
                  title: Text('Email'),
                  subtitle: Text(settingsData!.email),
                ),
                SwitchListTile(
                    value: settingsData!.twoFactorEnabled,
                    title: Text('Two Factor Authentication'),
                    onChanged: (value) {
                      Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      TwoFactorSettingsPage(isEnabled: !value)))
                          .then((value) => _loadSettings());
                    }),
                ListTile(
                  title: Text("Logout"),
                  onTap: () {
                    // Dialog
                    showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Text("Logout"),
                            content: Text("Are you sure you want to logout?"),
                            actions: [
                              TextButton(
                                  onPressed: () {
                                    Navigator.pop(context, false);
                                  },
                                  child: Text("Cancel")),
                              TextButton(
                                  onPressed: () {
                                    Navigator.pop(context, true);
                                    // authBloc!.add(LogoutWithNav(context));
                                  },
                                  child: Text("Logout")),
                            ],
                          );
                        }).then((value) {
                      if (value == true) {
                        authBloc!.add(SignOutRequested());
                        Navigator.pop(context);
                      }
                    });
                  },
                )
              ],
            ),
    );
  }
}
