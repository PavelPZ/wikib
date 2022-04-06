import 'dart:typed_data';

import 'package:hive/hive.dart';
import 'package:riverpod/riverpod.dart';
import 'package:protobuf/protobuf.dart' as $pb;
import 'package:protobuf_for_dart/algorithm.dart' as dom;

// flutter pub run build_runner watch --delete-conflicting-outputs
part 'model.g.dart';

final storageBoxProvider = Provider<Box>((_) => throw UnimplementedError());

Future initRewiseStorage() => Hive.openBox('rewise_storage');
Box getDB() => Hive.box('rewise_storage');
List<Override> get scopeRewiseStorage => <Override>[storageBoxProvider.overrideWithValue(getDB())];

// DEVICEID = 0; // 1 rows (max 1*252 items)
// CONFIGS = 1; // 1 rows (max 1*252 items)
//   CONFIG = 0;
//   MICROCYCLE = 1;
//   AUTH_CONFIG = 2;
// BOOKS = 2..3; // 2 rows (max 2*252 items)
//   uniqueCounter = 0;
// DAILY = 4..7; // 4 rows (max 4*252 items)
//   uniqueCounter = 0;
//   actDay = 1;
// FACT = 8..; // rest: (max (100-4-1-2)*252 items)
//   uniqueCounter = 0;

class RewiseStorage {
  RewiseStorage() {
    allGroups = [
      row0 = SinglesGroup(this, row: 0, singles: []),
      row1 = SinglesGroup(this, row: 1, singles: [
        config = SinglePlaceMsg<dom.Config>(this, rowId: 1, propId: 0),
      ]),
      books = MessagesGroupBook(
        this,
        rowStart: 2,
        rowEnd: 3,
        uniqueCounter: SinglePlaceValue<int>(this, rowId: 2, propId: 0),
      ),
      daylies = MessagesGroupDaily(
        this,
        rowStart: 4,
        rowEnd: 7,
        uniqueCounter: SinglePlaceValue<int>(this, rowId: 4, propId: 0),
        actDay: SinglePlaceValue<int>(this, rowId: 4, propId: 1),
      ),
      facts = MessagesGroupFact(
        this,
        rowStart: 8,
        rowEnd: 99,
        uniqueCounter: SinglePlaceValue<int>(this, rowId: 8, propId: 0),
      ),
    ];
  }
  late Box db;
  late SinglesGroup row0;
  late SinglesGroup row1;
  // late SinglesGroup row1;
  // late books = ItemGroup<dom.Book>();
  late MessagesGroup<dom.Daily> daylies;
  late MessagesGroup<dom.Book> books;
  late MessagesGroup<dom.Fact> facts;
  // late facts = ItemGroup<dom.Fact>();
  late List<ItemGroup> allGroups;
  late SinglePlaceMsg<dom.Config> config;
}

abstract class BoxItem<T> extends HiveObject {
  T get value;
  set value(T v);
  saveValue(T v) {
    value = v;
    save();
  }
}

@HiveType(typeId: 1)
class BoxInt extends BoxItem<int> {
  @HiveField(0, defaultValue: 0)
  int value = 0;
}

abstract class BoxMsg<T extends $pb.GeneratedMessage> extends BoxItem<Uint8List?> {
  int get version;
  set version(int v);

  T? get msg {
    if (_msg != null) return _msg!;
    // deserialize from value
    return _msg!;
  }

  void saveMsg(T? v) {
    _msg = v;
    if (v == null) saveValue(null);
    // todo serialize v to value and saveValue(null);
  }

  T? _msg;
}

@HiveType(typeId: 5)
class BoxFact extends BoxMsg<dom.Fact> {
  @HiveField(0, defaultValue: null)
  @override
  Uint8List? value;

  @HiveField(1, defaultValue: 0)
  @override
  int version = 0;
}

abstract class Place {
  const Place(this.db);
  final RewiseStorage db;
}

abstract class SinglePlace<T> extends Place {
  SinglePlace(RewiseStorage db, {required this.rowId, required this.propId}) : super(db);
  final int rowId;
  final int propId;
  T get value;
  set value(T v);
}

class SinglePlaceValue<T> extends SinglePlace<T> {
  SinglePlaceValue(RewiseStorage db, {required int rowId, required int propId}) : super(db, rowId: rowId, propId: propId);

  @override
  T get value => null as T;
  @override
  set value(T v) {}
}

class SinglePlaceMsg<T extends $pb.GeneratedMessage> extends SinglePlace<T> {
  SinglePlaceMsg(RewiseStorage db, {required int rowId, required int propId}) : super(db, rowId: rowId, propId: propId);

  @override
  T get value => null as T;
  @override
  set value(T v) {}
}

abstract class ItemGroup extends Place {
  ItemGroup(RewiseStorage db, {required this.rowStart, required this.rowEnd}) : super(db);
  final int rowStart;
  final int rowEnd;
}

class SinglesGroup extends ItemGroup {
  SinglesGroup(RewiseStorage db, {required int row, required this.singles}) : super(db, rowStart: row, rowEnd: row);
  final List<SinglePlace> singles;
}

class MessagesGroup<T extends $pb.GeneratedMessage> extends ItemGroup {
  MessagesGroup(RewiseStorage db, {required int rowStart, required int rowEnd, required this.uniqueCounter})
      : super(db, rowStart: rowStart, rowEnd: rowEnd);
  final SinglePlaceValue<int> uniqueCounter;
}

class MessagesGroupDaily extends MessagesGroup<dom.Daily> {
  MessagesGroupDaily(RewiseStorage db,
      {required int rowStart, required int rowEnd, required SinglePlaceValue<int> uniqueCounter, required this.actDay})
      : super(db, rowStart: rowStart, rowEnd: rowEnd, uniqueCounter: uniqueCounter);
  final SinglePlaceValue<int> actDay;
}

class MessagesGroupFact extends MessagesGroup<dom.Fact> {
  MessagesGroupFact(RewiseStorage db, {required int rowStart, required int rowEnd, required SinglePlaceValue<int> uniqueCounter})
      : super(db, rowStart: rowStart, rowEnd: rowEnd, uniqueCounter: uniqueCounter);
}

class MessagesGroupBook extends MessagesGroup<dom.Book> {
  MessagesGroupBook(RewiseStorage db, {required int rowStart, required int rowEnd, required SinglePlaceValue<int> uniqueCounter})
      : super(db, rowStart: rowStart, rowEnd: rowEnd, uniqueCounter: uniqueCounter);
}

class BoxKey {
  const BoxKey(this.boxKey);
  const BoxKey.row(int rowId, int propId)
      : assert(propId <= 252),
        boxKey = rowId << 8 + propId;
  final int boxKey;
  int get rowId => boxKey >> 8;
  int get propId => boxKey & 0xff;
  BoxKey next() => propId < 252 ? BoxKey(boxKey + 1) : BoxKey.row(rowId + 1, 0);
}
