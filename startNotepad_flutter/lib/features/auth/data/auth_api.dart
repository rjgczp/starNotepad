import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';

class AuthApi {
  final ApiClient _client;

  AuthApi(this._client);

  Future<Response<dynamic>> login({
    required String username,
    required String password,
    required String deviceId,
  }) {
    return _client.request<dynamic>(
      '/api/ua/login',
      method: 'POST',
      data: <String, dynamic>{
        'username': username,
        'password': password,
        'deviceId': deviceId,
      },
      headers: const <String, dynamic>{'Content-Type': 'application/json'},
    );
  }

  Future<Response<dynamic>> register({
    required String username,
    required String emailPhone,
    required String password,
    required String emailCode,
    required String nickname,
    required String avatar,
    required String gender,
    required String address,
    required String signature,
    required String deviceId,
  }) {
    return _client.request<dynamic>(
      '/api/ua/register',
      method: 'POST',
      data: <String, dynamic>{
        'username': username,
        'emailPhone': emailPhone,
        'password': password,
        'emailCode': emailCode,
        'nickname': nickname,
        'avatar': avatar,
        'gender': gender,
        'address': address,
        'signature': signature,
        'deviceId': deviceId,
      },
      headers: const <String, dynamic>{'Content-Type': 'application/json'},
    );
  }

  Future<Response<dynamic>> sendRegisterEmailCode({required String email}) {
    return _client.request<dynamic>(
      '/api/ua/sendRegisterEmailCode',
      method: 'POST',
      data: <String, dynamic>{'email': email},
      headers: const <String, dynamic>{'Content-Type': 'application/json'},
    );
  }

  Future<Response<dynamic>> loginVerify({
    required String challengeId,
    required String emailCode,
    required String deviceId,
  }) {
    return _client.request<dynamic>(
      '/api/ua/loginVerify',
      method: 'POST',
      data: <String, dynamic>{
        'challengeId': challengeId,
        'emailCode': emailCode,
        'deviceId': deviceId,
      },
      headers: const <String, dynamic>{'Content-Type': 'application/json'},
    );
  }

  Future<Response<dynamic>> sendChangePasswordEmailCode({
    required String username,
    required String emailPhone,
    required String deviceId,
  }) {
    return _client.request<dynamic>(
      '/api/ua/sendChangePasswordEmailCode',
      method: 'POST',
      data: <String, dynamic>{
        'username': username,
        'emailPhone': emailPhone,
        'deviceId': deviceId,
      },
      headers: const <String, dynamic>{'Content-Type': 'application/json'},
    );
  }

  Future<Response<dynamic>> changePassword({
    required String username,
    required String emailPhone,
    required String newPassword,
    required String emailCode,
    required String deviceId,
  }) {
    return _client.request<dynamic>(
      '/api/ua/changePassword',
      method: 'POST',
      data: <String, dynamic>{
        'username': username,
        'emailPhone': emailPhone,
        'newPassword': newPassword,
        'emailCode': emailCode,
        'deviceId': deviceId,
      },
      headers: const <String, dynamic>{'Content-Type': 'application/json'},
    );
  }
}
