// ignore_for_file: unused_import

import 'dart:js' as js;
import 'dart:html';
import 'dart:js_util';

import 'package:flutter/material.dart';

import '../interface.dart';
import 'common.dart';

class MediaPlatform {
  static Future appInit() async {}
  static Widget getWebView({required Widget child}) => SizedBox();
  static Future callJavascript(String script) => Future.value(js.context.callMethod(script, []));
  static int get actualPlatform => Platforms.web;
}
