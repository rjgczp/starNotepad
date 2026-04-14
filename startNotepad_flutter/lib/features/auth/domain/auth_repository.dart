abstract class AuthRepository {
  Future<void> login({
    required String username,
    required String password,
    required String deviceId,
  });

  Future<void> loginVerify({
    required String challengeId,
    required String emailCode,
    required String deviceId,
  });

  Future<void> sendChangePasswordEmailCode({
    required String username,
    required String emailPhone,
    required String deviceId,
  });

  Future<void> changePassword({
    required String username,
    required String emailPhone,
    required String newPassword,
    required String emailCode,
    required String deviceId,
  });

  Future<void> logout();
}
