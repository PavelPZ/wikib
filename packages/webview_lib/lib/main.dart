import 'package:flutter/material.dart';
import 'package:functional_widget_annotation/functional_widget_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:webview_lib/webview_lib.dart';

// flutter pub run build_runner watch --delete-conflicting-outputs
part 'main.g.dart';

const longUrl = 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3';
const shortUrl = 'https://free-loops.com/data/mp3/c8/84/81a4f6cc7340ad558c25bba4f6c3.mp3';
const playUrl = longUrl;

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await webViewRpcInit();

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
    child: SizedBox.expand(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: SafeArea(
          child: Scaffold(
            body: Center(
                child: ElevatedButton(
              onPressed: play,
              child: Text('PLAY'),
            )),
          ),
        ),
      ),
    ),
  );
}

Future play() async {
  final player = await PlayerProxy.create(playUrl);
  await player.play();
  await Future.delayed(Duration(milliseconds: 100000));
  await player.stop();
  await Future.delayed(Duration(milliseconds: 1000));
  await player.dispose();
}
