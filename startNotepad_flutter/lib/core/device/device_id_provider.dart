import 'dart:io';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';

import '../../tools/localData.dart';

class DeviceIdProvider {
  static const String deviceIdKey = 'device_id';

  static Future<String> getOrCreate() async {
    if (LocalData.prefs == null) {
      await LocalData.init();
    }

    final cached = LocalData.getString(deviceIdKey);
    if (cached.isNotEmpty) return cached;

    final plugin = DeviceInfoPlugin();

    String? id;
    try {
      if (Platform.isAndroid) {
        final info = await plugin.androidInfo;
        id = info.id;
        if (id.isEmpty) {
          id = info.fingerprint;
        }
      } else if (Platform.isIOS) {
        final info = await plugin.iosInfo;
        id = info.identifierForVendor;
        if (id == null || id.isEmpty) {
          id = info.model;
        }
      } else if (Platform.isMacOS) {
        final info = await plugin.macOsInfo;
        id = info.systemGUID;
      } else if (Platform.isWindows) {
        final info = await plugin.windowsInfo;
        id = info.deviceId;
      } else if (Platform.isLinux) {
        final info = await plugin.linuxInfo;
        id = info.machineId;
      }
    } catch (_) {
      // Fall through to fallback.
    }

    final deviceId =
        (id == null || id.isEmpty)
            ? _fallbackStable()
            : '${Platform.operatingSystem}-$id';
    await LocalData.setString(deviceIdKey, deviceId);
    return deviceId;
  }

  static String _fallbackStable() {
    final r = Random.secure();
    final buf = List<int>.generate(16, (_) => r.nextInt(256));
    final hex = buf.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${Platform.operatingSystem}-rnd-$hex';
  }
}
