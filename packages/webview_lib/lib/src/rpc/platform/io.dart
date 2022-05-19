import 'dart:io';

import '../interface.dart';
import 'localServer.dart';
import 'platformMobile.dart';
import 'platformWindows.dart';

final localhostServer = LocalhostServer();

IMediaPlatform createPlatform() {
  if (Platform.isAndroid || Platform.isIOS) return MobileMediaPlatform();
  if (Platform.isWindows) return WindowsMediaPlatform();
  throw UnimplementedError();
}
