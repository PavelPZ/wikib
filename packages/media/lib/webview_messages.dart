import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:functional_widget_annotation/functional_widget_annotation.dart';
import 'package:webview_windows/webview_windows.dart';

// flutter pub run build_runner watch --delete-conflicting-outputs
part 'webview_messages.g.dart';

Future main() async {
  runApp(const MyApp());
}

@swidget
Widget myApp() => MaterialApp(
      title: 'webview_messages',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
          appBar: AppBar(
            title: Text('webview_messages'),
          ),
          body: MyBody()),
    );

@hwidget
Widget myBody() {
  final isInitialized = useState(false);
  final messageFromWebView = useState('');
  final controller = useMemoized(() => WebviewController(), []);

  Future initialize() async {
    if (isInitialized.value || controller.value.isInitialized) return;
    await controller.initialize();
    await controller.loadUrl('http://localhost:3000/');
    controller.webMessage.listen((msg) {
      messageFromWebView.value = jsonEncode(msg);
    });
    // await controller.loadUrl('https://google.com/');
    // await controller.loadStringContent(window_html_hack_data);
    isInitialized.value = true;
  }

  initialize();

  return Center(
    child: Column(
      children: [
        SizedBox(
          width: WIDTH,
          height: HEIGHT,
          child: Stack(
            children: [
              SizedBox(
                width: WIDTH,
                height: HEIGHT,
                child: const DecoratedBox(
                  decoration: BoxDecoration(color: Colors.amberAccent),
                  position: DecorationPosition.foreground,
                ),
              ),
              isInitialized.value ? Webview(controller, width: WIDTH, height: HEIGHT) : CircularProgressIndicator(),
            ],
          ),
        ),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => controller.postWebMessage('{"message":"dart", "number": 1.4, "bool": false, "string": "string2"}'),
          child: Text('Send message'),
        ),
        SizedBox(height: 20),
        Text(messageFromWebView.value),
      ],
    ),
  );
}

const WIDTH = 1000.0;
const HEIGHT = 100.0;
