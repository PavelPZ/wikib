import 'dart:convert';
import 'dart:typed_data';

import 'package:hive/hive.dart';
// import 'package:riverpod/riverpod.dart';
import 'package:protobuf/protobuf.dart' as $pb;
import 'package:utils/utils.dart';

import 'package:azure/azure.dart';

// flutter pub run build_runner watch --delete-conflicting-outputs
part 'storage.g.dart';

void initStorage() {
  Hive.registerAdapter(BoxIntAdapter());
  Hive.registerAdapter(BoxStringAdapter());
}

const initialETag = 'initialETag';

// ***************************************
// STORAGE
// ***************************************

abstract class Storage<TDBId extends DBId> implements IStorage, ICancelToken {
  Storage(this.box, this.azureTable, this.dbId, this.email);

  void setAllGroups(List<ItemsGroup> allGroups) {
    this.allGroups = allGroups;
    row2Group = <int, ItemsGroup>{};
    for (var grp in allGroups)
      for (var i = grp.rowStart; i <= grp.rowEnd; i++) {
        assert(row2Group[i] == null);
        row2Group[i] = grp;
      }
  }

  final DBId dbId;
  final String email;
  Box box; // due to debugReopen
  final TableStorage? azureTable;
  late Map<int, ItemsGroup> row2Group;
  late List<ItemsGroup> allGroups;

  String get partitionKey => dbId.partitionKey(email);

  Future initialize([bool debugClear = false]) async {
    if (debugClear) {
      assert(dpAzureMsg('Storage.initialize: debugClear START')());
      if (azureTable != null) await azureTable!.flush();
      await toAzureDeleteAll();
      await box.clear();
      assert(dpAzureMsg('Storage.initialize: debugClear END')());
    } else {
      if (azureTable != null) {
        assert(dpAzureMsg('Storage.initialize: saveToCloud START')());
        await azureTable!.saveToCloud(this);
        assert(dpAzureMsg('Storage.initialize: saveToCloud END')());
      }
    }
    assert(dpAzureMsg('Storage.initialize: seed RUN')());
    _seed();
    await flush();
  }

  Future close() async {
    await cancel();
    await box.close();
  }

  Future flush() async {
    if (azureTable != null) await azureTable!.flush();
    await box.flush();
  }

  Future cancel() async {
    _canceled = true;
    try {
      if (azureTable != null) await azureTable!.flush();
      await box.flush();
    } finally {
      _canceled = false;
    }
  }

  bool get canceled => _canceled;
  bool _canceled = false;

  void _seed() {
    if (box.length > 0) return;
    box.put(BoxKey.eTagHiveKey.boxKey, '');
    allGroups.forEach((e) => e.seed());
  }

  AzureDataUpload? toAzureUpload() {
    //if (!namePlace.exists()) return null;
    final rowGroups = <int, List<BoxItem>>{};
    for (var item in box.values.whereType<BoxItem>().where((b) => b.isDefered))
      rowGroups.update(item.key, (value) => value..add(item), ifAbsent: () => <BoxItem>[item]);

    // first row
    final firstRow = BatchRow(rowId: BoxKey.eTagHiveKey.rowId, data: _initAzureRowData(BoxKey.eTagHiveKey.rowId), method: BatchMethod.put)
      ..eTag = box.get(BoxKey.eTagHiveKey.boxKey);
    firstRow.data['aa'] = '';
    final rows = <BatchRow>[firstRow];
    // final rows = <BatchRow>[];
    // finish rows
    for (final r in rowGroups.entries) {
      final data = _initAzureRowData(r.key);
      BatchRow row;
      if (r.value.every((b) => b.isDeleted)) {
        rows.add(row = BatchRow(rowId: r.key, data: data, method: BatchMethod.delete));
      } else {
        for (final item in r.value.where((b) => !b.isDeleted)) item.toAzureUpload(data);
        rows.add(row = BatchRow(rowId: r.key, data: data, method: r.value.any((b) => b.isDeleted) ? BatchMethod.put : BatchMethod.merge));
      }
      for (var item in r.value) row.versions[item.key] = item.version;
    }
    assert(dpAzureMsg('Storage.toAzureUpload: ${rows.map((e) => '${e.rowId.toString()}-${e.method.toString()}').join(',')}')());
    return AzureDataUpload(rows: rows);
  }

