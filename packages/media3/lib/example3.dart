// ignore_for_file: prefer_single_quotes, unawaited_futures, avoid_print

// Windows:
// https://codingwithtashi.medium.com/how-to-use-flutter-webview-windows-in-your-flutter-application-and-communicate-between-them-60050f0bb48f
// https://pub.dev/documentation/webview_windows/latest/webview_windows/WebviewController/executeScript.html
// Mobiles:
// https://inappwebview.dev/docs/javascript/communication/

import 'dart:async';
import 'dart:convert';
import 'dart:js' as js;
import 'dart:html';
import 'dart:js_util';

import 'package:js/js.dart';

import 'package:flutter/material.dart';
// import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:functional_widget_annotation/functional_widget_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:json_annotation/json_annotation.dart';

// flutter pub run build_runner watch --delete-conflicting-outputs
part 'example3.g.dart';

@JsonSerializable()
class IStreamItem {
  IStreamItem({required this.streamId, required this.value});
  final int streamId;
  final Map<String, dynamic> value;
  factory IStreamItem.fromJson(Map<String, dynamic> json) => _$IStreamItemFromJson(json);
  Map<String, dynamic> toJson() => _$IStreamItemToJson(this);
}

@JsonSerializable()
class IPromiseStreamValue {
  IPromiseStreamValue({required this.promiseId, required this.error, required this.result});
  final int promiseId;
  final int? result;
  final String? error;
  factory IPromiseStreamValue.fromJson(Map<String, dynamic> json) => _$IPromiseStreamValueFromJson(json);
  Map<String, dynamic> toJson() => _$IPromiseStreamValueToJson(this);
}

class Platforms {
  static const none = 0;
  static const web = 1;
  static const mobile = 2;
  static const windows = 3;
}

class StreamIds {
  static const none = 0;
  static const promiseCallback = 1;
  static const playerReadyState = 5;
  static const playerError = 6;
  static const playState = 7;
  static const playPosition = 8;
  static const playDurationchange = 9;
}

@JS('media.setPlatform')
external void mediaSetPlatform(int platform); // Platforms

void onStream(String str) {
  final map = jsonDecode(str);
  final item = IStreamItem.fromJson(map);
  switch (item.streamId) {
    case StreamIds.promiseCallback:
      final promise = IPromiseStreamValue.fromJson(item.value);
      if (promise.promiseId == 0) return;
      break;
  }
  print(str);
}

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setProperty(window, 'onStream', allowInterop(onStream));
  js.context.callMethod('media.setPlatform', ['']);
  mediaSetPlatform(Platforms.web);
  runApp(const ProviderScope(child: MaterialApp(home: MyApp())));
}

@cwidget
Widget myApp(WidgetRef ref) {
  // final controller = ref.watch(webViewControllerProvider);
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true),
    home: const SafeArea(
      child: Scaffold(
        body: Center(child: WebView()),
      ),
    ),
  );
}

@hcwidget
Widget webView(WidgetRef ref, {Widget? child}) => Text('HALLO');
