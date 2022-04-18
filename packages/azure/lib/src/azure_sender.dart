part of 'azure.dart';

abstract class IRetries {
  const IRetries();
  int nextMSec();
  Future<int> delay() async {
    final msecs = nextMSec();
    if (msecs < 0) return -msecs;
    print('delayed: $msecs');
    await Future.delayed(Duration(milliseconds: msecs));
    return 0;
  }
}

class AzureRequest {
  AzureRequest(this.method, this.uri, {this.finalizeData});
  final dynamic finalizeData;
  final headers = <String, String>{};
  Uri uri;
  String method;
  List<int>? bodyBytes;
  Request toHttpRequest() {
    final res = Request(method, uri)..headers.addEntries(headers.entries);
    if (bodyBytes != null) res.bodyBytes = bodyBytes!;
    return res;
  }
}

class AzureResponse<T> {
  // input
  StreamedResponse? response;
  int error = ErrorCodes.no;
  ContinueResult continueResult = ContinueResult.doBreak;
  String? errorReason;
  Exception? errorDetail;
  AzureRequest? myRequest;

  // output
  T? result;
}

typedef FinishRequest = void Function(AzureRequest req);
typedef FinalizeResponse<T> = Future<ContinueResult> Function(AzureResponse<T> resp);
// order matter, see selectResponse bellow
enum ContinueResult { doBreak, doContinue, doWait, doRethrow }

class ErrorCodes {
  ErrorCodes._();
  static const no = 0;
  static const notFound = 404; // EntityNotFound, TableNotFound
  static const conflict = 409; // EntityAlreadyExists, TableAlreadyExists, TableBeingDeleted
  static const eTagConflict = 412; // Precondition Failed
  static const otherHttpSend = 600; // other statusCode >= 400, other than 404, 409, 412
  static const bussy = 500; // 500, 503, 504

  static const noInternet = 601;
  static const exception1 = 602;
  static const exception2 = 603;
  static const timeout = 604;

  static const canceled = 605;

  static int computeStatusCode(int statusCode) {
    switch (statusCode) {
      case conflict:
      case notFound:
      case eTagConflict:
        return statusCode;
      case 500:
      case 503:
      case 504:
        return bussy;
      default:
        return statusCode < 400 ? 0 : throw (otherHttpSend);
    }
  }

  static void statusCodeToResponse(AzureResponse resp) {
    resp.error = computeStatusCode(resp.response!.statusCode);
    resp.errorReason = resp.response!.reasonPhrase;
  }

  static void exceptionToResponse(AzureResponse resp, Exception e) {
    final res = e.toString();
    final match = _regExp.firstMatch(res);
    if (match == null) {
      resp.error = exception1;
      resp.errorReason = res;
    } else {
      resp.error = exception2;
      resp.errorReason = 'errno=${match.group(1)}';
    }
  }
}

final _regExp = RegExp(
  r'^.*errno.*?([0-9]+).*$',
  caseSensitive: false,
  multiLine: true,
);

class SendPar {
  SendPar({this.retries, this.debugSimulateLongRequest = 0, this.exceptionToResponse});
  IRetries? retries;
  final int debugSimulateLongRequest; // simulate long-time Http request
  final void Function(AzureResponse resp, Exception e)? exceptionToResponse;
}

abstract class Sender {
  Future? _running;
  Completer? _runningCompleter;
  Future flush() => _running ?? Future.value();

  Future<AzureResponse<T>?> send<T>({
    AzureRequest? request,
    List<AzureRequest>? getRequests(bool alowFirstRowOnly)?,
    AzureRequest? getRequest()?,
    required FinalizeResponse<T> finalizeResponse,
    SendPar? sendPar,
    ICancelToken? token,
  }) async {
    assert(((request == null ? 0 : 1) + (getRequest == null ? 0 : 1) + (getRequests == null ? 0 : 1)) == 1);
    if (_runningCompleter != null) return null;
    _runningCompleter = Completer();
    _running = _runningCompleter!.future;
    final sp = sendPar ?? SendPar();
    sp.retries ??= RetriesSimple._instance;
    try {
      final res = await Future.microtask(() async {
        final ress = await _send<T>(
          request: request,
          getRequests: getRequests,
          getRequest: getRequest,
          finalizeResponse: finalizeResponse,
          sendPar: sp,
          token: token,
        );
        return ress;
      });
      return res;
    } finally {
      _runningCompleter!.complete();
      _runningCompleter = null;
      _running = null;
    }
  }