  Map<String, dynamic> _initAzureRowData(int rowId) =>
      <String, dynamic>{'PartitionKey': Encoder.keys.encode(dbId.partitionKey(email)), 'RowKey': Encoder.keys.encode(BoxKey.byte2Hex(rowId))};

  Future fromAzureETagUploaded(String eTag) => box.put(BoxKey.eTagHiveKey.boxKey, eTag);

  Future fromAzureRowUploaded(Map<int, int> versions) {
    // TODO(pz): eTagPlace.getBox()!..value = newETag];
    final modified = <BoxItem>[];
    for (var kv in versions.entries) {
      final item = box.get(kv.key) as BoxItem?;
      if (item == null || item.version != kv.value) continue;
      assert(item.isDefered || item.key == BoxKey.eTagHiveKey.boxKey);
      if (item.isDeleted)
        item.delete();
      else
        modified.add(item..isDefered = false);
    }
    if (modified.isNotEmpty) box.putAll(Map.fromEntries(modified.map((e) => MapEntry(e.key, e))));
    return box.flush();
  }

  Future debugFromAzureAllUploaded(AzureDataUpload? azureDataUpload) {
    if (azureDataUpload == null) return Future.value();
    for (var row in azureDataUpload.rows) {
      if (row.rowId == BoxKey.eTagHiveKey.rowId)
        fromAzureETagUploaded(DateTime.now().millisecondsSinceEpoch.toString());
      else
        fromAzureRowUploaded(row.versions);
    }
    return box.flush();
  }

  Future fromAzureDownload(AzureDataDownload rows) async {
    await box.clear();
    final puts = <MapEntry<dynamic, dynamic>>[];
    for (var row in rows.entries)
      for (var prop in rows.entries) {
        final key = BoxKey.azure(row.key, prop.key);
        final messageGroup = row2Group[key.rowId]!;
        puts.add(MapEntry(key.boxKey, messageGroup.fromAzureDownload(key.boxKey, prop.value)));
      }
    final entries = Map.fromEntries(puts);
    await box.putAll(entries);
  }

  void saveBoxItem(BoxItem boxItem) {
    boxItem.version = Day.nowMilisecUtc;
    boxItem.isDefered = true;
    box.put(boxItem.key, boxItem);
    azureTable?.saveToCloud(this, token: this);
  }

  void saveBoxItems(Iterable<BoxItem> boxItems) {
    box.putAll(Map.fromEntries(boxItems.map((boxItem) {
      boxItem.version = Day.nowMilisecUtc;
      boxItem.isDefered = true;
      return MapEntry(boxItem.key, boxItem);
    })));
    azureTable?.saveToCloud(this, token: this);
  }

  Future debugReopen() async {
    await close();
    box = await Hive.openBox(box.name, path: box.path!.split('\\${box.name}.hive')[0]);
  }

  String debugDump([bool filter(BoxItem item)?]) {
    var all = box.values.whereType<BoxItem>();
    if (filter != null) all = all.where(filter);
    return all
        .map((e) => '${e.isDeleted ? '-' : ''}${e.isDefered ? '*' : ''}${e.key}${e.value is Uint8List ? '' : '=' + e.value.toString()}')
        .join(',');
  }

  String debugDeletedAndDefered([bool filter(BoxItem item)?]) {
    var all = box.values.whereType<BoxItem>();
    if (filter != null) all = all.where(filter);
    var deleted = 0, defered = 0;
    all.forEach((e) {
      if (e.isDeleted) deleted++;
      if (e.isDefered) defered++;
    });
    return 'deleted=$deleted, defered=$defered';
  }

  Future toAzureDeleteAll() async {
    if (azureTable == null) return;
    final rowKeys = await azureTable!.getAllRows(partitionKey);
    if (rowKeys == null) return null;
    final rowIds = rowKeys.map((key) => BoxKey.hex2Byte(key));
    final rows = rowIds.map((rowId) => BatchRow(rowId: rowId, data: _initAzureRowData(rowId), method: BatchMethod.delete)).toList();
    assert(dpAzureMsg('Storage.toAzureDeleteAll: ${rows.map((e) => '${e.rowId.toString()}-${e.method.toString()}').join(',')}')());
    final azureDataUpload = AzureDataUpload(rows: rows);
    await azureTable!.saveToCloud(DeleteAllStorage(azureDataUpload));
    await azureTable!.flush();
  }
}

