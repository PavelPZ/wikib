import 'dart:convert';
import 'dart:typed_data';

import 'package:hive/hive.dart';
// import 'package:riverpod/riverpod.dart';
import 'package:protobuf/protobuf.dart' as $pb;
import 'package:utils/utils.dart';

import 'package:azure/azure.dart';

// flutter pub run build_runner watch --delete-conflicting-outputs
part 'model.g.dart';

void initStorage() {
  Hive.registerAdapter(BoxIntAdapter());
  Hive.registerAdapter(BoxStringAdapter());
}

const initialETag = 'initialETag';

// ***************************************
// STORAGE
// ***************************************

abstract class Storage implements IStorage {
  Storage(this.box, this.azureTable, this.primaryKey) {
    // systemRow = SinglesGroup(this, row: 0, singles: [
    //   eTagPlace = PlaceString(this, rowId: 0, propId: 0),
    //   namePlace = PlaceString(this, rowId: 0, propId: 1),
    // ]);
  }

  void initializeGroups(List<ItemsGroup> groups) {
    allGroups = groups;
    row2Group = <int, ItemsGroup>{};
    for (var grp in allGroups)
      for (var i = grp.rowStart; i <= grp.rowEnd; i++) {
        assert(row2Group[i] == null);
        row2Group[i] = grp;
      }
  }

  Box box; // due to debugReopen
  final TableStorage? azureTable;
  final String primaryKey;
  late Map<int, ItemsGroup> row2Group;
  late List<ItemsGroup> allGroups;
  // late SinglesGroup systemRow;
  // late PlaceString eTagPlace;
  // late PlaceString namePlace; // email|speakLang|learnLang

  // void seed(String? name) {
  //   if (namePlace.exists()) rAssert(namePlace.getValueOrMsg() == name);
  //   if (eTagPlace.exists()) return;
  //   eTagPlace.saveValue(initialETag);
  //   if (name != null) namePlace.saveValue(name);
  //   allGroups.forEach((e) => e.seed());
  // }
  void seed() => allGroups.forEach((e) => e.seed());

  AzureDataUpload? toAzureUpload([bool alowEmptyData = false]) {
    //if (!namePlace.exists()) return null;
    final rowGroups = <String, List<BoxItem>>{};
    var itemCount = 0;
    for (var item in box.values.cast<BoxItem>().where((b) => b.isDefered || b.key == BoxKey.eTagPlaceKey)) {
      rowGroups.update(item.rowKey, (value) => value..add(item), ifAbsent: () => <BoxItem>[item]);
      itemCount++;
    }
    assert(itemCount >= 1);
    if (!alowEmptyData && itemCount <= 1) return null;
    // finish rows
    final rows = <BatchRow>[];
    for (final r in rowGroups.entries) {
      final data = <String, dynamic>{'PartitionKey': Encoder.keys.encode(primaryKey), 'RowKey': Encoder.keys.encode(r.key)};
      BatchRow row;
      if (r.value.every((b) => b.isDeleted)) {
        rows.add(row = BatchRow(data: data, method: BatchMethod.delete));
      } else {
        for (final item in r.value.where((b) => !b.isDeleted)) item.toAzureUpload(data);
        rows.add(row = BatchRow(data: data, method: r.value.any((b) => b.isDeleted) ? BatchMethod.put : BatchMethod.merge));
      }
      for (var item in r.value) row.versions[item.key] = item.version;
    }
    return AzureDataUpload(rows: rows);
  }

  void fromAzureUpload(Map<int, int> versions) {
    // TODO(pz): eTagPlace.getBox()!..value = newETag];
    final modified = <BoxItem>[];
    for (var kv in versions.entries) {
      final item = box.get(kv.key) as BoxItem?;
      if (item == null || item.version != kv.value) continue;
      assert(item.isDefered || item.key == BoxKey.eTagPlaceKey);
      if (item.isDeleted)
        item.delete();
      else
        modified.add(item..isDefered = false);
    }
    if (modified.isNotEmpty) box.putAll(Map.fromEntries(modified.map((e) => MapEntry(e.key, e))));
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
    box.putAll(entries);
  }

