// https://docs.microsoft.com/en-us/dotnet/api/microsoft.azure.cosmos.table.tablebatchoperation?view=azure-dotnet
// max 100 rows, max 4 MByte of HTTP message size
class BatchRow {
  BatchRow({required this.rowId, required this.data, required this.method});
  final String rowId;
  final Map<String, dynamic> data;
  String? eTag;
  final BatchMethod method;
}

class AzureDataUpload {
  AzureDataUpload({required this.rows, required this.versions});
  final List<BatchRow> rows;
  final Map<int, int> versions;
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