class DeleteAllStorage implements IStorage {
  DeleteAllStorage(this._data);
  final AzureDataUpload _data;

  AzureDataUpload? toAzureUpload() => _data;
  Future fromAzureRowUploaded(Map<int, int> versions) => Future.value();
  Future fromAzureETagUploaded(String eTag) => Future.value();
}

// ***************************************
// BOX ITEMS
// ***************************************

abstract class BoxItem<T> extends HiveObject {
  @HiveField(0, defaultValue: 0)
  int key = 0;

  T get value;
  set value(T v);

  @HiveField(2, defaultValue: 0)
  int version = 0;

  @HiveField(3, defaultValue: false)
  bool isDeleted = false;

  @HiveField(4, defaultValue: false)
  bool isDefered = false;

  void toAzureUpload(Map<String, dynamic> data) => data[BoxKey.getPropKey(key)] = value;
}

@HiveType(typeId: 1)
class BoxInt extends BoxItem<int> {
  @override
  @HiveField(1, defaultValue: 0)
  int value = 0;
}

@HiveType(typeId: 2)
class BoxString extends BoxItem<String> {
  @override
  @HiveField(1, defaultValue: '')
  String value = '';
}

abstract class BoxMsg<T extends $pb.GeneratedMessage> extends BoxItem<Uint8List?> {
  T msgCreator();
  void setMsgId(T msg, int id);

  T? get msg {
    rAssert(!isDeleted);
    if (_msg != null) return _msg!;
    assert(value != null);
    _msg = Protobuf.fromBytes(value!, msgCreator);
    return _msg!;
  }

  set msg(T? v) {
    rAssert(!isDeleted);
    _msg = v;
    assert(_msg != null);
    value = Protobuf.toBytes(_msg!);
  }

  T? _msg;

  @override
  void toAzureUpload(Map<String, dynamic> data) {
    final propKey = BoxKey.getPropKey(key);
    data[propKey] = base64.encode(value!);
    data['$propKey@odata.type'] = 'Edm.Binary';
  }

  @override
  @HiveField(1, defaultValue: null)
  Uint8List? value;
}

// ***************************************
// PLACES
// ***************************************

abstract class Place<T> {
  Place(this.storage, {required int rowId, required int propId}) : boxKey = (rowId << 8) + propId;

  final int boxKey;
  final Storage storage;

  BoxItem createBoxItem();
  BoxItem fromValueOrMsg(int? key, T value);
  T getValueOrMsg([int? key]);

  int getKey([int? key]) => key ?? boxKey;
  int getBoxKey([int? key]) => getKey(key);

  BoxItem fromKeyValue(int key, dynamic value) => createBoxItem()
    ..key = key
    ..value = value;

  BoxItem? getBox([int? key]) {
    final boxItem = storage.box.get(getBoxKey(key));
    return boxItem == null || boxItem.isDeleted ? null : boxItem;
  }

  bool exists([int? key]) => getBox(key) != null;

  void delete({int? key}) {
    final boxItem = getBox(key);
    rAssert(boxItem != null);
    boxItem!.isDeleted = true;
    storage.saveBoxItem(boxItem);
  }

  void saveValue(T valueOrMsg, {int? key}) => storage.saveBoxItem(getBox(key) ?? fromValueOrMsg(key, valueOrMsg));
}

abstract class PlaceValue<T> extends Place<T> {
  PlaceValue(Storage storage, {required int rowId, required int propId}) : super(storage, rowId: rowId, propId: propId);

  @override
  T getValueOrMsg([int? key]) => (getBox(key)?.value)!;
  @override
  BoxItem fromValueOrMsg(int? key, T value) => fromKeyValue(getKey(key), value);
}

class PlaceInt extends PlaceValue<int> {
  PlaceInt(Storage storage, {required int rowId, required int propId}) : super(storage, rowId: rowId, propId: propId);

  @override
  BoxItem createBoxItem() => BoxInt();
}

class PlaceString extends PlaceValue<String> {
  PlaceString(Storage storage, {required int rowId, required int propId}) : super(storage, rowId: rowId, propId: propId);

