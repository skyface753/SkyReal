import 'package:client_flutter/bloc/auth_bloc.dart';
import 'package:client_flutter/pages/twofactor_settings.dart';
import 'package:client_flutter/services/dio_service.dart';
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
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  SettingsData? settingsData;

  _loadSettings() async {
    await DioService().getApi().get('user/settings').then((value) {
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
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    if (state is Authenticated) {
                      return ListTile(
                        title: Text('Avatar'),
                        subtitle: Text(settingsData!.avatar ?? 'No avatar'),
                        onTap: () async {
                          FilePickerResult? result =
                              await FilePicker.platform.pickFiles();

                          if (result != null) {
                            if (kIsWeb) {
                              // html.File file = html.File(result.files.single.bytes!, result.files.single.name);
                              FormData formData = FormData.fromMap({
                                'avatar': await MultipartFile.fromBytes(
                                    result.files.single.bytes!,
                                    filename: result.files.single.name)
                              });

                              await DioService()
                                  .getApi()
                                  .put('avatar/upload', data: formData)
                                  .then((value) {
                                final Map responseMap = value.data;
                                print("UPLOAD");
                                if (responseMap['success']) {
                                  print("UPLOAD SUCCESS");
                                  setState(() {
                                    settingsData!.avatar = responseMap['data']
                                        ['avatar']['generatedPath'];
                                    //TODO: update avatar in auth bloc
                                    // BlocProvider.of<AuthBloc>(context).add(
                                    //     ChangeAvatarRequested(
                                    //         settingsData!.avatar!));
                                    state.changeAvatar(settingsData!.avatar!);
                                  });
                                }
                              });
                            }
                          } else {
                            // User canceled the picker
                          }
                        },
                      );
                    } else {
                      return Container();
                    }
                  },
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
              ],
            ),
    );
  }
}
