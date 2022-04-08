import 'dart:typed_data';

import 'package:hive/hive.dart';
// import 'package:riverpod/riverpod.dart';
import 'package:protobuf/protobuf.dart' as $pb;
import 'package:utils/utils.dart';

import '../forStorage.dart';

// flutter pub run build_runner watch --delete-conflicting-outputs
part 'model.g.dart';

// final storageBoxProvider = Provider<Box>((_) => throw UnimplementedError());
// List<Override> scopeStorageProvider(Box box) => <Override>[storageBoxProvider.overrideWithValue(box)];

void initStorage() {
  Hive.registerAdapter(BoxIntAdapter());
  Hive.registerAdapter(BoxStringAdapter());
}

abstract class Storage {
  Storage(this.box);

  void setAllGroups(List<ItemGroup> groups) {
    allGroups = groups;
    row2Group = <int, ItemGroup>{};
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
  late Map<int, ItemGroup> row2Group;
  late List<ItemGroup> allGroups;

  Future seed() => Future.wait(allGroups.map((e) => e.seed()));

  Future fromAzureDownload(AzureDataDownload rows) async {
    await box.clear();
    final puts = <MapEntry<dynamic, dynamic>>[];
    for (var row in rows.entries)
      for (var prop in rows.entries) {
        final key = BoxKey.azure(row.key, prop.key);
        final messageGroup = row2Group[key.rowId]!;
        puts.add(MapEntry(key.boxKey, messageGroup.create(key, prop.value)));
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

abstract class Place {
  const Place(this.storage);

  final Storage storage;

  BoxKey get defaultKey;

  BoxItem createBoxItem(BoxKey key, dynamic value);

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

  Future seed() => Future.value();
}

abstract class SinglePlace<T> extends Place {
  SinglePlace(Storage storage, {required this.rowId, required this.propId}) : super(storage);

  final int rowId;
  final int propId;

  BoxKey getKey([BoxKey? key]) => key ?? defaultKey;
  int getBoxKey([BoxKey? key]) => getKey(key).boxKey;

  BoxItem create(BoxKey? key, dynamic value) {
    key ??= getKey(key);
    return createBoxItem(key, value)..key = key.boxKey;
  }

  BoxItem? getBox([BoxKey? key]) {
    final boxItem = storage.box.get(getBoxKey(key));
    return boxItem == null || boxItem.isDeleted ? null : boxItem;
  }

  bool exists([BoxKey? key]) => storage.box.containsKey(getBoxKey(key));

  Future delete([BoxKey? key]) {
    final boxItem = getBox(key);
    rAssert(boxItem != null);
    boxItem!.isDeleted = true;
    return saveBoxItem(boxItem);
  }

  @override
  BoxKey get defaultKey => BoxKey.idx(rowId, propId);
}

abstract class SinglePlaceValue<T> extends SinglePlace<T> {
  SinglePlaceValue(Storage storage, {required int rowId, required int propId}) : super(storage, rowId: rowId, propId: propId);

  T? getValue([BoxKey? key]) => getBox()?.value;

  Future saveValue(T value, [BoxKey? key]) {
    final BoxItem boxItem = getBox(key) ?? create(key, 0);
    boxItem.value = value;
    return saveBoxItem(boxItem);
  }
}

class SinglePlaceInt extends SinglePlaceValue<int> {
  SinglePlaceInt(Storage storage, {required int rowId, required int propId}) : super(storage, rowId: rowId, propId: propId);

  @override
  BoxItem createBoxItem(BoxKey key, dynamic value) => BoxInt()..value = value;
}

abstract class SinglePlaceMsg<T extends $pb.GeneratedMessage> extends SinglePlace<T> {
  SinglePlaceMsg(Storage storage, {required int rowId, required int propId}) : super(storage, rowId: rowId, propId: propId);

  T? getValue([BoxKey? key]) {
    final boxItem = getBox(key) as BoxMsg<T>?;
    return boxItem == null || boxItem.isDeleted ? null : boxItem.msg!;
  }

  Future saveValue(T value, [BoxKey? key]) {
    final boxItem = (getBox(key) ?? create(key, null)) as BoxMsg<T>;
    boxItem.msg = value;
    return saveBoxItem(boxItem);
  }

  Future updateValue(BoxKey? key, void proc(T t)) {
    final boxItem = getBox(key) as BoxMsg<T>;
    proc(boxItem.msg!);
    return saveBoxItem(boxItem);
  }

  @override
  BoxItem create(BoxKey? key, dynamic value) {
    assert(value is T);
    key ??= getKey(key);
    final res = (createBoxItem(key, null) as BoxMsg<T>)..key = key.boxKey;
    final msg = value as T;
    res.setMsgId(msg, key.boxKey);
    return res..msg = msg;
  }
}

abstract class ItemGroup extends Place {
  ItemGroup(Storage storage, {required this.rowStart, required this.rowEnd}) : super(storage);

  final int rowStart;
  final int rowEnd;

  @override
  BoxKey get defaultKey => throw UnimplementedError();

  BoxItem create(BoxKey key, dynamic value) => createBoxItem(key, value)..key = key.boxKey;
}

class SinglesGroup extends ItemGroup {
  SinglesGroup(Storage storage, {required int row, required this.singles}) : super(storage, rowStart: row, rowEnd: row);

  final List<SinglePlace> singles;

  @override
  BoxItem createBoxItem(BoxKey key, dynamic value) {
    assert(key.propId < singles.length);
    return singles[key.propId].createBoxItem(key, value);
  }
}

abstract class MessagesGroup<T extends $pb.GeneratedMessage> extends ItemGroup {
  MessagesGroup(
    Storage storage, {
    required int rowStart,
    required int rowEnd,
    required this.itemsPlace,
  }) : super(storage, rowStart: rowStart, rowEnd: rowEnd);

  final SinglePlaceMsg<T> itemsPlace;

  @override
  BoxItem createBoxItem(BoxKey key, dynamic value) => itemsPlace.createBoxItem(key, value);

  Iterable<BoxMsg<T>> getItems() => storage.box
      .valuesBetween(
        startKey: BoxKey.idx(itemsPlace.rowId, itemsPlace.propId).boxKey,
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
    required SinglePlaceMsg<T> itemsPlace,
  }) : super(storage, rowStart: rowStart, rowEnd: rowEnd, itemsPlace: itemsPlace);

  final SinglePlaceValue<int> uniqueCounter;

  @override
  BoxItem createBoxItem(BoxKey key, dynamic value) {
    if (key.rowId == rowStart && key.propId == 0) return uniqueCounter.createBoxItem(key, value);
    return super.createBoxItem(key, value);
  }

  Future addNewGroupItems(List<T> msgs) async {
    final uniqueBox = uniqueCounter.getBox() as BoxInt;
    var nextKey = BoxKey(uniqueBox.value);
    final futures = msgs.map((msg) {
      nextKey = BoxKey(uniqueBox.value).next();
      uniqueBox.value = nextKey.boxKey;
      rAssert(nextKey.rowId >= rowStart && nextKey.rowId <= rowStart);
      rAssert(nextKey.propId <= 252);
      final boxItem = itemsPlace.create(nextKey, msg) as BoxMsg<T>;
      return saveBoxItem(boxItem);
    }).toList();
    futures.add(uniqueCounter.saveValue(nextKey.boxKey));
    await Future.wait(futures);
    storage.onChanged();
  }

  @override
  Future seed() async {
    await super.seed();
    if (!uniqueCounter.exists()) await uniqueCounter.saveValue(itemsPlace.defaultKey.boxKey - 1);
  }
}

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
