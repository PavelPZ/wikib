// https://weblog.west-wind.com/posts/2021/Jan/26/Chromium-WebView2-Control-and-NET-to-JavaScript-Interop-Part-2
// https://stackoverflow.com/questions/68544091/how-to-post-message-from-typescript-to-c
// https://github.com/MicrosoftEdge/WebView2Samples/blob/a12bfcc2bc8a1155529c35c7bd4645036f492ca0/GettingStartedGuides/WPF_GettingStarted/MainWindow.xaml.cs
// https://docs.microsoft.com/cs-cz/microsoft-edge/webview2/get-started/wpf

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:functional_widget_annotation/functional_widget_annotation.dart';
import 'package:webview_windows/webview_windows.dart';

// flutter pub run build_runner watch --delete-conflicting-outputs
part 'webview_sound_hack.g.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

@swidget
Widget myApp() => MaterialApp(
      title: 'webview_sound_hack',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
          appBar: AppBar(
            title: Text('webview_sound_hack'),
          ),
          body: MyBody()),
    );

@hwidget
Widget myBody() {
  final isInitialized = useState(false);
  final controller = useMemoized(() => WebviewController(), []);

  Future initialize() async {
    if (isInitialized.value || controller.value.isInitialized) return;
    await controller.initialize();
    await controller.setBackgroundColor(Colors.transparent);
    await controller.loadUrl('http://localhost:3000/');
    // await controller.loadUrl('https://google.com/');
    // await controller.loadStringContent(window_html_hack_data);
    isInitialized.value = true;
  }

  initialize();

  return Center(
    child: SizedBox(
        width: WIDTH,
        height: WIDTH,
        child: Stack(
          children: [
            SizedBox(
              width: WIDTH,
              height: WIDTH,
              child: const DecoratedBox(
                decoration: BoxDecoration(color: Colors.red),
                position: DecorationPosition.foreground,
              ),
            ),
            isInitialized.value ? Webview(controller, width: WIDTH, height: WIDTH) : CircularProgressIndicator(),
          ],
        )),
  );
}

const WIDTH = 200.0;
