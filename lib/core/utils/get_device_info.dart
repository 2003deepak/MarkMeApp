import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<String> getDeviceInfo() async {
  // For desktop platforms, return generic info
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    return "${getPlatformType()} Desktop";
  }

  // For mobile platforms, use device_info_plus
  final deviceInfo = DeviceInfoPlugin();

  if (Platform.isAndroid) {
    final android = await deviceInfo.androidInfo;
    return "Android ${android.model}, SDK ${android.version.sdkInt}";
  } else if (Platform.isIOS) {
    final ios = await deviceInfo.iosInfo;
    return "iOS ${ios.model}, ${ios.systemVersion}";
  }
  return "Unknown Device";
}

String getPlatformType() {
  if (kIsWeb) return "web";
  if (Platform.isAndroid) return "android";
  if (Platform.isIOS) return "ios";
  if (Platform.isWindows) return "windows";
  if (Platform.isMacOS) return "macos";
  if (Platform.isLinux) return "linux";
  return "unknown";
}

// Add this helper function
bool get isMobilePlatform => Platform.isAndroid || Platform.isIOS;
bool get isDesktopPlatform =>
    Platform.isWindows || Platform.isMacOS || Platform.isLinux;

Future<void> clearSession(SharedPreferences prefs) async {
  await prefs.remove('refreshToken');
  await prefs.remove('role');
  await prefs.remove('fcmToken');
}
