part of 'azure_ex.dart';

// https://docs.microsoft.com/en-us/rest/api/storageservices/understanding-the-table-service-data-model
class RowData {
  RowData(Key key)
      : this.fromMap(<String, dynamic>{
          'PartitionKey': key.partition,
          'RowKey': key.row,
        });
  RowData.forBatch(String row) : this(Key(null, row));
  RowData.fromKeys(String partition, String row) : this(Key(partition, row));
  RowData.fromJson(String json) : this.fromMap(jsonDecode(json));
  RowData.fromMap(this.data);
  static RowData create(Map<String, dynamic> map) => RowData.fromMap(map);

  final Map<String, dynamic> data;
  // String get partitionKey => Encoder.keys.decode(data['PartitionKey']);
  String get rowKey => Encoder.keys.decode(data['RowKey']);
  String? eTag;
  BatchMethod? batchMethod; // true ? 'MERGE' : 'PUT'
  // Data-ID header for getting back response
  int? batchDataId;
  // parsed batch reponse
  ResponsePart? batchResponse;

  String keyUrlPart() => '(PartitionKey=\'${data['PartitionKey']}\',RowKey=\'${data['RowKey']}\')';
  String batchKeyUrlPart(String partitionKey) => '(PartitionKey=\'$partitionKey\',RowKey=\'${data['RowKey']}\')';

  List<int> toJsonBytes() => utf8.encode(toJson());
  String toJson() => jsonEncode(data);

  Uint8List? getBinaryValue(String propName) {
    final String? val = data[propName];
    return val == null ? null : base64.decode(val); // Convert.FromBase64String(val);
  }

  // propName, msg.writeToBuffer()
  void setBinaryValue(String propName, List<int>? value) {
    final typeProp = '$propName@odata.type';
    if (value == null) /* remove value.isEmpty test: binary of protobuf messages could be 0 bytes len */ {
      data.remove(propName);
      data.remove(typeProp);
      return;
    }
    data[propName] = base64.encode(value);
    data[typeProp] = 'Edm.Binary';
  }
}
