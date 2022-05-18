import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:functional_widget_annotation/functional_widget_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../interface.dart';
import 'localServer.dart';

// flutter pub run build_runner watch --delete-conflicting-outputs
part 'platformMobile.g.dart';

class MobileMediaPlatform implements IMediaPlatform {
  static InAppWebViewController? _mobileWebViewController = null;

  @override
  Future appInit() async {
    await Permission.microphone.request();
    if (Platform.isAndroid) {
      await AndroidInAppWebViewController.setWebContentsDebuggingEnabled(true);
    }
  }

  @override
  final actualPlatform = Platforms.mobile;

  @override
  Widget getWebView({required Widget child}) => MobileWebView(child: child);

  @override
  Future callJavascript(String script) => _mobileWebViewController!.evaluateJavascript(source: script);

  @override
  void postMessage(Map<String, dynamic> msg) {}
  @override
  Stream<Map<dynamic, dynamic>> get webMessage => throw UnimplementedError();
}

@hcwidget
Widget mobileWebView(WidgetRef ref, {Widget? child}) {
  final webView = useMemoized(() {
    final creator = child == null ? InAppWebView.new : HeadlessInAppWebView.new;
    return creator(
      initialUrlRequest: URLRequest(url: Uri.parse(localhostServerUrl)),
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
        MobileMediaPlatform._mobileWebViewController = controller;
        //ref.read(mobileWebViewControllerProvider.notifier).state = controller;
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
