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

void _rpcCallback(IRpcResult rpcResult) {
  print('flutter rpc Callback (rpcId=${rpcResult.rpcId})');
  final comp = promises.remove(rpcResult.rpcId);
  if (comp == null) throw Exception('not found');
  if (rpcResult.error != null)
    comp.completeError(rpcResult.error!);
  else
    comp.complete(rpcResult.result);
}

void handlerCallback(IStreamMessage msg) {
  if (msg.handlerId == null) return;
  final listenner = handlerListenners[msg.handlerId];
  if (listenner == null) return;
  listenner(msg.streamId, msg.value);
}

void receiveFromWebView(IStreamMessage msg) {
  switch (msg.streamId) {
    case StreamIds.consoleLog:
      print(msg.value);
      break;
    case StreamIds.rpcCallback:
      _rpcCallback(IRpcResult.fromJson(msg.value as Map<String, dynamic>));
      break;
    default:
      handlerCallback(msg);
      break;
  }
}

final handlerListenners = <int, void Function(int streamId, dynamic value)>{};

final promises = <int, Completer>{};
var lastPromiseIdx = 1;
