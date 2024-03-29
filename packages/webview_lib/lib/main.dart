import 'package:flutter/material.dart';
import 'package:functional_widget_annotation/functional_widget_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:webview_lib/src/rpc/handlers.dart';
import 'package:webview_lib/webview_lib.dart';

// flutter pub run build_runner watch --delete-conflicting-outputs
part 'main.g.dart';

const longUrl = 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3';
const shortUrl =
    'https://free-loops.com/data/mp3/c8/84/81a4f6cc7340ad558c25bba4f6c3.mp3';
const playUrl = longUrl;

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await webViewRpcInit();

  runApp(const ProviderScope(child: MaterialApp(home: MyApp())));
}

@cwidget
Widget myApp(WidgetRef ref) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: SafeArea(
      child: Scaffold(
        body: Center(
          child: Column(children: [
            ElevatedButton(
              onPressed: play,
              child: Text('PLAY'),
            ),
            Expanded(
              child: platform.getWebView(child: null),
            ),
          ]),
        ),
      ),
    ),
  );
}

Future play() async {
  final player = await PlayerProxy.create(playUrl, listen: (id, result) {
    switch (id) {
      case StreamIds.playerReadyState:
        break;
      case StreamIds.playState:
        break;
    }
    ;
  });
  await rpc([
    getSetCall(player.audioName, 'currentTime', 360),
    getSetCall(player.audioName, 'playbackRate', 0.5),
  ]);
  await player.play();
  await Future.delayed(Duration(milliseconds: 3000));
  await player.stop();
  await Future.delayed(Duration(milliseconds: 500));
  await player.dispose();
}
