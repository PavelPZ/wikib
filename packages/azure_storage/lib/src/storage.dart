import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:azure/azure.dart';
import 'package:hive/hive.dart';
// import 'package:riverpod/riverpod.dart';
import 'package:protobuf/protobuf.dart' as $pb;
import 'package:utils/utils.dart';

part 'box_item.dart';
part 'group.dart';
part 'place.dart';
// flutter pub run build_runner watch --delete-conflicting-outputs
part 'storage.g.dart';

void initStorage() {
  Hive.registerAdapter(BoxIntAdapter());
  Hive.registerAdapter(BoxStringAdapter());
}

const initialETag = 'initialETag';

class StorageInfo {
  StorageInfo({required this.dbId, required this.emailOrEmpty, required this.debugDeviceId, required this.tableAccount});
  final DBId? dbId;
  final String emailOrEmpty;
  final String? debugDeviceId;
  final TableAccount? tableAccount;
  DBId get id => dbId!;
  bool get isEmpty => dbId == null;
  String get hiveName => '${debugDeviceId == null ? '' : debugDeviceId! + '-'}$partitionKey';
  String get partitionKey => id.partitionKey(emailOrEmpty);
  Future initHiveBox() async => _hiveBox = await Hive.openBox(hiveName);
  Box get hiveBox => _hiveBox!;
  Box? _hiveBox;
  TableStorage? getTableStorage() => tableAccount == null ? null : TableStorage(account: tableAccount!, partitionKey: partitionKey);
  void debugChangeBox(Box box) => _hiveBox = box;
}

abstract class Storage<TDBId extends DBId> implements IStorage {
  Storage(this.info) {
    saveToCloudTable = info.getTableStorage();
  }

  void setAllGroups(List<ItemsGroup> allGroups) {
    this.allGroups = allGroups;
    row2Group = <int, ItemsGroup>{};
    for (var grp in allGroups)
      for (var i = grp.rowStart; i <= grp.rowEnd; i++) {
        assert(row2Group[i] == null);
        row2Group[i] = grp;
      }
  }

  final StorageInfo info;
  late TableStorage? saveToCloudTable;
  late Map<int, ItemsGroup> row2Group;
  late List<ItemsGroup> allGroups;

  Box get box => info._hiveBox!;

  Future initialize() async {
    final tableAndInet = saveToCloudTable != null && await connectedByOne4();
    if (info.hiveBox.length > 0) {
      if (tableAndInet) await saveToCloudTable!.saveToCloud(this);
    } else {
      if (tableAndInet) {
        await wholeAzureDownload();
        if (!isNullOrEmpty(info.hiveBox.get(BoxKey.eTagHiveKey.boxKey))) return;
      }
      unawaited(info.hiveBox.put(BoxKey.eTagHiveKey.boxKey, ''));
      // ignore: avoid_function_literals_in_foreach_calls
      allGroups.forEach((e) => e.seed());
    }
  }

  // cancel waiting in azureTable save (e.g. when waiting for internet connection)
  Future close() async {
    cancel();
    await info.hiveBox.close();
  }

  // wait in azureTable save (e.g. when waiting for internet connection)
  Future debugFlush() async {
    if (saveToCloudTable != null) await saveToCloudTable!.flush();
    await info.hiveBox.flush();
  }

  void cancel() {
    saveToCloudTable?.cancel();
    saveToCloudTable = info.getTableStorage();
  }

