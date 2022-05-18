import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:webview_windows/webview_windows.dart';

import '../interface.dart';
import '../rpc_call.dart';
import 'localServer.dart';

class WindowsMediaPlatform implements IMediaPlatform {
  static WebviewController? _windowsWebViewController = null;

  @override
  Future appInit() async {
    _windowsWebViewController = WebviewController();
    _windowsWebViewController!.webMessage.listen((event) {
      receiveFromWebView(IStreamMessage.fromJson(event as Map<String, dynamic>));
    });
    await _windowsWebViewController!.initialize();
    await _windowsWebViewController!.loadUrl(localhostServerUrl);
    final completer = Completer();
    final unlisten = _windowsWebViewController!.loadingState.listen((loadingState) {
      if (loadingState == LoadingState.navigationCompleted) completer.complete();
    });
    await completer.future;
    await unlisten.cancel();
  }

  @override
  final actualPlatform = Platforms.windows;

  @override
  Widget getWebView({required Widget child}) => Stack(children: [
        // SizedBox(width: 0, height: 0, child: Webview(_windowsWebViewController!)),
        // SizedBox.expand(child: child),
        Webview(_windowsWebViewController!),
        child,
      ]);

  @override
  Future callJavascript(String script) => _windowsWebViewController!.executeScript(script);

  @override
  void postToWebView(IRpc rpcCall) => _windowsWebViewController!.postWebMessage(jsonEncode(rpcCall.toJson()));
}
