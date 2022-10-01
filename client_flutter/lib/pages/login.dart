import 'package:client_flutter/bloc/auth_bloc.dart';
import 'package:client_flutter/pages/home.dart';
import 'package:client_flutter/pages/register.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:rounded_loading_button/rounded_loading_button.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';

class LoginPage extends StatefulWidget {
  static String routeName = '/login';

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  final RoundedLoadingButtonController _btnController =
      RoundedLoadingButtonController();
  _login() {
    try {
      BlocProvider.of<AuthBloc>(context).add(
        SignInRequested(_emailController.text, _passwordController.text),
      );
    } catch (e) {
      setState(() {
        _btnController.error();
      });
    }

    // print(_emailController.text);
    // print(_passwordController.text);
  }

  final GlobalKey<FormState> _key = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: BlocListener<AuthBloc, AuthState>(listener: (context, state) {
        if (state is Authenticated) {
          print("Authenticated - ${state}");
          // Navigating to the dashboard screen if the user is authenticated
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => HomePage()));
        }
        if (state is AuthError) {
          // Showing the error message if the user has entered invalid credentials
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.error)));
        }
      }, child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is Loading) {
            // Showing the loading indicator while the user is signing in
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if (state is UnAuthenticated) {
            // Showing the sign in form if the user is not authenticated
            return Center(
                child: Padding(
                    padding: EdgeInsets.all(10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        TextField(
                          controller: _emailController,
                          autofocus: true,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                          ),
                          onChanged: (value) => _btnController.reset(),
                        ),
                        TextField(
                          obscureText: true,
                          enableSuggestions: false,
                          autocorrect: false,
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                          ),
                          onChanged: (value) => _btnController.reset(),
                          onSubmitted: (value) => _login(),
                        ),
                        _btnController.currentState == ButtonState.error
                            ? Text('Invalid email or password')
                            : Container(),
                        RoundedLoadingButton(
                          controller: _btnController,
                          onPressed: () {
                            _login();
                          },
                          child: const Text('Login',
                              style: TextStyle(color: Colors.white)),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Don\'t have an account?',
                              style: TextStyle(fontSize: 25.0),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => RegisterPage()));
                              },
                              child: Text(
                                ' Sign Up',
                                style: TextStyle(
                                    fontSize: 25.0, color: Colors.blue),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )));
          } else if (state is OTPRequired) {
            return OtpTextField(
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
                BlocProvider.of<AuthBloc>(context).add(SignInRequested(
                    _emailController.text, _passwordController.text,
                    totpCode: verificationCode));
              }, // end onSubmit
            );
          }
          return Container();
        },
      )),
    );
  }
}
