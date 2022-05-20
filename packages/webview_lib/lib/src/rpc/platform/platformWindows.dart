import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:webview_lib/src/rpc/platform/io.dart';
import 'package:webview_windows/webview_windows.dart';

import '../interface.dart';
import '../rpc_call.dart';
import 'localServer.dart';

class WindowsMediaPlatform extends IMediaPlatform {
  static WebviewController? _windowsWebViewController = null;

  @override
  Future appInit() async {
    await localhostServer.start();
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
  Widget getWebView({required Widget child}) => _getWebView(child: child);

  // ignore: unused_element
  Widget _getWebViewDebug({required Widget child}) => Row(
        children: [
          Expanded(child: child),
          Expanded(
              child: Webview(
            _windowsWebViewController!,
            permissionRequested: (url, kind, isUserInitiated) => Future.value(WebviewPermissionDecision.allow),
          )),
        ],
      );

  // ignore: unused_element
  Widget _getWebView({required Widget child}) => Stack(children: [
        SizedBox(
          width: 0,
          height: 0,
          child: Webview(
            _windowsWebViewController!,
            permissionRequested: (url, kind, isUserInitiated) => Future.value(WebviewPermissionDecision.allow),
          ),
        ),
        SizedBox.expand(child: child),
      ]);

  @override
  Future callJavascript(String script) => _windowsWebViewController!.executeScript(script);

  // @override
  // void postToWebView(IRpc rpcCall) {
  //   final msg = jsonEncode(rpcCall.toJson());
  //   print(msg);
  //   _windowsWebViewController!.postWebMessage(msg);
  // }
}
