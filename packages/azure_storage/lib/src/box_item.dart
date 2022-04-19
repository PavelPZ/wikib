part of 'storage.dart';

abstract class BoxItem<T> extends HiveObject {
  @HiveField(0, defaultValue: 0)
  int key = 0;

  T get value;
  set value(T v);

  @HiveField(2, defaultValue: 0)
  int version = 0;

  @HiveField(3, defaultValue: false)
  bool isDeleted = false;

  @HiveField(4, defaultValue: false)
  bool isDefered = false;

  void toAzureUpload(Map<String, dynamic> data) => data[BoxKey.getPropKey(key)] = value;
}

@HiveType(typeId: 1)
class BoxInt extends BoxItem<int> {
  @override
  @HiveField(1, defaultValue: 0)
  int value = 0;
}

@HiveType(typeId: 2)
class BoxString extends BoxItem<String> {
  @override
  @HiveField(1, defaultValue: '')
  String value = '';
}

abstract class BoxMsg<T extends $pb.GeneratedMessage> extends BoxItem<Uint8List?> {
  T msgCreator();
  void setMsgId(T msg, int id);

  T? get msg {
    rAssert(!isDeleted);
    if (_msg != null) return _msg!;
    assert(value != null);
    _msg = Protobuf.fromBytes(value!, msgCreator);
    return _msg!;
  }

  set msg(T? v) {
    rAssert(!isDeleted);
    _msg = v;
    assert(_msg != null);
    value = Protobuf.toBytes(_msg!);
  }

  T? _msg;

  @override
  void toAzureUpload(Map<String, dynamic> data) {
    final propKey = BoxKey.getPropKey(key);
    data[propKey] = base64.encode(value!);
    data['$propKey@odata.type'] = 'Edm.Binary';
  }

  @override
  @HiveField(1, defaultValue: null)
  Uint8List? value;
}
