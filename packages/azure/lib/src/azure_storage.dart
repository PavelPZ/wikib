part of 'azure.dart';

class TableStorage extends Azure {
  TableStorage({required TableAccount account, required this.partitionKey}) : super(account: account);

  String partitionKey;
  Future<bool> checkDeviceConflict() => Future.value(false);

  Future<Map<String, Map<String, dynamic>>> loadAll() => Future.value(<String, Map<String, dynamic>>{});

  Future saveToCloud(IStorage storage) async {
    List<AzureRequest>? getRequests(IStorage storage, {required bool alowFirstRowOnly}) {
      final data = storage.toAzureUpload();
      if (data == null || (!alowFirstRowOnly && data.rows.length <= 1)) return null;

      var nextIndex = 0;
      final requests = <AzureRequest>[];

      while (nextIndex < data.rows.length) {
        final request = AzureRequest('POST', Uri.parse(account.uriConfig[1]), finalizeData: data);
        sign(request.headers, isBatch: true);

        final batch = BatchStorage(request, account.batchInnerUri!);

        while (nextIndex < data.rows.length) {
          final row = data.rows[nextIndex]..batchDataId = nextIndex;
          if (!batch.appendData(row)) break;
          nextIndex++;
        }

        request.bodyBytes = batch.getBody();
        requests.add(request);
      }
      return requests;
    }

    Future<int> finishBatchRows(String res, AzureDataUpload data) async {
      final rowResponses = List<ResponsePart>.from(ResponsePart.parseResponse(res));
      assert(dpAzureMsg(
          'TableStorage.finishBatchRows: ${rowResponses.map((e) => '${int.parse(e.headers['Content-ID'] ?? '9999')}-${e.statusCode}').join(',')}')());
      var code = 0;
      for (final resp in rowResponses) {
        final isError = ErrorCodes.computeStatusCode(resp.statusCode) != ErrorCodes.no;
        final rowId = int.parse(resp.headers['Content-ID'] ?? '9999');
        if (rowId != 9999) {
          final row = data.rows[rowId];
          row.batchResponse = resp;
          row.eTag = resp.headers['ETag'];
          if (!isError) {
            if (row.eTag != null && rowId == BoxKey.eTagHiveKey.rowId)
              await storage.fromAzureUploadedETag(row.eTag!);
            else
              await storage.fromAzureUploadedRow(row.versions);
          }
        }
        code = max(code, resp.statusCode);
      }
      return code;
    }

    final sendRes = await send<dynamic>(
      getRequests: (alowFirstRowOnly) => getRequests(storage, alowFirstRowOnly: alowFirstRowOnly),
      finalizeResponse: (resp) async {
        final respStr = await resp.response!.stream.bytesToString();
        final AzureDataUpload data = resp.myRequest!.finalizeData;
        resp.error = ErrorCodes.computeStatusCode(await finishBatchRows(respStr, data));
        switch (resp.error) {
          case ErrorCodes.eTagConflict:
            await storage.onETagConflict();
            // if (canceled) return ContinueResult.doBreak;
            return ContinueResult.doBreak;
          case ErrorCodes.no:
            return ContinueResult.doContinue;
          default:
            return ContinueResult.doRethrow;
        }
      },
    );
    if (canceled) return null;
    if (sendRes == null) return;
    if (sendRes.error != ErrorCodes.eTagConflict && sendRes.error >= 400) throw sendRes;
  }

  Future<List<String>?> getAllRowKeys(String partitionKey) async {
    final query = Query.partition(partitionKey);
    query.select = <String>['RowKey'];
    final res = await queryLow(query);
    if (res == null || res.isEmpty) return null;
    final data = res.map((m) => m['RowKey'] as String).toList();
    assert(dpAzureMsg('TableStorage.getAllRows: ${data.join(',')}')());
    return data;
  }

  Future<String?> getETag(String partitionKey) async {
    final row = await readLow(Key(partitionKey, BoxKey.eTagHiveKey.rowKey));
    return row == null ? null : row.item2;
  }

  Future<WholeAzureDownload?> getAllRows(String partitionKey) async {
    final res = WholeAzureDownload();
    final etag = await getETag(partitionKey);
    if (etag == null) return null;
    res.eTag = etag;
    final query = Query.partition(partitionKey);
    final rows = await queryLow(query);
    if (rows == null || rows.isEmpty) return null;
    for (var row in rows) {
      if (row['RowKey'] == BoxKey.eTagHiveKey.rowKey) continue;
      res.rows.add(row);
    }
    return res;
  }
}

const maxAzureRequestLen = 4000000;

class BatchStorage {
  BatchStorage(this._request, this._innerBatchUri) {
    _request.headers['Content-Type'] = 'multipart/mixed; boundary=$_batchId';
    _sb.writeln('--$_batchId');
    _sb.writeln('Content-Type: multipart/mixed; boundary=$_changesetId');
    _sb.writeln();
  }
  final AzureRequest _request;
  final String _innerBatchUri;
  final String _batchId = 'batch_${_nextId()}';
  final String _changesetId = 'changeset_${_nextId()}';
  final _sb = StringBuffer();
  var encodedLen = 0;

  static String batchKeyUrlPart(BatchRow data) => '(PartitionKey=\'${data.data['PartitionKey']}\',RowKey=\'${data.data['RowKey']}\')';

  bool appendData(BatchRow data) {
    final subSb = StringBuffer();
    subSb.writeln('--$_changesetId');
    subSb.writeln('Content-Type: application/http');
    subSb.writeln('Content-Transfer-Encoding: binary');
    subSb.writeln();
    final method = data.method;
    final methodName = batchMethodName[method];
    subSb.writeln('$methodName $_innerBatchUri${batchKeyUrlPart(data)} HTTP/1.1');
    if (method == BatchMethod.delete || !isNullOrEmpty(data.eTag)) subSb.writeln('If-Match: ${data.eTag ?? '*'}');
    subSb.writeln('Content-ID: ${data.batchDataId}');
    subSb.writeln('Accept: application/json;odata=nometadata');
    subSb.writeln('Content-Type: application/json');
    if (method != BatchMethod.delete) {
      subSb.writeln();
      subSb.writeln(data.toJson());
    } else {
      subSb.writeln('Content-Length: 0');
      subSb.writeln();
    }
    final sub = subSb.toString();
    final encoded = utf8.encode(sub).length;
    if (encodedLen + encoded > maxAzureRequestLen) return false;
    encodedLen += encoded;
    _sb.write(sub);
    return true;
  }

  List<int> getBody() {
    final str = _getBodyStr();
    final res = utf8.encode(str);
    final len = res.length;
    // https://support.microsoft.com/cs-cz/help/4016806/the-request-body-is-too-large-error-when-writing-data-to-azure-file
    assert(len < maxAzureRequestLen);
    return res;
  }

  String _getBodyStr() {
    _sb.writeln('--$_changesetId--');
    _sb.writeln('--$_batchId--');
    return _sb.toString();
  }

  // static final _uuid = Uuid();
  // static String _nextId() => _uuid.v4();
  static var _uuid = 0;
  static String _nextId() => (_uuid++).toString();
}
