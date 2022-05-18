// Windows:
// https://codingwithtashi.medium.com/how-to-use-flutter-webview-windows-in-your-flutter-application-and-communicate-between-them-60050f0bb48f
// https://pub.dev/documentation/webview_windows/latest/webview_windows/WebviewController/executeScript.html
// Mobiles:
// https://inappwebview.dev/docs/javascript/communication/
import 'package:webview_lib/webview_lib.dart';

Future mediaAppInit() async {
  platform = createPlatform();
  await platform.appInit();
  await platform.callJavascript('window.media.setPlatform(${platform.actualPlatform.toString()})');
  // MediaPlatform.postMessage({'msg': 'test'});
  platform.webMessage.listen((json) {
    if (json['streamId'] == StreamIds.consoleLog) print('MediaView: ${json['value']}');
  });
}
