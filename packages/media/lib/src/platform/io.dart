import 'dart:io';

import 'package:flutter/widgets.dart';

import 'mobile.dart';
import 'windows.dart';

class MediaPlatform {
  static Future appInit() => _isMobile ? MobileMediaPlatform.appInit() : WindowsMediaPlatform.appInit();

  static final actualPlatform = _isMobile ? MobileMediaPlatform.actualPlatform : WindowsMediaPlatform.actualPlatform;

  static Widget getWebView({required Widget child}) =>
      _isMobile ? MobileMediaPlatform.getWebView(child: child) : WindowsMediaPlatform.getWebView(child: child);

  static Future callJavascript(String script) => _isMobile ? MobileMediaPlatform.callJavascript(script) : WindowsMediaPlatform.callJavascript(script);

  static void postMessage(Map<String, dynamic> msg) => _isMobile ? MobileMediaPlatform.postMessage(msg) : WindowsMediaPlatform.postMessage(msg);
  static Stream<Map<dynamic, dynamic>> get webMessage => _isMobile ? MobileMediaPlatform.webMessage : WindowsMediaPlatform.webMessage;

  static bool get _isMobile => Platform.isAndroid || Platform.isIOS;
}
