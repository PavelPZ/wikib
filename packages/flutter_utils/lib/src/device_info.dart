// https://github.com/jhomlala/catcher/blob/477c86726b405d0a65b26e0dd4e5512955ccabbd/lib/core/catcher.dart
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

const deviceInfoDisplayName = 'diDisplayName';
const deviceInfoPlatformName = 'diPlatform';

Future<Map<String, dynamic>> loadDeviceInfo() async {
  final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  final baseInfo = await deviceInfo.deviceInfo;
  final res = baseInfo.toMap();
  if (kIsWeb) {
    final webBrowserInfo = baseInfo as WebBrowserInfo;
    res[deviceInfoDisplayName] = webBrowserInfo.browserName.toString();
    res[deviceInfoPlatformName] = 'web';
  } else {
    res[deviceInfoPlatformName] = defaultTargetPlatform.toString();
    switch (defaultTargetPlatform) {
      case TargetPlatform.windows:
        final windowsDeviceInfo = baseInfo as WindowsDeviceInfo;
        res[deviceInfoDisplayName] = windowsDeviceInfo.computerName;
        break;
      case TargetPlatform.linux:
        final linuxDeviceInfo = baseInfo as LinuxDeviceInfo;
        res[deviceInfoDisplayName] = linuxDeviceInfo.name;
        break;
      case TargetPlatform.android:
        final androidDeviceInfo = baseInfo as AndroidDeviceInfo;
        res[deviceInfoDisplayName] = '${androidDeviceInfo.manufacturer}: ${androidDeviceInfo.model}';
        break;
      case TargetPlatform.iOS:
        final iosInfo = baseInfo as IosDeviceInfo;
        res[deviceInfoDisplayName] = '${iosInfo.name}: ${iosInfo.model}';
        break;
      case TargetPlatform.macOS:
        final macOsDeviceInfo = baseInfo as MacOsDeviceInfo;
        res[deviceInfoDisplayName] = '${macOsDeviceInfo.model}: ${macOsDeviceInfo.computerName}';
        break;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }
  return res;
}