  @override
  BoxItem createBoxItem() => BoxString();
}

abstract class PlaceMsg<T extends $pb.GeneratedMessage> extends Place<T> {
  PlaceMsg(Storage storage, {required int rowId, required int propId}) : super(storage, rowId: rowId, propId: propId);

  void updateMsg(void proc(T t), {int? key}) {
    final boxItem = getBox(key) as BoxMsg<T>;
    rAssert(!boxItem.isDeleted);
    proc(boxItem.msg!);
    storage.saveBoxItem(boxItem);
  }

  @override
  BoxItem fromValueOrMsg(int? key, T msg) {
    key ??= getKey(key);
    return (createBoxItem() as BoxMsg<T>)
      ..setMsgId(msg, key) // must be first: following "msg = msg" saves msg to uint8 value
      ..key = key
      ..msg = msg;
  }

  @override
  T getValueOrMsg([int? key]) => ((getBox(key) as BoxMsg<T>?)?.msg)!;
}

// ***************************************
// GROUPS
// ***************************************

abstract class ItemsGroup {
  ItemsGroup(this.storage, {required this.rowStart, required this.rowEnd});

  final Storage storage;

  final int rowStart;
  final int rowEnd;

  BoxItem fromAzureDownload(int key, dynamic value);
  void seed() {}
}

class SinglesGroup extends ItemsGroup {
  SinglesGroup(Storage storage, {required int row, required this.singles}) : super(storage, rowStart: row, rowEnd: row);

  final List<Place> singles;

  @override
  BoxItem fromAzureDownload(int key, dynamic value) {
    final boxKey = BoxKey(key);
    assert(boxKey.propId < singles.length);
    return singles[boxKey.propId].fromKeyValue(key, value);
  }
}

abstract class MessagesGroup<T extends $pb.GeneratedMessage> extends ItemsGroup {
  MessagesGroup(
    Storage storage, {
    required int rowStart,
    required int rowEnd,
    required this.itemsPlace,
  }) : super(storage, rowStart: rowStart, rowEnd: rowEnd);

  final PlaceMsg<T> itemsPlace;

  @override
  BoxItem fromAzureDownload(int key, dynamic value) => itemsPlace.fromKeyValue(key, value);

  Iterable<BoxItem> getItems() {
    final endKey = BoxKey.getBoxKey(rowEnd, BoxKey.maxPropId);
    return storage.box
        .valuesBetween(
          startKey: BoxKey.getBoxKey(rowStart, 0),
        )
        .cast<BoxItem>()
        .where((f) => !f.isDeleted && f.key <= endKey);
  }

  Iterable<BoxMsg<T>> getMsgs() => getItems().whereType<BoxMsg<T>>();

  void clear({bool startItemsIncluded = false}) =>
      storage.saveBoxItems((startItemsIncluded ? getItems() : getMsgs()).map((e) => e..isDeleted = true));
}

abstract class MessagesGroupWithCounter<T extends $pb.GeneratedMessage> extends MessagesGroup<T> {
  MessagesGroupWithCounter(
    Storage storage, {
    required int rowStart,
    required int rowEnd,
    required this.uniqueCounter,
    required PlaceMsg<T> itemsPlace,
  }) : super(storage, rowStart: rowStart, rowEnd: rowEnd, itemsPlace: itemsPlace);

  final PlaceValue<int> uniqueCounter;

  @override
  BoxItem fromAzureDownload(int key, dynamic value) {
    final boxKey = BoxKey(key);
    if (boxKey.rowId == rowStart && boxKey.propId == 0) return uniqueCounter.fromKeyValue(key, value);
    return super.fromAzureDownload(key, value);
  }

  Future addItems(Iterable<T> msgs) {
    final uniqueBox = uniqueCounter.getBox() as BoxInt;
    var nextKey = uniqueBox.value;
    final items = msgs.map((msg) => itemsPlace.fromValueOrMsg(nextKey = BoxKey.nextKey(nextKey), msg)).toList();
    items.add(uniqueBox..value = nextKey);
    storage.saveBoxItems(items);
    return storage.box.flush();
  }

  @override
  void seed() {
    super.seed();
    if (!uniqueCounter.exists()) uniqueCounter.saveValue(itemsPlace.boxKey - 1);
  }
}
