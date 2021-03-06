// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'interface.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IStreamMessage _$IStreamMessageFromJson(Map<String, dynamic> json) =>
    IStreamMessage(
      streamId: json['streamId'] as int,
      handlerId: json['handlerId'] as int?,
      value: json['value'],
    );

Map<String, dynamic> _$IStreamMessageToJson(IStreamMessage instance) =>
    <String, dynamic>{
      'streamId': instance.streamId,
      'handlerId': instance.handlerId,
      'value': instance.value,
    };

IRpcResult _$IRpcResultFromJson(Map<String, dynamic> json) => IRpcResult(
      rpcId: json['rpcId'] as int,
      result: json['result'],
      error: json['error'] as String?,
    );

Map<String, dynamic> _$IRpcResultToJson(IRpcResult instance) =>
    <String, dynamic>{
      'rpcId': instance.rpcId,
      'result': instance.result,
      'error': instance.error,
    };

IRpcFnc _$IRpcFncFromJson(Map<String, dynamic> json) => IRpcFnc(
      name: json['name'] as String,
      type: json['type'] as int?,
      arguments: json['arguments'] as List<dynamic>,
    );

Map<String, dynamic> _$IRpcFncToJson(IRpcFnc instance) => <String, dynamic>{
      'name': instance.name,
      'type': instance.type,
      'arguments': instance.arguments,
    };

IRpc _$IRpcFromJson(Map<String, dynamic> json) => IRpc(
      rpcId: json['rpcId'] as int,
      fncs: (json['fncs'] as List<dynamic>)
          .map((e) => IRpcFnc.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$IRpcToJson(IRpc instance) => <String, dynamic>{
      'rpcId': instance.rpcId,
      'fncs': instance.fncs.map((e) => e.toJson()).toList(),
    };
