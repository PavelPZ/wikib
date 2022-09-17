// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

const int port = 7660;

const localhostServerUrl = 'http://localhost:$port/index.html';

///This class allows you to create a simple server on `http://localhost:[port]/` in order to be able to load your assets file on a server. The default [port] value is `8080`.
class LocalhostServer {
  bool _started = false;

  ///Starts the server on `http://localhost:[port]/`.
  ///
  ///**NOTE for iOS**: For the iOS Platform, you need to add the `NSAllowsLocalNetworking` key with `true` in the `Info.plist` file (See [ATS Configuration Basics](https://developer.apple.com/library/archive/documentation/General/Reference/InfoPlistKeyReference/Articles/CocoaKeys.html#//apple_ref/doc/uid/TP40009251-SW35)):
  ///```xml
  ///<key>NSAppTransportSecurity</key>
  ///<dict>
  ///    <key>NSAllowsLocalNetworking</key>
  ///    <true/>
  ///</dict>
  ///```
  ///The `NSAllowsLocalNetworking` key is available since **iOS 10**.
  Future<void> start() async {
    if (_started)
      throw Exception(
          'LocalhostServer already started on http://localhost:$port');
    _started = true;

    final completer = Completer();

    runZonedGuarded(() {
      HttpServer.bind('127.0.0.1', port).then((server) {
        server.listen((HttpRequest request) async {
          final path = request.requestedUri.path;
          if (path != '/index.html') return;
          request.response.headers.contentType =
              ContentType('text', 'html', charset: 'utf-8');
          final html = await rootBundle.loadString('assets/index.html');
          final js = await rootBundle.loadString('assets/media.js');
          final body = html.replaceFirst('{####}', js);
          // final body = debugHTML();
          request.response.add(utf8.encode(body));
          await request.response.close();
        });

        completer.complete();
      });
    }, (e, stackTrace) => print('LocalhostServer error: $e $stackTrace'));

    return completer.future;
  }
}
