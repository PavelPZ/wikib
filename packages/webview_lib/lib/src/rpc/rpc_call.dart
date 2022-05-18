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

void receiveFromWebView<T>(IStreamMessage<T> item) {
  listenners[item.streamId]!(item);
}

final listenners = <int, void Function(IStreamMessage)>{
  StreamIds.consoleLog: (item) => print(item.value),
  StreamIds.promiseCallback: rpcCallback,
};

final promises = <int, Completer>{};
var lastPromiseIdx = 1;
