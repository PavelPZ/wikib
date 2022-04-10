part of 'azure.dart';

Request copyRequest(Request request) => Request(request.method, request.url)
  ..encoding = request.encoding
  ..bodyBytes = request.bodyBytes
  ..persistentConnection = request.persistentConnection
  ..followRedirects = request.followRedirects
  ..maxRedirects = request.maxRedirects
  ..headers.addAll(request.headers);

// class ResponsePart {
//   late int statusCode;
//   late String reasonPhrase;
//   final headers = <String, String>{};
//   final body = StringBuffer();

//   // https://docs.microsoft.com/en-us/rest/api/storageservices/performing-entity-group-transactions
//   static Iterable<ResponsePart> parseResponse(String response) sync* {
//     const crlf = '\r\n';
//     const multipart = 'Content-Type: multipart/mixed; boundary=';
//     final idx = response.indexOf(multipart);
//     if (idx < 0) return;
//     response = response.substring(idx + multipart.length);
//     final lines = response.split(crlf);
//     final changeSetStart = '--' + lines[0];
//     final changeSetEnd = changeSetStart + '--';
//     var state = 0;
//     late ResponsePart part;
//     for (final line in lines) {
//       switch (state) {
//         case 0: // before first changeSetStart
//           if (line != changeSetStart) continue;
//           state = 1;
//           break;
//         case 1: // after changeSetStart, before first epmty line
//           if (line != '') continue;
//           part = ResponsePart();
//           yield part;
//           state = 2;
//           break;
//         case 2: // on HTTP/1.1
//           final parts = line.split(' ');
//           assert(parts.length >= 3);
//           assert(parts[0] == 'HTTP/1.1');
//           part.statusCode = int.parse(parts[1]);
//           part.reasonPhrase = parts.sublist(2).join(' ');
//           state = 3;
//           break;
//         case 3: // headers
//           if (line != '') {
//             final parts = line.split(': ');
//             assert(parts.length == 2);
//             part.headers[parts[0]] = parts[1];
//             continue;
//           }
//           state = 4;
//           break;
//         case 4: // body
//           if (line == changeSetEnd) break;
//           if (line != changeSetStart) {
//             part.body.writeln(line);
//             continue;
//           }
//           state = 1;
//           break;
//       }
//     }
//   }
// }
