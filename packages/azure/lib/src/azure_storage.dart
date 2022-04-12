part of 'azure.dart';

class TableStorage extends Azure {
  TableStorage({required TableAccount account}) : super(account: account);

  Future<bool> checkDeviceConflict() => Future.value(false);

  Future<AzureDataDownload> loadAll() => Future.value(AzureDataDownload());

  Future batch(IStorage storage, {CancelToken? token}) async {
    if (_batchIsRunning) return;
    _batchIsRunning = true;

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
          final row = data.rows[nextIndex];
          if (!batch.appendData(row)) break;
          row.batchDataId = nextIndex;
          nextIndex++;
        }

        request.bodyBytes = batch.getBody();
        requests.add(request);
      }
      return requests;
    }

    int finishBatchRows(String res, AzureDataUpload data) {
      final rowResponses = List<ResponsePart>.from(ResponsePart.parseResponse(res));
      var code = 0;
      for (final resp in rowResponses) {
        final row = data.rows[int.parse(resp.headers['Content-ID'] ?? '9999')];
        if (ErrorCodes.computeStatusCode(resp.statusCode) == ErrorCodes.no) storage.fromAzureUpload(row.versions);
        row.batchResponse = resp;
        row.eTag = resp.headers['ETag'];
        code = max(code, resp.statusCode);
      }
      return code;
    }

    try {
      await Future.microtask(() async {
        final sendRes = await send<void>(
          getRequests: () => getRequests(storage),
          token: token,
          finalizeResponse: (resp, token) async {
            if (resp.error != ErrorCodes.no) return ContinueResult.doRethrow;
            // reponse OK, parse response string:
            final respStr = await resp.response!.stream.bytesToString();
            if (token?.canceled == true) return ContinueResult.doRethrow;
            final AzureDataUpload data = resp.myRequest!.finalizeData;
            resp.error = ErrorCodes.computeStatusCode(finishBatchRows(respStr, data));
            if (resp.error != ErrorCodes.no) return ContinueResult.doRethrow;
            return ContinueResult.doBreak;
          },
        );
        if (token?.canceled == true) return null;
        if (sendRes!.error >= 400) throw sendRes;
      });
      if (token?.canceled == true) return null;
    } finally {
      _batchIsRunning = false;
    }
  }

  bool _batchIsRunning = false;

  // Future _sendRequest(AzureRequest request) async {
  //   int finishBatchRows(String res, AzureDataUpload data) {
  //     final rowResponses = List<ResponsePart>.from(ResponsePart.parseResponse(res));
  //     var code = 0;
  //     for (final resp in rowResponses) {
  //       // final row = data.rows[int.parse(resp.headers['Content-ID'] ?? '9999')];
  //       // row.batchResponse = resp;
  //       // row.eTag = resp.headers['ETag'];
  //       code = max(code, resp.statusCode);
  //     }
  //     return code;
  //   }

  //   try {
  //     final sendRes = await send<void>(
  //       request: request,
  //       finalizeResponse: (resp) async {
  //         if (resp.error != ErrorCodes.no) return ContinueResult.doRethrow;
  //         // reponse OK, parse response string:
  //         final respStr = await resp.response!.stream.bytesToString();
  //         final AzureDataUpload data = resp.myRequest!.finalizeData;
  //         resp.error = ErrorCodes.computeStatusCode(finishBatchRows(respStr, data));
  //         if (resp.error != ErrorCodes.no) return ContinueResult.doRethrow;
  //         return ContinueResult.doBreak;
  //       },
  //     );
  //     if (sendRes!.error >= 400) throw sendRes;
  //   } finally {
  //     _batchIsRunning = false;
  //   }
  // }

  // Future _batch(IStorage storage, {required SendPar sendPar}) async {
  //   AzureRequest? getBatchRequest(IStorage storage) {
  //     final data = storage.toAzureUpload();
  //     if (data == null) return null;
  //     final request = AzureRequest('POST', Uri.parse(account.uriConfig[1]), finalizeData: data);
  //     sign(request.headers, isBatch: true);

  //     final batch = BatchStorage(request, account.batchInnerUri!);
  //     for (var i = 0; i < data.rows.length; i++) if (!batch.appendData(data.rows[i]..batchDataId = i)) break;

  //     request.bodyBytes = batch.getBody();
  //     return request;
  //   }

  //   int finishBatchRows(String res, AzureDataUpload data) {
  //     final rowResponses = List<ResponsePart>.from(ResponsePart.parseResponse(res));
  //     var code = 0;
  //     for (final resp in rowResponses) {
  //       final row = data.rows[int.parse(resp.headers['Content-ID'] ?? '9999')];
  //       row.batchResponse = resp;
  //       row.eTag = resp.headers['ETag'];
  //       code = max(code, resp.statusCode);
  //     }
  //     return code;
  //   }

  //   try {
  //     final sendRes = await send<void>(
  //       getRequest: () => getBatchRequest(storage),
  //       sendPar: sendPar,
  //       finalizeResponse: (resp) async {
  //         if (resp.error != ErrorCodes.no) return ContinueResult.doRethrow;
  //         // reponse OK, parse response string:
  //         final respStr = await resp.response!.stream.bytesToString();
  //         final AzureDataUpload data = resp.myRequest!.finalizeData;
  //         resp.error = ErrorCodes.computeStatusCode(finishBatchRows(respStr, data));
  //         if (resp.error != ErrorCodes.no) return ContinueResult.doRethrow;
  //         //resp.result = respStr;
  //         return ContinueResult.doContinue;
  //       },
  //     );
  //     if (sendRes!.error >= 400) throw sendRes;
  //   } finally {
  //     _batchIsRunning = false;
  //   }
  // }

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
    if (data.eTag != null) subSb.writeln('If-Match: ${data.eTag}');
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
