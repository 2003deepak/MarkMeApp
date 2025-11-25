import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

Future<String> getDeviceInfo() async {
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
