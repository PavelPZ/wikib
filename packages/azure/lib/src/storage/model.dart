import 'dart:typed_data';

import 'package:hive/hive.dart';
// import 'package:riverpod/riverpod.dart';
import 'package:protobuf/protobuf.dart' as $pb;
import 'package:utils/utils.dart';

import '../forStorage.dart';

// flutter pub run build_runner watch --delete-conflicting-outputs
part 'model.g.dart';

void initStorage() {
  Hive.registerAdapter(BoxIntAdapter());
  Hive.registerAdapter(BoxStringAdapter());
}

// ***************************************
// STORAGE
// ***************************************

abstract class Storage {
  Storage(this.box);

  void setAllGroups(List<ItemsGroup> groups) {
    allGroups = groups;
    row2Group = <int, ItemsGroup>{};
    for (var grp in allGroups)
      for (var i = grp.rowStart; i <= grp.rowEnd; i++) {
        assert(row2Group[i] == null);
        row2Group[i] = grp;
      }
  }

  void onChanged();
  void _onChanged() {
    if (_onChangedRunning != null) return;
    _onChangedRunning = Future.microtask(() => onChanged()).whenComplete(() => _onChangedRunning = null);
  }

  Future? _onChangedRunning;

  Box box;
  late Map<int, ItemsGroup> row2Group;
  late List<ItemsGroup> allGroups;

  Future seed() => Future.wait(allGroups.map((e) => e.seed()));

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

  AzureDataUpload? toAzureUpload() {
    final rowGroups = <String, List<BoxItem>>{};
    final versions = <int, int>{};
    for (var item in box.values.cast<BoxItem>().where((b) => b.isDefered)) {
      rowGroups.update(item.rowKey, (value) => value..add(item), ifAbsent: () => <BoxItem>[item]);
      versions[item.key] = item.version;
    }
    if (versions.length == 0) return null;
    // finish rows
    final rows = <BatchRow>[];
    for (var r in rowGroups.entries) {
      if (r.value.every((b) => b.isDeleted)) {
        rows.add(BatchRow(rowId: r.key, data: <String, dynamic>{}, method: BatchMethod.delete));
      } else {
        final notDeletedMap = Map.fromEntries(r.value.where((b) => !b.isDeleted).map((e) => MapEntry(e.rowPropId, e.value)));
        rows.add(BatchRow(rowId: r.key, data: notDeletedMap, method: r.value.any((b) => b.isDeleted) ? BatchMethod.put : BatchMethod.merge));
      }
    }
    return AzureDataUpload(rows: rows, versions: versions);
  }

  Future fromAzureUpload(Map<int, int> versions) {
    final futures = <Future>[];
    for (var kv in versions.entries) {
      final item = box.get(kv.key) as BoxItem?;
      if (item == null || item.version != kv.value) continue;
      assert(item.isDefered);
      if (item.isDeleted)
        futures.add(item.delete());
      else
        item.isDefered = false;
    }
    return futures.length > 0 ? Future.wait(futures) : Future.value();
  }

  Future debugReopen() async {
    await box.close();
    box = await Hive.openBox(box.name, path: box.path!.split('\\${box.name}.hive')[0]);
  }
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

  String get rowKey => BoxKey.getRowKey(key);
  String get rowPropId => BoxKey.getRowPropId(key);
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
  T? getValueOrMsg([int? key]);

  int getKey([int? key]) => key ?? boxKey;
  int getBoxKey([int? key]) => getKey(key);

  BoxItem fromKeyValue(int key, dynamic value) => createBoxItem()
    ..key = key
    ..value = value;

  Future saveBoxItem(BoxItem boxItem) async {
    boxItem.version = Day.nowMilisecUtc;
    boxItem.isDefered = true;
    await storage.box.put(boxItem.key, boxItem);
    storage._onChanged();
  }

  Future saveBoxItems(List<BoxItem> boxItems) async {
    final futures = boxItems.map((boxItem) {
      boxItem.version = Day.nowMilisecUtc;
      boxItem.isDefered = true;
      return storage.box.put(boxItem.key, boxItem);
    });
    await Future.wait(futures);
    storage._onChanged();
  }

  BoxItem? getBox([int? key]) {
    final boxItem = storage.box.get(getBoxKey(key));
    return boxItem == null || boxItem.isDeleted ? null : boxItem;
  }

