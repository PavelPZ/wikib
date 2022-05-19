@Timeout(Duration(seconds: 3600))

import 'dart:convert';

import 'package:webview_lib/webview_lib.dart';
import 'package:test/test.dart';

void main() {
  test('IRpcResult', () async {
    final objs = <IRpcResult>[
      IRpcResult(rpcId: 1, error: null, result: 1),
      IRpcResult(rpcId: 1, error: null, result: 1.1),
      IRpcResult(rpcId: 1, error: null, result: ['x', 'y']),
      IRpcResult(rpcId: 1, error: null, result: {'a': 2}),
    ];
    for (var obj in objs) {
      final json = obj.toJson();
      final obj2 = IRpcResult.fromJson(json);
      final json2 = jsonEncode(obj2.toJson());
      expect(jsonEncode(json), json2);
    }
  });

  test('IStreamMessage', () async {
    final obj = IStreamMessage<IRpcResult<String>>(streamId: 1, handlerId: 2, value: IRpcResult<String>(rpcId: 3, result: 'xxxx', error: null));
    final json = obj.toJson();
    final obj2 = IStreamMessage<IRpcResult<String>>.fromJson(json);
    final json2 = obj2.toJson();
    expect(jsonEncode(json), jsonEncode(json2));
  });

  test('IRpc', () async {
    final arg = {
      'a1': 1,
      'a2': 1.1,
      'a3': false,
      'a4': 'a4',
      'a5': {'aa1': 'xxx'}
    };
    final obj = IRpc(rpcId: 1, fncs: [
      IRpcFnc(name: 'f1', type: null, arguments: []),
      IRpcFnc(name: 'f1', type: 2, arguments: [
        1,
        1.1,
        true,
        'xxx',
        arg,
        [1, 1.1, true, 'array']
      ]),
    ]);
    final json = obj.toJson();
    final obj2 = IRpc.fromJson(json);
    final json2 = jsonEncode(obj2.toJson());
    expect(jsonEncode(json), json2);
  });
}
