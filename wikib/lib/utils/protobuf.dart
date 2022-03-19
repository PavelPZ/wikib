import 'dart:convert';
import 'dart:typed_data';
import 'package:protobuf/protobuf.dart' as $pb;

abstract class Protobuf {
  static T fromStr<T extends $pb.GeneratedMessage>(String data, T create()) {
    final res = create();
    res.mergeFromProto3Json(jsonDecode(data));
    return res;
  }

  static String toStr($pb.GeneratedMessage msg) => jsonEncode(msg.toProto3Json());

  static T fromBytes<T extends $pb.GeneratedMessage>(List<int> data, T create()) {
    final res = create();
    res.mergeFromBuffer(data);
    return res;
  }

  static T fromBytesNull<T extends $pb.GeneratedMessage>(List<int>? data, T create()) {
    final res = create();
    if (data != null) res.mergeFromBuffer(data);
    return res;
  }

  static Uint8List toBytes($pb.GeneratedMessage msg) => msg.writeToBuffer();
}
