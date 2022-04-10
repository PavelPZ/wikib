part of 'azure.dart';

class TableStorage extends Azure {
  TableStorage(String table, {bool? isEmulator}) : super._(table, isEmulator: isEmulator);

  Future batch(AzureDataUpload data, {SendPar? sendPar}) => runBatch(data, sendPar);

  //************* BATCH */
  AzureRequest getBatchRequest(List<BatchRow> data) {
    final request = AzureRequest('POST', Uri.parse(_uri[1]));
    _sign(request.headers, isBatch: true);

    final batch = BatchStorage(request, batchInnerUri!);
    for (var i = 0; i < data.length; i++) {
      batch.appendData(data[i]..batchDataId = i);
    }
    request.bodyBytes = batch.getBody();
    return request;
  }

  int finishBatchRows(String res, AzureDataUpload data) {
    final rowResponses = List<ResponsePart>.from(ResponsePart.parseResponse(res));
    var code = 0;
    for (final resp in rowResponses) {
      final row = data.rows[int.parse(resp.headers['Content-ID'] ?? '9999')];
      row.batchResponse = resp;
      row.eTag = resp.headers['ETag'];
      code = max(code, resp.statusCode);
    }
    return code;
  }

  Future runBatch(AzureDataUpload data, SendPar? sendPar) async {
    for (var i = 0; i < data.rows.length; i += 100) {
      final request = getBatchRequest(List<BatchRow>.from(data.rows.skip(i).take(100)));
      final sendRes = await send<String>(
          request: request,
          sendPar: sendPar,
          finalizeResponse: (resp) async {
            if (resp.error != ErrorCodes.no) return ContinueResult.doRethrow;
            // reponse OK, parse response string:
            final respStr = await resp.response!.stream.bytesToString();
            resp.error = ErrorCodes.computeStatusCode(finishBatchRows(respStr, data));
            if (resp.error != ErrorCodes.no) return ContinueResult.doRethrow;
            resp.result = respStr;
            return ContinueResult.doBreak;
          });
      if (sendRes!.error >= 400) throw sendRes;
    }
  }
}

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

  static String batchKeyUrlPart(BatchRow data) => '(PartitionKey=\'${data.data['PartitionKey']}\',RowKey=\'${data.data['RowKey']}\')';

  void appendData(BatchRow data) {
    _sb.writeln('--$_changesetId');
    _sb.writeln('Content-Type: application/http');
    _sb.writeln('Content-Transfer-Encoding: binary');
    _sb.writeln();
    final method = data.method;
    final methodName = batchMethodName[method];
    _sb.writeln('$methodName $_innerBatchUri${batchKeyUrlPart(data)} HTTP/1.1');
    if (data.eTag != null) _sb.writeln('If-Match: ${data.eTag}');
    _sb.writeln('Content-ID: ${data.batchDataId}');
    _sb.writeln('Accept: application/json;odata=nometadata');
    _sb.writeln('Content-Type: application/json');
    // if (data.eTag != null) _sb.writeln('ETag: ${data.eTag}');
    //assert((method == 'DELETE') == (data == null));
    if (method != BatchMethod.delete) {
      _sb.writeln();
      _sb.writeln(data.toJson());
    } else {
      _sb.writeln('Content-Length: 0');
      _sb.writeln();
    }
  }

  List<int> getBody() {
    final str = _getBodyStr();
    final res = utf8.encode(str);
    final len = res.length;
    // https://support.microsoft.com/cs-cz/help/4016806/the-request-body-is-too-large-error-when-writing-data-to-azure-file
    if (len > 4000000) throw Exception('Azure request limit');
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
