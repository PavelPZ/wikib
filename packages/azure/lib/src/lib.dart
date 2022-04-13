import 'dart:convert';

// import 'package:http/http.dart';
import 'package:tuple/tuple.dart';

class Key {
  Key(String? partition, String? row)
      : partition = Encoder.keys.encode(partition),
        row = Encoder.keys.encode(row);
  final String? partition;
  final String? row;
}

class BatchRow {
  BatchRow({required this.rowId, required this.data, required this.method});
  final int rowId;
  final Map<String, dynamic> data;
  String? eTag;
  final BatchMethod method;
  final versions = <int, int>{};
  // for azure store code
  int batchDataId = 0;
  ResponsePart? batchResponse;
  String toJson() => jsonEncode(data);
}

class AzureDataUpload {
  AzureDataUpload({required this.rows});
  final List<BatchRow> rows;
  // String? newETag;
  // Map<int, int> debugAllRowVersions() => Map<int, int>.fromEntries(rows.map((r) => r.versions.entries).expand((e) => e));
}

abstract class IStorage {
  AzureDataUpload? toAzureUpload();
  Future fromAzureRowUploaded(Map<int, int> versions);
  Future fromAzureETagUploaded(String eTag);
}

typedef AzureDataDownload = Map<String, Map<String, dynamic>>;

// ***************************************
// BOX KEY
// ***************************************

class BoxKey {
  const BoxKey(this.boxKey);
  const BoxKey.idx(int rowId, int propId)
      : assert(propId <= maxPropId),
        boxKey = (rowId << 8) + propId;
  factory BoxKey.azure(String rowId, String propId) => BoxKey.idx(_hex2Byte(rowId), _hex2Byte(propId));

  final int boxKey;
  int get rowId => boxKey >> 8;
  int get propId => boxKey & 0xff;

  BoxKey next() => propId < maxPropId ? BoxKey(boxKey + 1) : BoxKey.idx(rowId + 1, 0);

  //-------- statics

  static int nextKey(int key) {
    final rowId = key >> 8;
    final propId = key & 0xff;
    return propId < maxPropId ? key + 1 : (rowId + 1) << 8;
  }

  static String getRowKey(int key) => byte2Hex(key >> 8);
  static String getRowPropId(int key) => byte2Hex(key & 0xff);
  static int getBoxKey(int rowId, int propId) => (rowId << 8) + propId;
  static final eTagHiveKey = BoxKey.idx(0, 0);
  static final eTagKeyFakeVersion = 0xffffff;

  //-------- RowData
  String get rowKey => byte2Hex(rowId);
  String get rowPropId => byte2Hex(propId);

  static const maxPropId = 252;
  static const hexMap = <String>['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p'];
  static String byte2Hex(int b) => hexMap[(b >> 8) & 0xf] + hexMap[b & 0xf];
  static int _hex2Byte(String hex) => (byteMap[hex[0]]! << 8) + byteMap[hex[1]]!;
  static const byteMap = <String, int>{
    'a': 0,
    'b': 1,
    'c': 2,
    'd': 3,
    'e': 4,
    'f': 5,
    'g': 6,
    'h': 7,
    'i': 8,
    'j': 9,
    'k': 10,
    'l': 11,
    'm': 12,
    'n': 13,
    'o': 14,
    'p': 15
  };
}

enum BatchMethod {
  merge,
  put,
  delete,
}
const batchMethodName = <BatchMethod, String>{
  BatchMethod.merge: 'MERGE',
  BatchMethod.put: 'PUT',
  BatchMethod.delete: 'DELETE',
};

class ResponsePart {
  late int statusCode;
  late String reasonPhrase;
  final headers = <String, String>{};
  final body = StringBuffer();

  // https://docs.microsoft.com/en-us/rest/api/storageservices/performing-entity-group-transactions
  static Iterable<ResponsePart> parseResponse(String response) sync* {
    const crlf = '\r\n';
    const multipart = 'Content-Type: multipart/mixed; boundary=';
    final idx = response.indexOf(multipart);
    if (idx < 0) return;
    response = response.substring(idx + multipart.length);
    final lines = response.split(crlf);
    final changeSetStart = '--' + lines[0];
    final changeSetEnd = changeSetStart + '--';
    var state = 0;
    late ResponsePart part;
    for (final line in lines) {
      switch (state) {
        case 0: // before first changeSetStart
          if (line != changeSetStart) continue;
          state = 1;
          break;
        case 1: // after changeSetStart, before first epmty line
          if (line != '') continue;
          part = ResponsePart();
          yield part;
          state = 2;
          break;
        case 2: // on HTTP/1.1
          final parts = line.split(' ');
          assert(parts.length >= 3);
          assert(parts[0] == 'HTTP/1.1');
          part.statusCode = int.parse(parts[1]);
          part.reasonPhrase = parts.sublist(2).join(' ');
          state = 3;
          break;
        case 3: // headers
          if (line != '') {
            final parts = line.split(': ');
            assert(parts.length == 2);
            part.headers[parts[0]] = parts[1];
            continue;
          }
          state = 4;
          break;
        case 4: // body
          if (line == changeSetEnd) break;
          if (line != changeSetStart) {
            part.body.writeln(line);
            continue;
          }
          state = 1;
          break;
      }
    }
  }
}

int toIntLow(int dbId, int id) => (dbId << 27) + id;
Tuple2<int, int> fromIntLow(int i) => Tuple2<int, int>((i >> 27) & 0xf, i & 0x7ffffff);

class Encoder {
  Encoder._(this._d2Char, this._d4Char, this._validChars)
      : _d2 = _d2Char.codeUnitAt(0),
        _d4 = _d4Char.codeUnitAt(0) {
    _validCharDir = Map<int, bool>.fromIterable(_validChars.runes.where((ch) => ch != _d2 && ch != _d4), key: (ch) => ch, value: (ch) => true);
  }

  // static const lastKey = '~';
  static final keys = Encoder._('~', ';', '!\$&()*+,-.0123456789:;=@ABCDEFGHIJKLMNOPQRSTUVWXYZ[]_abcdefghijklmnopqrstuvwxyz~');
  static final tables = Encoder._('A', 'B', '0123456789abcdefghijklmnopqrstuvwxyz');

  final String _d2Char;
  final String _d4Char;
  final String _validChars;
  final int _d2;
  final int _d4;
  late Map<int, bool> _validCharDir;

  String? encode(String? val) {
    if (val == null) return null;
    final sb = StringBuffer();
    for (var i = 0; i < val.length; i++) {
      final ch = val.codeUnitAt(i);
      if (_validCharDir.containsKey(ch)) {
        sb.write(String.fromCharCode(ch));
        continue;
      }
      assert(ch <= 0xffff);
      // ~ef OR ;efef
      sb.write('${ch <= 0xff ? _d2Char : _d4Char}${ch.toRadixString(16).padLeft(ch <= 0xff ? 2 : 4, '0')}');
    }
    return sb.toString();
  }

  String decode(String val) {
    final sb = StringBuffer();
    var idx = 0;
    while (idx < val.length) {
      final ch = val[idx];
      if (ch == _d2Char) {
        sb.write(String.fromCharCode(int.parse(val.substring(idx + 1, idx + 3), radix: 16)));
        idx += 3;
      } else if (ch == _d4Char) {
        sb.write(String.fromCharCode(int.parse(val.substring(idx + 1, idx + 5), radix: 16)));
        idx += 5;
      } else {
        sb.write(ch);
        idx += 1;
      }
    }
    return sb.toString();
  }
}
