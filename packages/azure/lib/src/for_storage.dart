// https://docs.microsoft.com/en-us/dotnet/api/microsoft.azure.cosmos.table.tablebatchoperation?view=azure-dotnet
// max 100 rows, max 4 MByte of HTTP message size
import 'dart:convert';

import 'lib.dart';

class BatchRow {
  BatchRow({required this.data, required this.method});
  final Map<String, dynamic> data;
  String? eTag;
  final BatchMethod method;
  // for azure store code
  int batchDataId = 0;
  ResponsePart? batchResponse;
  String toJson() => jsonEncode(data);
}

class AzureDataUpload {
  AzureDataUpload({required this.rows, required this.versions});
  final List<BatchRow> rows;
  final Map<int, int> versions;
  String? newETag;
}

typedef AzureDataDownload = Map<String, Map<String, dynamic>>;

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
