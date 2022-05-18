import 'package:flutter/material.dart';
import 'package:functional_widget_annotation/functional_widget_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:webview_lib/webview_lib.dart';

// flutter pub run build_runner watch --delete-conflicting-outputs
part 'main.g.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await mediaAppInit();

  // // await Permission.camera.request();
  // await Permission.microphone.request();
  // await localhostServer.start();

  // if (Platform.isAndroid) {
  //   await AndroidInAppWebViewController.setWebContentsDebuggingEnabled(true);
  // }

  runApp(const ProviderScope(child: MaterialApp(home: MyApp())));
}

@cwidget
Widget myApp(WidgetRef ref) {
  return platform.getWebView(
    child: SizedBox.shrink(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: SafeArea(
          child: Scaffold(
            body: Center(child: Text('HALLO WORLD')),
          ),
        ),
      ),
    ),
  );
}
