import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class SystemTipBroadcast {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static int _notificationIdSeed = 40000;

  static Future<void> _ensureInitialized() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(settings);

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin
    >();
    await androidPlugin?.requestNotificationsPermission();

    _initialized = true;
  }

  static Future<void> notifyVerifyCode({
    required String verifyCode,
    required String scene,
  }) async {
    final code = verifyCode.trim();
    if (code.isEmpty) return;

    try {
      await _ensureInitialized();

      const androidDetails = AndroidNotificationDetails(
        'verify_code_channel',
        '验证码提示',
        channelDescription: '登录与密码找回验证码系统提示',
        importance: Importance.max,
        priority: Priority.high,
      );
      const details = NotificationDetails(android: androidDetails);

      _notificationIdSeed++;
      await _plugin.show(
        _notificationIdSeed,
        '验证码提示',
        '$scene验证码：$code',
        details,
      );
    } catch (_) {
      // 忽略通知异常，避免影响主业务流程
    }
  }
}
