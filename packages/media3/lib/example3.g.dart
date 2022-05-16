// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'example3.dart';

// **************************************************************************
// FunctionalWidgetGenerator
// **************************************************************************

class MyApp extends ConsumerWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext _context, WidgetRef _ref) => myApp(_ref);
}

class WebView extends HookConsumerWidget {
  const WebView({Key? key, this.child}) : super(key: key);

  final Widget? child;

  @override
  Widget build(BuildContext _context, WidgetRef _ref) =>
      webView(_ref, child: child);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IStreamItem _$IStreamItemFromJson(Map<String, dynamic> json) => IStreamItem(
      streamId: json['streamId'] as int,
      value: json['value'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$IStreamItemToJson(IStreamItem instance) =>
    <String, dynamic>{
      'streamId': instance.streamId,
      'value': instance.value,
    };

IPromiseStreamValue _$IPromiseStreamValueFromJson(Map<String, dynamic> json) =>
    IPromiseStreamValue(
      promiseId: json['promiseId'] as int,
      error: json['error'] as String?,
      result: json['result'] as int?,
    );

Map<String, dynamic> _$IPromiseStreamValueToJson(
        IPromiseStreamValue instance) =>
    <String, dynamic>{
      'promiseId': instance.promiseId,
      'result': instance.result,
      'error': instance.error,
    };
