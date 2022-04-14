part of 'azure_ex.dart';

typedef CreateFromMap<T extends RowData> = T Function(Map<String, dynamic> map);

class Table<T extends RowData> extends Azure {
  Table({required TableAccount account, this.createFromMap = RowData.create}) : super(account: account);

  Future<List<T>> query(Query query, {SendPar? sendPar}) async {
    final res = await queryLow(query, sendPar: sendPar);
    return res == null ? <T>[] : List<T>.from(res.map((map) => createFromMap(map)));
  }

  final CreateFromMap createFromMap;

  Future<T?> read(Key key, {SendPar? sendPar}) async {
    final tup = await readLow(key, sendPar: sendPar);
    final res = tup == null ? null : (createFromMap(tup.item1)..eTag = tup.item2);
    return res as T?;
  }

  Future<Tuple2<Map<String, dynamic>, String>?> readLow(Key key, {SendPar? sendPar}) async {
    final request = queryRequest(key: key);

    final res = await send<Tuple2<Map<String, dynamic>, String>>(
        request: request,
        sendPar: sendPar,
        finalizeResponse: (resp) async {
          if (resp.error == ErrorCodes.notFound) return ContinueResult.doBreak; // => doBreak with null result
          if (resp.error != ErrorCodes.no) return ContinueResult.doRethrow;
          final json = await resp.response!.stream.bytesToString();
          final map = jsonDecode(json);
          resp.result = Tuple2<Map<String, dynamic>, String>(map, resp.response!.headers['etag']!);
          return ContinueResult.doBreak;
        });
    return res!.result;
  }

  Future insert(T data) async =>
      data.eTag = await writeBytesRequest(data.toJsonBytes(), 'POST', finishHttpRequest: (req) => req.headers['Prefer'] = 'return-no-content');

  Future insertOrReplace(T data) => _writeRowRequest(data, 'PUT');
  Future insertOrMerge(T data) => _writeRowRequest(data, 'MERGE');
  Future update(T data) => _writeRowRequest(data, 'PUT');
  Future merge(T data) => _writeRowRequest(data, 'MERGE');
  Future delete(T data) => _writeRowRequest(data, 'DELETE');

  // entity Insert x Update x Delete, ...
  Future _writeRowRequest(RowData data, String method, {SendPar? sendPar}) async {
    final res = await writeBytesRequest(data.toJsonBytes(), method, eTag: data.eTag, sendPar: sendPar, uriAppend: data.keyUrlPart());
    data.eTag = res;
  }
}
