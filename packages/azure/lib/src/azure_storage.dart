part of 'azure.dart';

class TableStorage extends Azure {
  TableStorage({required TableAccount account}) : super(account: account);

  Future<bool> checkDeviceConflict() => Future.value(false);

  Future<AzureDataDownload> loadAll() => Future.value(AzureDataDownload());

  Future saveToCloud(IStorage storage, {ICancelToken? token}) async {
    List<AzureRequest>? getRequests(IStorage storage) {
      final data = storage.toAzureUpload();
      if (data == null) return null;

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
            if (row.eTag != null) {
              // not DELETE
              if (rowId == BoxKey.eTagHiveKey.rowId) {
                await storage.fromAzureETagUploaded(row.eTag!);
              } else
                await storage.fromAzureRowUploaded(row.versions);
            }
          }
        }
        code = max(code, resp.statusCode);
      }
      return code;
    }

    final sendRes = await send<void>(
      getRequests: () => getRequests(storage),
      token: token,
      finalizeResponse: (resp) async {
        // reponse OK, parse response string:
        final respStr = await resp.response!.stream.bytesToString();
        final AzureDataUpload data = resp.myRequest!.finalizeData;
        resp.error = ErrorCodes.computeStatusCode(await finishBatchRows(respStr, data));
        // await box
        if (resp.error != ErrorCodes.no) return ContinueResult.doRethrow;
        return ContinueResult.doBreak;
      },
    );
    if (token?.canceled == true) return null;
    if (sendRes != null && sendRes.error >= 400) throw sendRes;
  }

  Future<List<String>?> getAllRows(String partitionKey, {ICancelToken? token}) async {
    final query = Query.partition(partitionKey);
    query.select = <String>['RowKey'];
    final res = await queryLow(query);
    if (res == null || res.isEmpty) return null;
    final data = res.map((m) => m['RowKey'] as String).toList();
    assert(dpAzureMsg('TableStorage.getAllRows: ${data.join(',')}')());
    return data;
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
    if (method == BatchMethod.delete) subSb.writeln('If-Match: ${data.eTag ?? '*'}');
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
