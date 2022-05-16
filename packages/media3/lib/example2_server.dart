// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'example2_data.dart';

const int port = 7660;

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
    if (_started) throw Exception('Server already started on http://localhost:$port');
    _started = true;

    final completer = Completer();

    runZonedGuarded(() {
      HttpServer.bind('127.0.0.1', port).then((server) {
        print('Server running on http://localhost:${port.toString()}');

        server.listen((HttpRequest request) async {
          final path = request.requestedUri.path;
          if (path != '/index.html') return;
          request.response.headers.contentType = ContentType('text', 'html', charset: 'utf-8');
          request.response.add(utf8.encode(htmlData));
          await request.response.close();
        });

        completer.complete();
      });
    }, (e, stackTrace) => print('Error: $e $stackTrace'));

    return completer.future;
  }
}

//   ///Closes the server.
//   Future<void> close() async {
//     if (this._server == null) {
//       return;
//     }
//     await this._server!.close(force: true);
//     print('Server running on http://localhost:$_port closed');
//     this._started = false;
//     this._server = null;
//   }

//   ///Indicates if the server is running or not.
//   bool isRunning() {
//     return this._server != null;
//   }

//   ContentType _getContentTypeFromMimeType(String mimeType) {
//     final contentType = mimeType.split('/');
//     String? charset;

//     if (_isTextFile(mimeType)) {
//       charset = 'utf-8';
//     }

//     return ContentType(contentType[0], contentType[1], charset: charset);
//   }

//   bool _isTextFile(String mimeType) {
//     final textFile = RegExp(r'^text\/|^application\/(javascript|json)');
//     return textFile.hasMatch(mimeType);
//   }
// }