  bool exists([int? key]) => storage.box.containsKey(getBoxKey(key));

  Future delete([int? key]) {
    final boxItem = getBox(key);
    rAssert(boxItem != null);
    boxItem!.isDeleted = true;
    return saveBoxItem(boxItem);
  }

  Future saveValue(T valueOrMsg, [int? key]) => saveBoxItem(getBox(key) ?? fromValueOrMsg(key, valueOrMsg));
}

abstract class PlaceValue<T> extends Place<T> {
  PlaceValue(Storage storage, {required int rowId, required int propId}) : super(storage, rowId: rowId, propId: propId);

  @override
  T? getValueOrMsg([int? key]) => getBox(key)?.value;
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

  Future updateMsg(int? key, void proc(T t)) {
    final boxItem = getBox(key) as BoxMsg<T>;
    rAssert(!boxItem.isDeleted);
    proc(boxItem.msg!);
    return saveBoxItem(boxItem);
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
  T? getValueOrMsg([int? key]) => (getBox(key) as BoxMsg<T>?)?.msg;
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
  Future seed() => Future.value();
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

  Iterable<BoxMsg<T>> getItems() => storage.box
      .valuesBetween(
        startKey: itemsPlace.boxKey,
        endKey: BoxKey.idx(rowEnd, BoxKey.maxPropId),
      )
      .cast<BoxMsg<T>>()
      .where((f) => !f.isDeleted);
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

  Future addNewGroupItems(List<T> msgs) async {
    final uniqueBox = uniqueCounter.getBox() as BoxInt;
    var nextKey = uniqueBox.value;
    final futures = msgs.map((msg) {
      nextKey = BoxKey.nextKey(nextKey);
      uniqueBox.value = nextKey;
      // rAssert(nextKey.rowId >= rowStart && nextKey.rowId <= rowStart);
      // rAssert(nextKey.propId <= 252);
      final boxItem = itemsPlace.fromValueOrMsg(nextKey, msg) as BoxMsg<T>;
      return itemsPlace.saveBoxItem(boxItem);
    }).toList();
    futures.add(uniqueCounter.saveValue(nextKey));
    await Future.wait(futures);
    storage.onChanged();
  }

  @override
  Future seed() async {
    await super.seed();
    if (!uniqueCounter.exists()) await uniqueCounter.saveValue(itemsPlace.boxKey - 1);
  }
}

// ***************************************
// BOX KEY
// ***************************************

class BoxKey {
  const BoxKey(this.boxKey);
  const BoxKey.idx(int rowId, int propId)
      : assert(propId <= maxPropId),
        boxKey = (rowId << 8) + propId;
  factory BoxKey.azure(String rowId, String propId) => BoxKey.idx(_hex2Byte(rowId), _hex2Byte(propId));

  final int boxKey;
  int get rowId => boxKey >> 8;
  int get propId => boxKey & 0xff;

  BoxKey next() => propId < maxPropId ? BoxKey(boxKey + 1) : BoxKey.idx(rowId + 1, 0);

  //-------- statics

  static int nextKey(int key) {
    final rowId = key >> 8;
    final propId = key & 0xff;
    return propId < maxPropId ? key + 1 : (rowId + 1) << 8;
  }

  static String getRowKey(int key) => _byte2Hex(key >> 8);
  static String getRowPropId(int key) => _byte2Hex(key & 0xff);

  //-------- RowData
  String get rowKey => _byte2Hex(rowId);
  String get rowPropId => _byte2Hex(propId);

  static const maxPropId = 252;
  static const hexMap = <String>['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p'];
  static String _byte2Hex(int b) => hexMap[(b >> 8) & 0xf] + hexMap[b & 0xf];
  static int _hex2Byte(String hex) => (byteMap[hex[0]]! << 8) + byteMap[hex[1]]!;
  static const byteMap = <String, int>{
    'a': 0,
    'b': 1,
    'c': 2,
    'd': 3,
    'e': 4,
    'f': 5,
    'g': 6,
    'h': 7,
    'i': 8,
    'j': 9,
    'k': 10,
    'l': 11,
    'm': 12,
    'n': 13,
    'o': 14,
    'p': 15
  };
}
