import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skyreal/bloc/auth_bloc.dart';
import 'package:skyreal/services/dio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:qr_flutter/qr_flutter.dart';

class TwoFactorSettingsPage extends StatefulWidget {
  final bool isEnabled;

  const TwoFactorSettingsPage({Key? key, required this.isEnabled})
      : super(key: key);

  @override
  _TwoFactorSettingsPageState createState() => _TwoFactorSettingsPageState();
}

class _TwoFactorSettingsPageState extends State<TwoFactorSettingsPage> {
  AuthBloc? authBloc;

  @override
  void initState() {
    super.initState();
    authBloc = BlocProvider.of<AuthBloc>(context);
    // _loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Two Factor Settings'),
      ),
      body:
          widget.isEnabled ? _buildDisableTwoFactor() : _buildEnableTwoFactor(),
    );
  }

  TextEditingController _passwordEnableController = TextEditingController();
  String? twoFactorUrl;
  String? twoFactorSecretBase32;
  bool totpError = false;
  bool passwordError = false;
  Widget _buildEnableTwoFactor() {
    print("twoFactorUrl: $twoFactorUrl");
    print("twoFactorSecretBase32: $twoFactorSecretBase32");
    if (twoFactorSecretBase32 != null && twoFactorUrl != null) {
      return Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Scan the QR code with your authenticator app"),
          // Image.network(twoFactorUrl!),
          QrImage(
            data: twoFactorUrl!,
            version: QrVersions.auto,
            size: 200.0,
          ),
          Text("Or enter the following code manually"),
          Text(twoFactorSecretBase32!),
          Text("Enter the code from your authenticator app"),
          OtpTextField(
            autoFocus: true,
            numberOfFields: 6,
            borderColor: Color(0xFF512DA8),
            //set to true to show as box or false to show as dash
            showFieldAsBox: true,
            //runs when a code is typed in
            onCodeChanged: (String code) {
              //handle validation or checks here
            },
            //runs when every textfield is filled
            onSubmit: (String verificationCode) {
              DioService()
                  .getApi(authBloc!.state)
                  .post('auth/2fa/verify', data: {
                'password': _passwordEnableController.text,
                'currentCode': verificationCode,
              }).then((value) {
                print("Verfiy Return");
                print(value.data);
                if (value.data['success']) {
                  Navigator.pop(context);
                } else {
                  setState(() {
                    totpError = true;
                  });
                }
              }).catchError((error) {
                setState(() {
                  totpError = true;
                });
              });
            }, // end onSubmit
          ),
          totpError
              ? Text(
                  "Invalid code",
                  style: TextStyle(color: Colors.red),
                )
              : Container(),
        ],
      ));
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Enable Two Factor'),
          TextField(
            autofocus: true,
            controller: _passwordEnableController,
            decoration: InputDecoration(
              hintText: 'Password',
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              DioService()
                  .getApi(authBloc!.state)
                  .post('auth/2fa/enable', data: {
                'password': _passwordEnableController.text,
              }).then((value) {
                setState(() {
                  print(value.data);
                  final Map responseMap = value.data;
                  if (responseMap['success']) {
                    twoFactorUrl = responseMap['data']['url'];
                    twoFactorSecretBase32 = responseMap['data']['secretBase32'];
                  } else {
                    passwordError = true;
                  }
                });
              }).catchError((error) {
                setState(() {
                  passwordError = true;
                });
              });
            },
            child: Text('Enable'),
          ),
          passwordError
              ? Text(
                  "Invalid password",
                  style: TextStyle(color: Colors.red),
                )
              : Container(),
        ],
      ),
    );
  }

  TextEditingController _passwordDisableController = TextEditingController();
  TextEditingController _totpDisableController = TextEditingController();
  bool disableError = false;

  Widget _buildDisableTwoFactor() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Disable Two Factor'),
          TextField(
            autofocus: true,
            controller: _passwordDisableController,
            decoration: InputDecoration(
              hintText: 'Password',
            ),
          ),
          OtpTextField(
            autoFocus: true,
            numberOfFields: 6,
            borderColor: Color(0xFF512DA8),
            //set to true to show as box or false to show as dash
            showFieldAsBox: true,
            //runs when a code is typed in
            onCodeChanged: (String code) {
              //handle validation or checks here
            },
            //runs when every textfield is filled
            onSubmit: (String verificationCode) {
              if (_passwordDisableController.text.isEmpty) {
                setState(() {
                  disableError = true;
                });
                return;
              }
              _disableTotp(_passwordDisableController.text, verificationCode);
            }, // end onSubmit
          ),
          disableError
              ? Text("Please check your password and TOTP code",
                  style: TextStyle(color: Colors.red))
              : Container(),
        ],
      ),
    );
  }

  _disableTotp(String password, String totp) {
    DioService().getApi(authBloc!.state).post('auth/2fa/disable', data: {
      'password': password,
      'totpCode': totp,
    }).then((value) {
      print("Disable Return");
      print(value.data);
      if (value.data['success']) {
        Navigator.pop(context);
      } else {
        setState(() {
          disableError = true;
        });
      }
    }).catchError((error) {
      setState(() {
        disableError = true;
      });
    });
  }
}
