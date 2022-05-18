import 'package:json_annotation/json_annotation.dart';

// flutter pub run build_runner watch --delete-conflicting-outputs
part 'interface.g.dart';

class Platforms {
  static const none = 0;
  static const web = 1;
  static const mobile = 2;
  static const windows = 3;
  // todo
  static const macOS = 4;
  static const linux = 5;
}

class StreamIds {
  static const none = 0;
  static const promiseCallback = 1;
  static const consoleLog = 2;
  static const playerReadyState = 5;
  static const playerError = 6;
  static const playState = 7;
  static const playPosition = 8;
  static const playDurationchange = 9;
}

@JsonSerializable(explicitToJson: true)
class IStreamMessage<T> {
  IStreamMessage({required this.streamId, required this.name, required this.value});
  final int streamId;
  final int? name;
  @JsonKey(fromJson: _fromJson, toJson: _toJson)
  final T value;
  factory IStreamMessage.fromJson(Map<String, dynamic> json) => _$IStreamMessageFromJson(json);
  Map<String, dynamic> toJson() => _$IStreamMessageToJson(this);

  static T _fromJson<T>(Object json) {
    if (T == IRpcResult<String>)
      return IRpcResult<String>.fromJson(json as Map<String, dynamic>) as T;
    else if (T == IRpcResult<int>) return IRpcResult<int>.fromJson(json as Map<String, dynamic>) as T;
    return json as T;
  }

  static Object _toJson<T>(T object) {
    if (object is IRpcResult) return object.toJson();
    return object as Object;
  }
}

@JsonSerializable(explicitToJson: true)
class IRpcResult<T> {
  IRpcResult({required this.rpcId, required this.result, required this.error});
  final int rpcId;
  @JsonKey(fromJson: _fromJson, toJson: _toJson)
  final T? result;
  final String? error;
  factory IRpcResult.fromJson(Map<String, dynamic> json) => _$IRpcResultFromJson(json);
  Map<String, dynamic> toJson() => _$IRpcResultToJson(this);

  static T _fromJson<T>(Object json) => json as T;
  static Object _toJson<T>(T object) => object as Object;
}

class RpcFncTypes {
  static const getter = 0;
  static const setter = 1;
}

@JsonSerializable(explicitToJson: true)
class IRpcFnc {
  IRpcFnc({required this.name, required this.type, required this.arguments});
  final String name;
  final int? type;
  final List<dynamic> arguments;

  factory IRpcFnc.fromJson(Map<String, dynamic> json) => _$IRpcFncFromJson(json);
  Map<String, dynamic> toJson() => _$IRpcFncToJson(this);
}

@JsonSerializable(explicitToJson: true)
class IRpc {
  IRpc({required this.rpcId, required this.fncs});
  final int rpcId;
  final List<IRpcFnc> fncs;

  factory IRpc.fromJson(Map<String, dynamic> json) => _$IRpcFromJson(json);
  Map<String, dynamic> toJson() => _$IRpcToJson(this);
}
