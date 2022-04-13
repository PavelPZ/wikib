import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:azure/azure.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart';
import 'package:utils/utils.dart';

import 'lib.dart';

part 'azure_storage.dart';
part 'azure_sender.dart';

class AzureAccounts {
  const AzureAccounts({
    this.emulatorAccount =
        const AzureAccount._('devstoreaccount1', 'Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw=='),
    this.cloudAccount =
        const AzureAccount._('wikibularydata', 'm8so0vlCxtzpPMIu3IeQox+mtlqw4m/a0OALvXkvdgH1/zi5ZJHfmicIfwFAZXbOsZxlb2eDdlLREWKdjh4UWg=='),
  });
  final AzureAccount emulatorAccount;
  final AzureAccount cloudAccount;
}

class AzureAccount {
  const AzureAccount._(this.accountName, this.keyStr);
  final String accountName;
  final String keyStr;
}

class TableAccount {
  // factory Account({bool? isEmulator}) => isEmulator == true ? _emulatorAccount : _debugCloudAccount;
  TableAccount({required AzureAccounts azureAccounts, required String tableName, bool isEmulator = false}) {
    azureAccount = isEmulator ? azureAccounts.emulatorAccount : azureAccounts.cloudAccount;
    key = base64.decode(azureAccount.keyStr);

    final host = isEmulator ? 'http://127.0.0.1:10002' : 'https://${azureAccount.accountName}.table.core.windows.net';
    batchInnerUri = host + (isEmulator ? '/${azureAccount.accountName}/$tableName' : '/$tableName');

    for (var idx = 0; idx < 2; idx++) {
      final signatureTable = idx == 1 ? '\$batch' : tableName;
      final slashAcountTable = '/${azureAccount.accountName}/$signatureTable';
      signaturePart[idx] = (isEmulator ? '/${azureAccount.accountName}' : '') + slashAcountTable; // second part of signature
      uriConfig[idx] = host + (isEmulator ? slashAcountTable : '/$signatureTable');
    }
  }
  late AzureAccount azureAccount;
  late Uint8List key;

  final signaturePart = ['', ''];
  final uriConfig = ['', ''];
  late String? batchInnerUri;

  static TableAccount debugGetAccount(String tableName, bool isEmulator) =>
      TableAccount(azureAccounts: const AzureAccounts(), tableName: tableName, isEmulator: isEmulator);
}

class Azure extends Sender {
  Azure({required this.account});

  final TableAccount account;

  // https://stackoverflow.com/questions/26066640/windows-azure-rest-api-sharedkeylite-authentication-storage-emulator
  // https://docs.microsoft.com/cs-cz/rest/api/storageservices/authorize-with-shared-key
  void sign(Map<String, String> headers, {String? uriAppend, bool? isBatch}) {
    // RFC1123 format
    final String dateStr = HttpDate.format(DateTime.now());
    final String signature = '$dateStr\n${account.signaturePart[isBatch == true ? 1 : 0]}${uriAppend ?? ''}';
    final toHash = utf8.encode(signature);
    final hmacSha256 = Hmac(sha256, account.key); // HMAC-SHA256
    final token = base64.encode(hmacSha256.convert(toHash).bytes);
    // Authorization header
    final String strAuthorization = 'SharedKeyLite ${account.azureAccount.accountName}:$token';

    headers['Authorization'] = strAuthorization;
    headers['x-ms-date'] = dateStr;
    // headers['x-ms-version'] = '2018-03-28';
    headers['x-ms-version'] = '2021-04-10';
  }

  Future<String?> writeBytesRequest(List<int>? bytes, String method,
      {String? eTag, SendPar? sendPar, String? uriAppend, void finishHttpRequest(AzureRequest req)?, ICancelToken? token}) async {
    final String uri = account.uriConfig[0] + (uriAppend ?? '');
    // Web request
    final request = AzureRequest(method, Uri.parse(uri));
    sign(request.headers, uriAppend: uriAppend);
    request.headers['Accept'] = 'application/json;odata=nometadata';
    request.headers['Content-type'] = 'application/json';
    if (eTag != null) request.headers['If-Match'] = eTag;
    if (bytes != null) request.bodyBytes = bytes;
    if (finishHttpRequest != null) finishHttpRequest(request);

    final sendRes = await send<String>(
        request: request,
        sendPar: sendPar,
        token: token,
        finalizeResponse: (resp) {
          if (resp.error != ErrorCodes.no) return Future.value(ContinueResult.doRethrow);
          resp.result = resp.response!.headers['etag'];
          return Future.value(ContinueResult.doBreak);
        });
    if (token?.canceled == true) return null;

    return sendRes?.result;
  }

