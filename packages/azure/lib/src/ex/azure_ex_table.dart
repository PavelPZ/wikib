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
