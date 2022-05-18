import 'interface.dart';
import 'rpc_call.dart';

var handlerCounter = 1;
int newHandlerName() => handlerCounter++;

IRpcFnc getFncItem(int? handler, String? name, int? type, [List<dynamic>? args]) => IRpcFnc(
      name: handler == null ? '.${name}' : '.${handler}.${name}',
      type: type,
      arguments: args ?? [],
    );

IRpcFnc getFncCall(int? handler, String name, [List<dynamic>? args]) => getFncItem(handler, name, null, args);

IRpcFnc getGetCall(int handler, String name) => getFncItem(handler, name, null);

IRpcFnc getSetCall(int handler, String name, dynamic value) => getFncItem(handler, name, RpcFncTypes.setter, [value]);

Future<T> fncCall<T>(int? handler, String name, [List<dynamic>? args]) async {
  final res = await rpc([getFncCall(handler, name, args)]);
  return res[0] as T;
}

Future<T> getCall<T>(int handler, String name) async {
  final res = await rpc([getGetCall(handler, name)]);
  return res[0] as T;
}

Future setCall(int handler, String name, dynamic value) async {
  await rpc([getSetCall(handler, name, value)]);
}