  @override
  AzureDataUpload? toAzureUpload({bool allowSingleRow = true}) {
    //if (!namePlace.exists()) return null;
    final rowGroups = <int, List<BoxItem>>{};
    for (var item in info.hiveBox.values.whereType<BoxItem>().where((b) => b.isDefered))
      rowGroups.update(BoxKey.getRowId(item.key), (value) => value..add(item), ifAbsent: () => <BoxItem>[item]);

    // first row
    if (rowGroups.isEmpty && !allowSingleRow) return null;
    final firstRow =
        BatchRow(rowId: BoxKey.eTagHiveKey.rowId, data: _initAzureRowData(info.partitionKey, BoxKey.eTagHiveKey.rowId), method: BatchMethod.put)
          ..eTag = info.hiveBox.get(BoxKey.eTagHiveKey.boxKey);
    firstRow.data['aa'] = '';
    final rows = <BatchRow>[firstRow];
    // final rows = <BatchRow>[];
    // finish rows
    for (final r in rowGroups.entries) {
      final data = _initAzureRowData(info.partitionKey, r.key);
      // row with delete
      BatchRow row;
      if (r.value.any((rr) => rr.isDeleted)) {
        // if (r.value.length == BoxKey.maxPropId + 1 && r.value.every((b) => b.isDeleted)) {
        //   // all items in row are deleted
        //   rows.add(row = BatchRow(rowId: r.key, data: data, method: BatchMethod.delete));
        // } else {
        final allRowItems = getItems(BoxKey.getBoxKey(r.key, 0), BoxKey.getBoxKey(r.key, BoxKey.maxPropId)).toList();
        if (allRowItems.length == r.value.length && r.value.every((b) => b.isDeleted)) {
          // all items in row are deleted
          rows.add(row = BatchRow(rowId: r.key, data: data, method: BatchMethod.delete));
        } else {
          // some of item is deleted => PUT not deleted items
          for (final item in allRowItems.where((b) => !b.isDeleted)) item.toAzureUpload(data);
          rows.add(row = BatchRow(rowId: r.key, data: data, method: BatchMethod.put));
        }
        //}
      } else {
        for (final item in r.value.where((b) => !b.isDeleted)) item.toAzureUpload(data);
        rows.add(row = BatchRow(rowId: r.key, data: data, method: BatchMethod.merge));
      }
      for (var item in r.value) row.versions[item.key] = item.version;
    }
    assert(dpAzureMsg('Storage.toAzureUpload: ${rows.map((e) => '${e.rowId.toString()}-${e.method.toString()}').join(',')}')());
    return AzureDataUpload(rows: rows);
  }

  static Map<String, dynamic> _initAzureRowData(String partitionKey, int rowId) =>
      <String, dynamic>{'PartitionKey': Encoder.keys.encode(partitionKey), 'RowKey': Encoder.keys.encode(BoxKey.byte2HexRow(rowId))};

  @override
  Future fromAzureUploadedETag(String eTag) => info.hiveBox.put(BoxKey.eTagHiveKey.boxKey, eTag);

  @override
  Future fromAzureUploadedRow(Map<int, int> versions) {
    final modified = <BoxItem>[];
    for (var kv in versions.entries) {
      final item = info.hiveBox.get(kv.key) as BoxItem?;
      if (item == null || item.version != kv.value) continue;
      assert(item.isDefered || item.key == BoxKey.eTagHiveKey.boxKey);
      if (item.isDeleted)
        item.delete();
      else
        modified.add(item..isDefered = false);
    }
    if (modified.isNotEmpty) info.hiveBox.putAll(Map.fromEntries(modified.map((e) => MapEntry(e.key, e))));
    return info.hiveBox.flush();
  }

  Future debugFromAzureAllUploaded(AzureDataUpload? azureDataUpload) {
    if (azureDataUpload == null) return Future.value();
    for (var row in azureDataUpload.rows) {
      if (row.rowId == BoxKey.eTagHiveKey.rowId)
        fromAzureUploadedETag(DateTime.now().millisecondsSinceEpoch.toString());
      else
        fromAzureUploadedRow(row.versions);
    }
    return info.hiveBox.flush();
  }

  @override
  Future onETagConflict() async {
    final rows = await info.getTableStorage()!.getAllRows(info.partitionKey);
    if (rows != null) _wholeAzureDownload(rows);
    cancel();
  }

  Future wholeAzureDownload() async {
    cancel();
    unawaited(info.hiveBox.clear());
    final rows = await info.getTableStorage()!.getAllRows(info.partitionKey);
    if (rows == null) return;
    _wholeAzureDownload(rows);
  }

  void _wholeAzureDownload(WholeAzureDownload rows) {
    unawaited(info.hiveBox.put(BoxKey.eTagHiveKey.boxKey, rows.eTag));
    // final azureItemsCount = rows.rows.cast<Map<String, dynamic>>().map((row) => row.length).reduce((value, element) => value + element);
    final boxes = <int, BoxItem>{};
    for (var row in rows.rows.cast<Map<String, dynamic>>()) {
      for (var prop in row.entries) {
        if (ignoreKeys.containsKey(prop.key)) continue;
        final key = BoxKey.azure(row['RowKey'], prop.key);
        final messageGroup = row2Group[key.rowId]!;
        boxes[key.boxKey] = messageGroup.wholeAzureDownload(key.boxKey, prop.value)..version = Day.nowMilisecUtc;
      }
    }
    unawaited(info.hiveBox.putAll(boxes));
  }

