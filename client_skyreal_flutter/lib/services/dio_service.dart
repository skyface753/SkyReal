// import 'package:dio/adapter_browser.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:skyreal/bloc/auth_bloc.dart';

class DioService {
  static String baseUrl = 'http://localhost:5000/api/';
  static String serverUrl = 'http://localhost:5000/api/';

  static Dio geBaseDio() {
    // var adapter = BrowserHttpClientAdapter();
    // adapter.withCredentials = true;
    return Dio(
      BaseOptions(
        baseUrl: baseUrl,
        receiveDataWhenStatusError: true,
        validateStatus: (status) {
          // All to 500 except 401
          return status! < 500 && status != 401;
        },
        headers: {
          "Accept": "application/json",
          'Content-type': 'application/json',
          'X-Requested-With': 'XMLHttpRequest',
        },
      ),
    );
    // ..httpClientAdapter = adapter;
  }

  Dio getApi(AuthState authState) {
    Dio dio = geBaseDio();

    dio.interceptors
        .add(InterceptorsWrapper(onRequest: (options, handler) async {
      final storage = new FlutterSecureStorage();
      String csrfToken = await storage.read(key: 'csrfToken') ?? '';
      String accessToken = await storage.read(key: 'accessToken') ?? '';
      options.headers['X-CSRF-TOKEN'] = csrfToken;
      options.headers['Authorization'] = 'Bearer $accessToken';
      // await storage.read(key: 'csrfToken').then((value) {
      //   print("Added csrfToken");
      //   options.headers['x-csrf-token'] = value;
      // });

      return handler.next(options);
      print(
        '${options.method} ${options.path}',
      );
      return handler.next(options);
    }, onResponse: (response, handler) {
      print(
        '${response.statusCode} ${response.statusMessage}',
      );
      return handler.next(response);
    }, onError: (DioError error, handler) async {
      print("Error status: ${error.response?.statusCode}");

      final Map errorData = error.response?.data;
      print(errorData['error']);
      print(error.response);
      // print(error.response);
      if (error.response?.statusCode == 401 &&
          errorData['message'] == 'jwt expired') {
        print("REFRESH ACCESS TOKEN");
        if (!await refreshToken(dio, authState)) {
          print("REFRESH TOKEN FAILED");
          return handler.next(error);
        }
        //create request with new access token
        final opts = new Options(
          method: error.requestOptions.method,
          extra: error.requestOptions.extra,
          headers: error.requestOptions.headers,
          contentType: error.requestOptions.contentType,
          responseType: error.requestOptions.responseType,
          listFormat: error.requestOptions.listFormat,
        );

        final cloneReq = await dio.request(error.requestOptions.path,
            options: opts,
            data: error.requestOptions.data,
            queryParameters: error.requestOptions.queryParameters);

        return handler.resolve(cloneReq);
      }
      print("ERROR in DIO");
      print(error);
      return handler.next(error);
    }));

    return dio;
  }

  Future<bool> refreshToken(Dio dio, AuthState authState) async {
    final storage = new FlutterSecureStorage();
    String? refreshToken = await storage.read(key: 'refreshToken');
    if (refreshToken == null) {
      print("REFRESH TOKEN NOT FOUND");
      return false;
    }
    Response refreshResponse = await dio
        .post('auth/refreshToken', data: {'refreshToken': refreshToken});
    if (refreshResponse.statusCode == 200) {
      print("REFRESH TOKEN SUCCESS");
      print(refreshResponse.data);
      final Map response = refreshResponse.data;
      await storage.write(
          key: 'accessToken', value: response['data']['accessToken']);
      if (authState is Authenticated) {
        authState.updateAccessToken(response['data']['accessToken']);
      }
      await storage.write(
          key: 'refreshToken', value: response['data']['refreshToken']);
      await storage.write(
          key: 'csrfToken', value: response['data']['csrfToken']);
      return true;
    }
    print("REFRESH TOKEN FAILED");
    return false;
  }

  Future<Response<dynamic>> _retry(
      RequestOptions requestOptions, Dio _dio) async {
    final options = new Options(
      method: requestOptions.method,
      headers: requestOptions.headers,
    );
    return _dio.request<dynamic>(requestOptions.path,
        data: requestOptions.data,
        queryParameters: requestOptions.queryParameters,
        options: options);
  }

  // static Future<Response> getData({
  //   required String url,
  //   required Map<String, dynamic> query,
  // }) async {
  //   return await dio.get(
  //     url,
  //     queryParameters: query,
  //   );
  // }
}
