import 'dart:io';

import '../interface.dart';
import 'platformMobile.dart';
import 'platformWindows.dart';

IMediaPlatform createPlatform() {
  if (Platform.isAndroid || Platform.isIOS) return MobileMediaPlatform();
  if (Platform.isWindows) return WindowsMediaPlatform();
  throw UnimplementedError();
}