  void saveBoxItem(BoxItem boxItem, {CancelToken? token}) {
    boxItem.version = Day.nowMilisecUtc;
    boxItem.isDefered = true;
    box.put(boxItem.key, boxItem);
    azureTable?.batch(this, token: token);
  }

  void saveBoxItems(Iterable<BoxItem> boxItems, {CancelToken? token}) {
    box.putAll(Map.fromEntries(boxItems.map((boxItem) {
      boxItem.version = Day.nowMilisecUtc;
      boxItem.isDefered = true;
      return MapEntry(boxItem.key, boxItem);
    })));
    azureTable?.batch(this, token: token);
  }

  Future debugReopen() async {
    await box.flush();
    await box.close();
    box = await Hive.openBox(box.name, path: box.path!.split('\\${box.name}.hive')[0]);
  }

  String debugDump([bool filter(BoxItem item)?]) {
    var all = box.values.cast<BoxItem>();
    if (filter != null) all = all.where(filter);
    return all
        .map((e) => '${e.isDeleted ? '-' : ''}${e.isDefered ? '*' : ''}${e.key}${e.value is Uint8List ? '' : '=' + e.value.toString()}')
        .join(',');
  }

  String debugDeletedAndDefered([bool filter(BoxItem item)?]) {
    var all = box.values.cast<BoxItem>();
    if (filter != null) all = all.where(filter);
    var deleted = 0, defered = 0;
    all.forEach((e) {
      if (e.isDeleted) deleted++;
      if (e.isDefered) defered++;
    });
    return 'deleted=$deleted, defered=$defered';
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

  void toAzureUpload(Map<String, dynamic> data) => data[rowPropId] = value;
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
    data[rowKey] = base64.encode(value!);
    data['$rowKey@odata.type'] = 'Edm.Binary';
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

  void delete({int? key, CancelToken? token}) {
    final boxItem = getBox(key);
    rAssert(boxItem != null);
    boxItem!.isDeleted = true;
    storage.saveBoxItem(boxItem, token: token);
  }

  void saveValue(T valueOrMsg, {int? key, CancelToken? token}) => storage.saveBoxItem(getBox(key) ?? fromValueOrMsg(key, valueOrMsg), token: token);
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

  void updateMsg(void proc(T t), {int? key, CancelToken? token}) {
    final boxItem = getBox(key) as BoxMsg<T>;
    rAssert(!boxItem.isDeleted);
    proc(boxItem.msg!);
    storage.saveBoxItem(boxItem, token: token);
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
  void seed({CancelToken? token}) {}
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

  void clear({bool startItemsIncluded = false, CancelToken? token}) =>
      storage.saveBoxItems((startItemsIncluded ? getItems() : getMsgs()).map((e) => e..isDeleted = true), token: token);
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

  Future addItems(Iterable<T> msgs, {CancelToken? token}) {
    final uniqueBox = uniqueCounter.getBox() as BoxInt;
    var nextKey = uniqueBox.value;
    final items = msgs.map((msg) => itemsPlace.fromValueOrMsg(nextKey = BoxKey.nextKey(nextKey), msg)).toList();
    items.add(uniqueBox..value = nextKey);
    storage.saveBoxItems(items, token: token);
    if (token?.canceled == true) return Future.value();
    return storage.box.flush();
  }

  @override
  Future seed({CancelToken? token}) {
    super.seed(token: token);
    if (!uniqueCounter.exists()) uniqueCounter.saveValue(itemsPlace.boxKey - 1, token: token);
    if (token?.canceled == true) return Future.value();
    return storage.box.flush();
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
  static int getBoxKey(int rowId, int propId) => (rowId << 8) + propId;
  static var eTagPlaceKey = getBoxKey(0, 0);

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
