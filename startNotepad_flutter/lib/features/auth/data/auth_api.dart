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

  Future<Response<dynamic>> getCurrentUserProfile() {
    return _client.request<dynamic>(
      '/api/ua/getCurrentUserProfile',
      method: 'GET',
    );
  }

  Future<Response<dynamic>> uploadFile({required String filePath}) async {
    final name = filePath.split('/').last;
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: name),
    });
    return _client.request<dynamic>(
      '/api/ufile/upload',
      method: 'POST',
      data: form,
    );
  }

  Future<Response<dynamic>> updateCurrentUserProfile({
    String? address,
    String? avatar,
    String? emailPhone,
    String? gender,
    String? nickname,
    String? signature,
    String? username,
  }) {
    final data = <String, dynamic>{};
    if (address != null) data['address'] = address;
    if (avatar != null) data['avatar'] = avatar;
    if (emailPhone != null) data['emailPhone'] = emailPhone;
    if (gender != null) data['gender'] = gender;
    if (nickname != null) data['nickname'] = nickname;
    if (signature != null) data['signature'] = signature;
    if (username != null) data['username'] = username;

    return _client.request<dynamic>(
      '/api/ua/updateCurrentUserProfile',
      method: 'PUT',
      data: data,
      headers: const <String, dynamic>{'Content-Type': 'application/json'},
    );
  }
}