  // move local 'emptyEMail' DB to user email DB.
  // try email DB from cloud first.
  Future moveTo(Storage newStorage) async {
    assert(info.tableAccount == null);
    assert(newStorage.info.tableAccount != null);
    assert(newStorage.info.hiveBox.isEmpty);
    assert(newStorage.info.emailOrEmpty != emptyEMail);
    assert(newStorage.info.hiveBox != info.hiveBox);
    // get content of newStorage.partitionKey cloud
    final newRows = await newStorage.info.getTableStorage()!.getAllRows(newStorage.info.partitionKey);
    final newRowsCount =
        newRows == null ? 0 : newRows.rows.cast<Map<String, dynamic>>().map((row) => row.length).reduce((value, element) => value + element);
    if (newRowsCount > info.hiveBox.length) {
      // newStorage.partitionKey cloud databaze is greater than local databaze => take DB from cloud
      newStorage._wholeAzureDownload(newRows!);
    } else {
      // newStorage.partitionKey databaze is smaller than local databaze => take DB from local db
      unawaited(newStorage.info.hiveBox.put(BoxKey.eTagHiveKey.boxKey, newRows?.eTag ?? ''));
      final olds = info.hiveBox.values.whereType<BoxItem>().toList();
      await info.hiveBox
          .clear(); // must be await otherwise saveBoxItems raises error "The same instance of an HiveObject cannot be stored in two different boxes"
      newStorage.saveBoxItems(olds);
    }
    unawaited(info.hiveBox.deleteFromDisk());
  }

  static const ignoreKeys = <String, bool>{'RowKey': true, 'PartitionKey': true, 'Timestamp': true};

  void saveBoxItem(BoxItem boxItem) {
    boxItem.version = Day.nowMilisecUtc;
    boxItem.isDefered = true;
    info.hiveBox.put(boxItem.key, boxItem);
    saveToCloudTable?.saveToCloud(this);
  }

  void saveBoxItems(Iterable<BoxItem> boxItems) {
    final entries = Map.fromEntries(boxItems.map((boxItem) {
      boxItem.version = Day.nowMilisecUtc;
      boxItem.isDefered = true;
      return MapEntry(boxItem.key, boxItem);
    }));
    info.hiveBox.putAll(entries);
    saveToCloudTable?.saveToCloud(this);
  }

  Future debugReopen() async {
    await close();
    info.debugChangeBox(await Hive.openBox(info.hiveBox.name, path: info.hiveBox.path!.split('\\${info.hiveBox.name}.hive')[0]));
  }

  String debugDump([bool filter(BoxItem item)?]) {
    var all = info.hiveBox.values.whereType<BoxItem>();
    if (filter != null) all = all.where(filter);
    return all
        .map((e) => '${e.isDeleted ? '-' : ''}${e.isDefered ? '*' : ''}${e.key}${e.value is Uint8List ? '' : '=' + e.value.toString()}')
        .join(',');
  }

  String debugDeletedAndDefered([bool filter(BoxItem item)?]) {
    var all = info.hiveBox.values.whereType<BoxItem>();
    if (filter != null) all = all.where(filter);
    var deleted = 0, defered = 0;
    all.forEach((e) {
      if (e.isDeleted) deleted++;
      if (e.isDefered) defered++;
    });
    return 'deleted=$deleted, defered=$defered';
  }

  static Future debugDeleteAzureAll(String partitionKey, TableAccount azureTableAcount) async {
    final azureTable = TableStorage(account: azureTableAcount, partitionKey: partitionKey);
    final rowKeys = await azureTable.getAllRowKeys(partitionKey);
    if (rowKeys == null) return null;
    final rowIds = rowKeys.map((key) => BoxKey.hex2Byte(key));
    final rows = rowIds.map((rowId) => BatchRow(rowId: rowId, data: _initAzureRowData(partitionKey, rowId), method: BatchMethod.delete)).toList();
    assert(dpAzureMsg('Storage.toAzureDeleteAll: ${rows.map((e) => '${e.rowId.toString()}-${e.method.toString()}').join(',')}')());
    final azureDataUpload = AzureDataUpload(rows: rows);
    unawaited(azureTable.saveToCloud(DeleteAllStorage(azureDataUpload)));
    await azureTable.flush();
  }

  Iterable<T> getItems<T extends BoxItem>(int startKey, int endKey, [bool filter(BoxItem item)?]) sync* {
    final lastKey = info.hiveBox.keys.last;
    for (var i = startKey; i <= min(endKey, lastKey); i++) {
      final it = info.hiveBox.get(i);
      if (it == null || it is! T || (filter != null && !filter(it))) continue;
      yield it;
    }
  }
}

class DeleteAllStorage implements IStorage {
  DeleteAllStorage(this._data);
  AzureDataUpload? _data;

  @override
  AzureDataUpload? toAzureUpload() {
    try {
      return _data;
    } finally {
      _data = null;
    }
  }

  @override
  Future fromAzureUploadedRow(Map<int, int> versions) => Future.value();
  @override
  Future fromAzureUploadedETag(String eTag) => Future.value();
  @override
  Future onETagConflict() => throw UnimplementedError();
}
