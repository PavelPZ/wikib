// Windows:
// https://codingwithtashi.medium.com/how-to-use-flutter-webview-windows-in-your-flutter-application-and-communicate-between-them-60050f0bb48f
// https://pub.dev/documentation/webview_windows/latest/webview_windows/WebviewController/executeScript.html
// Mobiles:
// https://inappwebview.dev/docs/javascript/communication/

import 'package:media/media.dart';

class Platforms {
  static const none = 0;
  static const web = 1;
  static const mobile = 2;
  static const windows = 3;
}

class StreamIds {
  static const none = 0;
  static const promiseCallback = 1;
  static const consoleLog = 2;
  static const playerReadyState = 5;
  static const playerError = 6;
  static const playState = 7;
  static const playPosition = 8;
  static const playDurationchange = 9;
}

Future mediaAppInit() async {
  await MediaPlatform.appInit();
  await MediaPlatform.callJavascript('media.setPlatform(${MediaPlatform.actualPlatform.toString()})');
}