  static const nextPartitionName = 'NextPartitionKey';
  static const nextRowName = 'NextRowKey';
  static const msContinuation = 'x-ms-continuation-';
  static final nextPartitionPar = msContinuation + nextPartitionName.toLowerCase();
  static final nextRowPar = msContinuation + nextRowName.toLowerCase();

  Future<List<dynamic>> queryLow<T>(Query? query, {SendPar? sendPar, ICancelToken? token}) async {
    final request = queryRequest(query: query);
    var nextPartition = '';
    var nextRow = '';
    final oldUrl = request.uri.toString();

    AzureRequest getRequest() {
      if (nextPartition == '' && nextRow == '') return request;
      var newUrl = oldUrl;
      if (nextPartition != '') newUrl += '&$nextPartitionName=$nextPartition';
      if (nextRow != '') newUrl += '&$nextRowName=$nextRow';
      request.uri = Uri.parse(newUrl);
      return request;
    }

    final resp = await send<List<dynamic>>(
        sendPar: sendPar,
        getRequest: getRequest,
        token: token,
        finalizeResponse: (resp) async {
          if (resp.error != ErrorCodes.no) return ContinueResult.doRethrow;
          final resStr = await resp.response!.stream.bytesToString();
          final resList = jsonDecode(resStr)['value'];
          assert(resList != null);
          (resp.result ??= <dynamic>[]).addAll(resList);
          nextPartition = resp.response!.headers[nextPartitionPar] ?? '';
          nextRow = resp.response!.headers[nextRowPar] ?? '';
          return nextPartition == '' && nextRow == '' ? ContinueResult.doBreak : ContinueResult.doContinue;
        });
    if (token?.canceled == true) return <dynamic>[];

    return resp!.result!;
  }

  // entity x table query
  AzureRequest queryRequest({Query? query, Key? key /*, SendPar? sendPar*/}) {
    final uriAppend = key == null ? '()' : '(PartitionKey=\'${key.partition}\',RowKey=\'${key.row}\')';
    final queryString = key == null ? (query ?? Query()).queryString() : '';
    var uri = account.uriConfig[0] + uriAppend;
    if (queryString.isNotEmpty) uri += '?$queryString';
    final request = AzureRequest('GET', Uri.parse(uri));
    sign(request.headers, uriAppend: uriAppend);
    request.headers['Accept'] = 'application/json;odata=nometadata';
    return request;
  }
}

enum QO { eq, gt, ge, lt, le, ne }

class Q {
  Q(this.key, String? value, [QO? o])
      : o = o ?? QO.eq,
        value = _encodeValue(key, value);
  Q.p(String value, [QO? o]) : this('PartitionKey', value, o);
  Q.r(String value, [QO? o]) : this('RowKey', value, o);
  final String key;
  final String? value;
  final QO o;
  @override
  String toString() => '$key ${o.toString().split('.').last} \'$value\'';
  static String? _encodeValue(String key, String? value) {
    if (value == null) return null;
    if (key == 'PartitionKey' || key == 'RowKey') return Encoder.keys.encode(value);
    return value.replaceAll('\'', '\'\'');
  }
}

class Query {
  Query({String? filter, List<String>? select, int? top}) : this._(filter, select, top);
  Query.partition(String partitionKey, {int? top}) : this._('${Q.p(partitionKey)}', null, top);
  Query.property(String partitionKey, String rowKey, String propName) : this._('${Q.p(partitionKey)} and ${Q.r(rowKey)}', [propName], null);
  Query._(this._filter, this.select, this._top);
  final String? _filter;
  List<String>? select;
  final int? _top;

  String queryString() {
    final sb = StringBuffer();
    if (_filter != null) sb.write('\$filter=${Uri.encodeFull(_filter!)}');
    if (_top != null) {
      if (sb.length > 0) sb.write('&');
      sb.write('\$top=$_top');
    }
    if (select != null && select!.isNotEmpty) {
      if (sb.length > 0) sb.write('&');
      sb.write('\$select=');
      var first = true;
      for (final p in select!) {
        if (!first) sb.write(',');
        first = false;
        sb.write(p);
      }
    }
    return sb.toString();
  }
}
