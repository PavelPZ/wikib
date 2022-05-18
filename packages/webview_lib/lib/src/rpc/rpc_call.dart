import 'dart:async';

import 'interface.dart';

late IMediaPlatform platform;

Future<List<dynamic>> rpc(List<IRpcFnc> calls) {
  final msg = IRpc(rpcId: lastPromiseIdx++, fncs: calls);
  print('flutter rpc (rpcId=${msg.rpcId})');
  final comp = promises[msg.rpcId] = Completer<List<dynamic>>();
  platform.postToWebView(msg);
  return comp.future;
}

void rpcCallback(IStreamMessage msg) {
  print('flutter rpc Callback (rpcId=${msg.value.rpcId})');
  final comp = promises.remove(msg.value.rpcId);
  if (comp == null) throw Exception('not found');
  if (msg.value.error != null)
    comp.completeError(msg.value.error);
  else
    comp.complete(msg.value.result);
}

void handlerCallback(IStreamMessage msg) {
  if (msg.name == null) return;
  final listenner = handlerListenners[msg.name];
  if (listenner == null) return;
  listenner(msg);
}

void receiveFromWebView<T>(IStreamMessage<T> msg) {
  switch (msg.streamId) {
    case StreamIds.consoleLog:
      print(msg.value);
      break;
    case StreamIds.promiseCallback:
      rpcCallback(msg);
      break;
    default:
      handlerCallback(msg);
      break;
  }
}

final handlerListenners = <int, void Function(IStreamMessage)>{};

final promises = <int, Completer>{};
var lastPromiseIdx = 1;