  Future<AzureResponse<T>?> _send<T>({
    AzureRequest? request,
    List<AzureRequest>? getRequests(bool alowFirstRowOnly)?,
    AzureRequest? getRequest()?,
    required FinalizeResponse<T> finalizeResponse,
    required SendPar sendPar,
    ICancelToken? token,
  }) async {
    // not cancelable between "await client.send" and "await finalizeResponse(resp)"
    Future<AzureResponse<T>> getContinueResult(AzureRequest req, AzureResponse<T> resp, bool internetOK) async {
      final client = Client();
      try {
        if (!internetOK) {
          resp.error = ErrorCodes.noInternet;
        } else {
          try {
            assert(dpCounter('send attempts'));

            resp.response = await client.send(req.toHttpRequest());

            if (sendPar.debugSimulateLongRequest > 0) await Future.delayed(Duration(milliseconds: sendPar.debugSimulateLongRequest));
            ErrorCodes.statusCodeToResponse(resp);
          } on Exception catch (e) {
            if (!await connectedByOne4()) {
              resp.error = ErrorCodes.noInternet;
            } else {
              ErrorCodes.exceptionToResponse(resp, e);
            }
          }
        }
        assert(resp.error != ErrorCodes.no || resp.response != null);

        assert(resp.error != ErrorCodes.no || dpCounter('send_ok'));
        assert(resp.error == ErrorCodes.no || (dpCounter('send_error') && dpCounter(resp.errorReason ?? resp.error.toString())));

        switch (resp.error) {
          case ErrorCodes.noInternet:
          case ErrorCodes.bussy:
            return resp..continueResult = ContinueResult.doWait;
          case ErrorCodes.exception1:
          case ErrorCodes.exception2:
            return resp..continueResult = ContinueResult.doRethrow;
          default:
            final cr = await finalizeResponse(resp);
            return resp..continueResult = cr;
        }
      } finally {
        client.close();
      }
    }

    AzureResponse<T>? resp;
    var isFirstGetRequests = true;

    while (true) {
      if (token?.canceled == true) return null;

      final internetOK = await connectedByOne4();
      if (token?.canceled == true) return null;

      if (!internetOK) {
        resp = AzureResponse<T>();
        resp.error = ErrorCodes.noInternet;
      }

      var max = ContinueResult.doBreak.index;
      if (getRequests != null) {
        final requests = getRequests(isFirstGetRequests);
        isFirstGetRequests = false;
        if (requests == null || requests.isEmpty) return null;
        final resp0 = await getContinueResult(requests[0], AzureResponse<T>()..myRequest = requests[0], internetOK);
        if (token?.canceled == true) return null;
        if (requests.length == 1 || resp0.error != ErrorCodes.no) {
          resp = resp0;
        } else {
          final resps = await Future.wait(requests.skip(1).map((r) => getContinueResult(r, AzureResponse<T>()..myRequest = r, internetOK)));
          if (token?.canceled == true) return null;
          resp = null;
          for (var rs in resps) {
            if (rs.continueResult.index < max) continue;
            resp = rs;
            max = rs.continueResult.index;
          }
        }
      } else {
        AzureRequest? req;
        if (getRequest != null) {
          req = getRequest();
          assert(req != null);
          resp ??= AzureResponse<T>(); // large query => agregate subqueries in the same AzureResponse
        } else {
          req = request;
          resp = AzureResponse<T>();
        }
        resp.myRequest = req;

        resp = await getContinueResult(req!, resp, internetOK);
        if (token?.canceled == true) return null;
      }

      switch (resp!.continueResult) {
        case ContinueResult.doBreak:
          return resp;
        case ContinueResult.doContinue:
          continue; // continue due more requests while cycle (e.g. multi part query)
        case ContinueResult.doWait: // recoverable error ()
          final res = await sendPar.retries!.delay();
          if (token?.canceled == true) return null;
          if (res != 0) return Future.error(res);
          resp = null; // continue due error
          continue;
        case ContinueResult.doRethrow:
          return Future.error(resp.error);
      }
    }
  }
}

class RetriesSimple extends IRetries {
  int baseMsec = 4000;
  int maxSec = 0;
  @override
  int nextMSec() {
    if (maxSec > 0 && baseMsec > maxSec) {
      return -ErrorCodes.timeout;
    }
    return baseMsec > 30000 ? baseMsec : baseMsec *= 2;
  }

  static final _instance = RetriesSimple();
}
