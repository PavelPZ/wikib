import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:webview_windows/webview_windows.dart';

import 'common.dart';
import 'localServer.dart';

class WindowsMediaPlatform {
  static final _localhostServer = LocalhostServer();
  static WebviewController? _windowsWebViewController = null;

  static Future appInit() async {
    await _localhostServer.start();
    _windowsWebViewController = WebviewController();
    await _windowsWebViewController!.initialize();
    await _windowsWebViewController!.loadUrl(localhostServerUrl);
    final completer = Completer();
    final unlisten = _windowsWebViewController!.loadingState.listen((loadingState) {
      if (loadingState == LoadingState.navigationCompleted) completer.complete();
    });
    await completer.future;
    await unlisten.cancel();
  }

  static const actualPlatform = Platforms.windows;

  static Widget getWebView({required Widget child}) => Stack(children: [
        SizedBox(width: 10, height: 10, child: Webview(_windowsWebViewController!)),
        SizedBox.expand(child: child),
      ]);

  static Future callJavascript(String script) => _windowsWebViewController!.executeScript(script);

  static void postMessage(Map<String, dynamic> msg) {}
  static Stream<Map<dynamic, dynamic>> get webMessage => _windowsWebViewController!.webMessage;
}
