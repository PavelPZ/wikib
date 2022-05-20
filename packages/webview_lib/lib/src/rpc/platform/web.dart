// ignore_for_file: unused_import

import 'dart:js' as js;
import 'dart:html';
import 'dart:js_util';

import 'package:flutter/material.dart';

import '../interface.dart';
import 'common.dart';

IMediaPlatform createPlatform() => MediaPlatform();

class MediaPlatform extends IMediaPlatform {
  @override
  Future appInit() async => throw UnimplementedError();
  @override
  int get actualPlatform => Platforms.web;
  @override
  Widget getWebView({required Widget child}) => SizedBox();
  @override
  Future callJavascript(String script) => Future.value(js.context.callMethod(script, []));

  // @override
  // void postToWebView(IRpc rpcCall) => throw UnimplementedError();
}
