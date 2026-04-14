import 'package:shared_preferences/shared_preferences.dart';

class LocalData {
  static SharedPreferences? prefs;

  //初始化
  static Future<void> init() async {
    prefs = await SharedPreferences.getInstance();
  }

  static Future<void> setValue(String key, Object value) async {
    final p = prefs;
    if (p == null) return;

    if (value is String) {
      await p.setString(key, value);
    } else if (value is int) {
      await p.setInt(key, value);
    } else if (value is bool) {
      await p.setBool(key, value);
    } else if (value is double) {
      await p.setDouble(key, value);
    }
  }

  static Object? getValue(String key) {
    return prefs?.get(key);
  }

  //设置字符串
  static Future<void> setString(String key, String value) async {
    await prefs?.setString(key, value);
  }

  //获取字符串
  static String getString(String key) {
    return prefs?.getString(key) ?? '';
  }

  //设置布尔值
  static Future<void> setBool(String key, bool value) async {
    await prefs?.setBool(key, value);
  }

  //获取布尔值
  static bool getBool(String key) {
    return prefs?.getBool(key) ?? false;
  }

  static Future<void> setInt(String key, int value) async {
    await prefs?.setInt(key, value);
  }

  static int getInt(String key) {
    return prefs?.getInt(key) ?? 0;
  }
}
