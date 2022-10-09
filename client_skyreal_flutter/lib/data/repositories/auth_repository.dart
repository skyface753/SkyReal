import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:skyreal/services/dio_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserState {
  int id;
  String username;
  String email;
  int roleFk;
  String? avatar;
  String accessToken;
  UserState(this.id, this.username, this.email, this.roleFk, this.avatar,
      this.accessToken);
  // From Json
  factory UserState.fromJson(Map<String, dynamic> json) {
    return UserState(json['id'], json['username'], json['email'],
        json['roleFk'], json['avatar'], json['accessToken']);
  }
}

class AuthRepository {
  Future<Object?> signIn(
      {required String username,
      required String password,
      String? totpCode}) async {
    var resp = await DioService.geBaseDio().post('auth/login', data: {
      'username': username,
      'password': password,
      'totpCode': totpCode
    });
    if (resp.statusCode == 400 && resp.data['message'] == '2FA required') {
      return "2FA";
    }
    final Map responseMap = resp.data;
    if (responseMap['success']) {
      final Map data = responseMap['data'];
      await writeData(data: data);
      final Map userData = data['user'];
      UserState userState = UserState(
          userData['id'],
          userData['username'],
          userData['email'],
          userData['roleFk'],
          userData['avatar'],
          data['accessToken']);
      await OneSignal.shared.setExternalUserId(userState.id.toString());
      return userState;
    } else {
      print(responseMap);
      throw Exception(responseMap['message'] + "UDJWF");
    }
  }

  Future<bool> changeAvatar(String? avatar) async {
    // Get old state
    final storage = new FlutterSecureStorage();
    await storage.write(key: 'avatar', value: avatar!);
    return true;
  }

  Future<void> writeData({required Map data}) async {
    const storage = FlutterSecureStorage();
    await storage.write(key: 'accessToken', value: data['accessToken']);
    await storage.write(key: 'refreshToken', value: data['refreshToken']);
    await storage.write(key: 'csrfToken', value: data['csrfToken']);
    await storage.write(key: 'userId', value: data['user']['id'].toString());
    await storage.write(key: 'username', value: data['user']['username']);
    await storage.write(key: 'email', value: data['user']['email']);
    await storage.write(
        key: 'roleFk', value: data['user']['roleFk'].toString());
    await storage.write(key: 'avatar', value: data['user']['avatar']);
  }

  Future<void> clearData() async {
    const storage = FlutterSecureStorage();

    storage.deleteAll();
  }

  Future<UserState?> signUp(
      {required String email,
      required String password,
      required String username}) async {
    var resp = await DioService.geBaseDio().put('auth/register', data: {
      'email': email,
      'password': password,
      'username': username,
    });
    final Map responseMap = resp.data;
    if (responseMap['success']) {
      final Map data = responseMap['data'];
      await writeData(data: data);
      final Map userData = data['user'];
      UserState userState = UserState(
          userData['id'],
          userData['username'],
          userData['email'],
          userData['roleFk'],
          userData['avatar'],
          data['accessToken']);
      return userState;
    } else {
      throw Exception(responseMap['message']);
    }

    // .then((value) {
    //   final Map response = value.data;
    //   if (response['success']) {
    //     print('Register Success');
    //     final Map data = response['data'];
    //     writeData(data: data);
    //     return data['user'];
    //   } else {
    //     throw Exception("Something went wrong");
    //   }
    // }).catchError((error) {
    //   throw Exception("Register Failed");
    // });
    // UserState user = UserState(response['id'], response['username'],
    //     response['email'], response['roleFk'], response['avatar'],
    // return user;
    //     .signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    try {
      String? refreshToken =
          await FlutterSecureStorage().read(key: 'refreshToken');
      await DioService.geBaseDio().post('auth/logout', data: {
        'refreshToken': refreshToken,
      }).then((value) {});
      OneSignal.shared.removeExternalUserId();

      await clearData();
    } catch (e) {
      print(e);
      OneSignal.shared.removeExternalUserId();
      await clearData();
    }
  }

  Future<UserState?> isSignedIn() async {
    const storage = FlutterSecureStorage();
    String? accessToken = await storage.read(key: 'accessToken');
    String? refreshToken = await storage.read(key: 'refreshToken');
    String? csrfToken = await storage.read(key: 'csrfToken');
    String? userId = await storage.read(key: 'userId');
    String? username = await storage.read(key: 'username');
    String? email = await storage.read(key: 'email');
    String? roleFk = await storage.read(key: 'roleFk');
    String? avatar = await storage.read(key: 'avatar');
    if (accessToken != null &&
        refreshToken != null &&
        csrfToken != null &&
        userId != null &&
        username != null &&
        email != null &&
        roleFk != null) {
      print("User is signed in");
      return UserState(int.parse(userId), username, email, int.parse(roleFk),
          avatar, accessToken);
    } else {
      return null;
    }
  }
}
