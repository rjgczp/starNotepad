import '../../auth/domain/auth_repository.dart';
import '../../../core/errors/app_exception.dart';
import '../../../tools/network.dart';
import '../../../tools/system_tip_broadcast.dart';
import '../../../tools/localData.dart';
import 'auth_api.dart';

class AuthRepositoryImpl implements AuthRepository {
  static const String tokenKey = 'token';
  static const String tokenExpiresAtKey = 'token_expires_at';
  static const String userDisplayNameKey = 'user_display_name';
  static const String userAvatarPathKey = 'user_avatar_path';
  static const String userSignatureKey = 'user_signature';

  final AuthApi _api;

  AuthRepositoryImpl(this._api);

  Future<void> _broadcastVerifyCodeIfNeeded({
    required String? message,
    required String scene,
  }) async {
    if (Network.emailVerifyCodeMode) return;
    await SystemTipBroadcast.notifyVerifyCode(
      verifyCode: message ?? '',
      scene: scene,
    );
  }

  Future<Map<String, dynamic>> _requireBodyMap(dynamic body) async {
    if (body is Map<String, dynamic>) return body;
    if (body is Map) return Map<String, dynamic>.from(body);
    throw const ApiException('Invalid response');
  }

  Future<void> _saveTokenFromResponseBody(
    dynamic body, {
    int? statusCode,
  }) async {
    final b = await _requireBodyMap(body);

    final code = b['code'];
    final message = b['message']?.toString();
    if (code != 200) {
      throw ApiException(message ?? 'Request failed', statusCode: statusCode);
    }

    final data = b['data'];
    if (data is! Map) {
      throw ApiException(message ?? 'Request failed', statusCode: statusCode);
    }
    final m = Map<String, dynamic>.from(data);

    final token = m['token'];
    if (token is! String || token.isEmpty) {
      throw ApiException(message ?? 'Request failed', statusCode: statusCode);
    }

    await LocalData.setString(tokenKey, token);

    final expiresAt = m['expiresAt'];
    if (expiresAt is int) {
      await LocalData.setInt(tokenExpiresAtKey, expiresAt);
    }

    final userMap =
        (m['user'] is Map)
            ? Map<String, dynamic>.from(m['user'] as Map)
            : (m['userInfo'] is Map)
            ? Map<String, dynamic>.from(m['userInfo'] as Map)
            : m;

    final nickname = userMap['nickname']?.toString().trim();
    final username = userMap['username']?.toString().trim();
    final displayName =
        (nickname != null && nickname.isNotEmpty)
            ? nickname
            : (username != null && username.isNotEmpty)
            ? username
            : '';
    if (displayName.isNotEmpty) {
      await LocalData.setString(userDisplayNameKey, displayName);
    }

    final avatar = userMap['avatar']?.toString().trim();
    print('[Login] userMap keys: ${userMap.keys.toList()}');
    print('[Login] avatar value: $avatar');
    if (avatar != null && avatar.isNotEmpty) {
      await LocalData.setString(userAvatarPathKey, avatar);
      print('[Login] Saved avatar path: $avatar');
    } else {
      print('[Login] Avatar is null or empty, not saving');
    }

    final signature = userMap['signature']?.toString().trim();
    if (signature != null && signature.isNotEmpty) {
      await LocalData.setString(userSignatureKey, signature);
    }
  }

  @override
  Future<void> login({
    required String username,
    required String password,
    required String deviceId,
  }) async {
    final res = await _api.login(
      username: username,
      password: password,
      deviceId: deviceId,
    );

    final body = await _requireBodyMap(res.data);
    final code = body['code'];
    final message = body['message']?.toString();
    if (code != 200) {
      throw ApiException(message ?? 'Login failed', statusCode: res.statusCode);
    }

    final data = body['data'];
    if (data is Map) {
      final m = Map<String, dynamic>.from(data);
      if (m['needEmailVerify'] == true) {
        await _broadcastVerifyCodeIfNeeded(message: message, scene: '登录');
        final challengeId = m['challengeId'];
        if (challengeId is String && challengeId.isNotEmpty) {
          throw NeedEmailVerifyException(
            message ?? 'Need email verify',
            challengeId: challengeId,
            statusCode: res.statusCode,
          );
        }
        throw ApiException(
          message ?? 'Need email verify',
          statusCode: res.statusCode,
        );
      }
    }

    await _saveTokenFromResponseBody(body, statusCode: res.statusCode);
  }

  @override
  Future<void> loginVerify({
    required String challengeId,
    required String emailCode,
    required String deviceId,
  }) async {
    final res = await _api.loginVerify(
      challengeId: challengeId,
      emailCode: emailCode,
      deviceId: deviceId,
    );
    await _saveTokenFromResponseBody(res.data, statusCode: res.statusCode);
  }

  @override
  Future<void> sendChangePasswordEmailCode({
    required String username,
    required String emailPhone,
    required String deviceId,
  }) async {
    final res = await _api.sendChangePasswordEmailCode(
      username: username,
      emailPhone: emailPhone,
      deviceId: deviceId,
    );

    final body = await _requireBodyMap(res.data);
    final code = body['code'];
    final message = body['message']?.toString();
    if (code != 200) {
      throw ApiException(
        message ?? 'Request failed',
        statusCode: res.statusCode,
      );
    }

    await _broadcastVerifyCodeIfNeeded(message: message, scene: '修改密码');
  }

  @override
  Future<void> changePassword({
    required String username,
    required String emailPhone,
    required String newPassword,
    required String emailCode,
    required String deviceId,
  }) async {
    final res = await _api.changePassword(
      username: username,
      emailPhone: emailPhone,
      newPassword: newPassword,
      emailCode: emailCode,
      deviceId: deviceId,
    );

    final body = await _requireBodyMap(res.data);
    final code = body['code'];
    final message = body['message']?.toString();
    if (code != 200) {
      throw ApiException(
        message ?? 'Request failed',
        statusCode: res.statusCode,
      );
    }
  }

  @override
  Future<void> logout() async {
    // 清除所有本地存储的用户信息和 token
    await LocalData.prefs?.remove(tokenKey);
    await LocalData.prefs?.remove(tokenExpiresAtKey);
    await LocalData.prefs?.remove(userDisplayNameKey);
    await LocalData.prefs?.remove(userAvatarPathKey);
    await LocalData.prefs?.remove(userSignatureKey);
    // 清除离线模式标记
    await LocalData.prefs?.remove('offline_mode');
  }
}
