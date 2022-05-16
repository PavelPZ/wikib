// ignore_for_file: prefer_single_quotes, unawaited_futures, avoid_print

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:functional_widget_annotation/functional_widget_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import 'example2_server.dart';

// flutter pub run build_runner watch --delete-conflicting-outputs
part 'example2.g.dart';

final webViewControllerProvider = StateProvider<InAppWebViewController?>((_) => null);
final localhostServer = LocalhostServer();

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // await Permission.camera.request();
  await Permission.microphone.request();
  await localhostServer.start();

  if (Platform.isAndroid) {
    await AndroidInAppWebViewController.setWebContentsDebuggingEnabled(true);
  }

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
Widget webView(WidgetRef ref, {Widget? child}) {
  final webView = useMemoized(() {
    final creator = child == null ? InAppWebView.new : HeadlessInAppWebView.new;
    return creator(
      initialUrlRequest: URLRequest(url: Uri.parse("http://localhost:$port/index.html")),
      initialOptions: InAppWebViewGroupOptions(
        crossPlatform: InAppWebViewOptions(
          // useShouldOverrideUrlLoading: false, // default
          // mediaPlaybackRequiresUserGesture: false,
          clearCache: true,
        ),
        android: AndroidInAppWebViewOptions(
          useHybridComposition: true,
        ),
        ios: IOSInAppWebViewOptions(
          allowsInlineMediaPlayback: true,
        ),
      ),
      onWebViewCreated: (controller) {
        ref.read(webViewControllerProvider.notifier).state = controller;
        // controller.loadFile(assetFilePath: "assets/index.html");
      },
      androidOnPermissionRequest: (controller, origin, resources) async {
        return PermissionRequestResponse(resources: resources, action: PermissionRequestResponseAction.GRANT);
      },
      onConsoleMessage: (controller, consoleMessage) {
        print(consoleMessage);
      },
      onLoadError: (controller, uri, id, txt) => print('$id: $txt'),
      onLoadHttpError: (controller, uri, id, txt) => print('$id: $txt'),
      onLoadStop: (controller, url) async {},
    );
  }, []);
  return child ?? webView as InAppWebView;
}
