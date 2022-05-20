// ignore_for_file: unused_import
@JS('wikibWeb')
library wikibWeb;

import 'dart:convert';
import 'dart:js' as js;

// import 'dart:html';
// import 'dart:js_util';

import 'package:flutter/material.dart';
import 'package:js/js.dart';

import '../interface.dart';
import '../rpc_call.dart';
import 'init.dart';

IMediaPlatform createPlatform() => MediaPlatform();

class MediaPlatform extends IMediaPlatform {
  @override
  Future appInit() async {
    js.context.callMethod('setWikibWebPostMessage', [
      allowInterop((json) {
        final msg = IStreamMessage.fromJson(jsonDecode(json));
        receiveFromWebView(msg);
      })
    ]);
    await onDocumentLoaded();
  }

  @override
  int get actualPlatform => Platforms.web;
  @override
  Widget getWebView({required Widget? child}) => child ?? SizedBox();
  @override
  Future callJavascript(String script) => Future.value(js.context.callMethod('eval', [script]));
}
