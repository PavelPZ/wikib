import 'dart:typed_data';

import 'package:hive/hive.dart';
import 'package:riverpod/riverpod.dart';
import 'package:protobuf/protobuf.dart' as $pb;
import 'package:utils/utils.dart';

import '../forStorage.dart';

// flutter pub run build_runner watch --delete-conflicting-outputs
part 'model.g.dart';

final storageBoxProvider = Provider<Box>((_) => throw UnimplementedError());

Future initStorage(String name) async {
  await Hive.openBox(name);
  Hive.registerAdapter(BoxIntAdapter());
  Hive.registerAdapter(BoxStringAdapter());
}

List<Override> scopeStorage(Box box) => <Override>[storageBoxProvider.overrideWithValue(box)];

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

  final Box box;
  late Map<int, ItemGroup> row2Group;
  late List<ItemGroup> allGroups;

  Future fromAzureDownload(AzureDataDownload rows) async {
    await box.clear();
    final puts = <MapEntry<dynamic, dynamic>>[];
    for (var row in rows.entries)
      for (var prop in rows.entries) {
        final key = BoxKey.azure(row.key, prop.key);
        final messageGroup = row2Group[key.rowId]!;
        puts.add(MapEntry(key.boxKey, messageGroup.createBoxItem(key, prop.value)));
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
}

abstract class BoxItem<T> extends HiveObject {
  int get key;
  set key(int v);

  T get value;
  set value(T v);

  int get version;
  set version(int v);

  bool get isDeleted;
  set isDeleted(bool v);

  bool get isDefered;
  set isDefered(bool v);

  String get rowKey => BoxKey.getRowKey(key);
  String get rowPropId => BoxKey.getRowPropId(key);
}

@HiveType(typeId: 1)
class BoxInt extends BoxItem<int> {
  @override
  @HiveField(0, defaultValue: 0)
  int key = 0;

  @override
  @HiveField(1, defaultValue: 0)
  int value = 0;

  @HiveField(2, defaultValue: 0)
  @override
  int version = 0;

  @HiveField(3, defaultValue: false)
  @override
  bool isDeleted = false;

  @HiveField(4, defaultValue: false)
  @override
  bool isDefered = false;
}

@HiveType(typeId: 2)
class BoxString extends BoxItem<String> {
  @override
  @HiveField(0, defaultValue: 0)
  int key = 0;

  @HiveField(1, defaultValue: '')
  @override
  String value = '';

  @HiveField(2, defaultValue: 0)
  @override
  int version = 0;

  @HiveField(3, defaultValue: false)
  @override
  bool isDeleted = false;

  @HiveField(4, defaultValue: false)
  @override
  bool isDefered = false;
}

abstract class BoxMsg<T extends $pb.GeneratedMessage> extends BoxItem<Uint8List?> {
  T msgCreator();
  void setId(int id);

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
}

abstract class Place {
  const Place(this.storage);

  final Storage storage;

  BoxItem createBoxItem(BoxKey key, dynamic value);

  BoxItem? getBox(BoxKey key) => storage.box.get(key);

  Future delete(BoxKey key) {
    final boxItem = getBox(key);
    rAssert(boxItem != null);
    boxItem!.isDeleted = true;
    return saveBoxItem(boxItem);
  }

  Future saveBoxItem(BoxItem boxItem) {
    boxItem.version = Day.nowMilisecUtc;
    boxItem.isDefered = true;
    final future = boxItem.save();
    storage._onChanged();
    return future;
  }
}

abstract class SinglePlace<T> extends Place {
  SinglePlace(Storage storage, {required this.rowId, required this.propId}) : super(storage);

  final int rowId;
  final int propId;
}

abstract class SinglePlaceValue<T> extends SinglePlace<T> {
  SinglePlaceValue(Storage storage, {required int rowId, required int propId}) : super(storage, rowId: rowId, propId: propId);

  T? getValue([BoxKey? key]) {
    final boxItem = getBox(key ?? BoxKey.idx(rowId, propId)) as BoxItem<T>?;
    return boxItem == null || boxItem.isDeleted ? null : boxItem.value;
  }

  Future saveValue(T value, [BoxKey? key]) {
    final BoxItem<T> boxItem = storage.box.get(key ?? BoxKey.idx(rowId, propId).boxKey);
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
    // final BoxMsg<T>? boxItem = storage.box.get(key ?? BoxKey.idx(rowId, propId));
    final boxItem = getBox(key ?? BoxKey.idx(rowId, propId)) as BoxMsg<T>?;
    return boxItem == null || boxItem.isDeleted ? null : boxItem.msg!;
  }

  Future saveValue(T value, [BoxKey? key]) {
    final BoxMsg<T> boxItem = storage.box.get(key ?? BoxKey.idx(rowId, propId).boxKey);
    boxItem.msg = value;
    return saveBoxItem(boxItem);
  }
}

abstract class ItemGroup extends Place {
  ItemGroup(Storage storage, {required this.rowStart, required this.rowEnd}) : super(storage);

  final int rowStart;
  final int rowEnd;
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
    required this.uniqueCounter,
    required this.itemsPlace,
  }) : super(storage, rowStart: rowStart, rowEnd: rowEnd);

  final SinglePlaceValue<int> uniqueCounter;
  final SinglePlaceMsg<T> itemsPlace;

  @override
  BoxItem createBoxItem(BoxKey key, dynamic value) {
    if (key.rowId == rowStart && key.propId == 0) return uniqueCounter.createBoxItem(key, value);
    return itemsPlace.createBoxItem(key, value);
  }

  Future addNewGroupItem(T msg) {
    final nextKey = BoxKey(uniqueCounter.getValue()!).next();
    rAssert(nextKey.rowId >= rowStart && nextKey.rowId <= rowStart);
    rAssert(nextKey.propId <= 252);
    final boxItem = itemsPlace.createBoxItem(nextKey, null) as BoxMsg<T>;
    boxItem.msg = msg;
    boxItem.setId(nextKey.boxKey);
    return saveBoxItem(boxItem);
  }
}

class BoxKey {
  const BoxKey(this.boxKey);
  const BoxKey.idx(int rowId, int propId)
      : assert(propId <= 252),
        assert(propId <= 255),
        boxKey = rowId << 8 + propId;
  factory BoxKey.azure(String rowId, String propId) => BoxKey.idx(_hex2Byte(rowId), _hex2Byte(propId));

  final int boxKey;
  int get rowId => boxKey >> 8;
  int get propId => boxKey & 0xff;

  BoxKey next() => propId < 252 ? BoxKey(boxKey + 1) : BoxKey.idx(rowId + 1, 0);

  //-------- statics

  static int nextKey(int key) {
    final rowId = key >> 8;
    final propId = key & 0xff;
    return propId < 252 ? key + 1 : (rowId + 1) << 8;
  }

  static String getRowKey(int key) => _byte2Hex(key >> 8);
  static String getRowPropId(int key) => _byte2Hex(key & 0xff);

  //-------- RowData
  String get rowKey => _byte2Hex(rowId);
  String get rowPropId => _byte2Hex(propId);

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
