import 'dart:typed_data';

import 'package:azure/azure.dart';
import 'package:hive/hive.dart';
import 'package:riverpod/riverpod.dart';
import 'package:protobuf_for_dart/algorithm.dart' as dom;
import 'package:utils/utils.dart';

// flutter pub run build_runner watch --delete-conflicting-outputs
part 'model.g.dart';

final rewiseStorageProvider = Provider<RewiseStorage>((_) => throw UnimplementedError());
List<Override> rewiseStorageOverrides(RewiseStorage storage) => <Override>[rewiseStorageProvider.overrideWithValue(storage)];

void initRewiseStorage() {
  initStorage();
  Hive.registerAdapter(BoxFactAdapter());
  Hive.registerAdapter(BoxDailyAdapter());
  Hive.registerAdapter(BoxBookAdapter());
  Hive.registerAdapter(BoxConfigAdapter());
}

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

typedef TRows = Map<String, Map<String, dynamic>>;

class RewiseStorage extends Storage {
  RewiseStorage(Box storage) : super(storage) {
    setAllGroups([
      row0 = SinglesGroup(this, row: 0, singles: []),
      row1 = SinglesGroup(this, row: 1, singles: [
        config = SinglePlaceConfig(this, rowId: 1, propId: 0),
      ]),
      books = MessagesGroupBook(
        this,
        rowStart: 2,
        rowEnd: 3,
        uniqueCounter: SinglePlaceInt(this, rowId: 2, propId: 0),
        itemsPlace: SinglePlaceBook(this, rowId: 2, propId: 1),
      ),
      daylies = MessagesGroupDaily(
        this,
        rowStart: 4,
        rowEnd: 7,
        uniqueCounter: SinglePlaceInt(this, rowId: 4, propId: 0),
        actDay: SinglePlaceInt(this, rowId: 4, propId: 1),
        itemsPlace: SinglePlaceDaily(this, rowId: 4, propId: 2),
      ),
      facts = MessagesGroupFact(
        this,
        rowStart: 8,
        rowEnd: 99,
        uniqueCounter: SinglePlaceInt(this, rowId: 8, propId: 0),
        itemsPlace: SinglePlaceFact(this, rowId: 8, propId: 1),
      ),
    ]);
  }
  late SinglesGroup row0;
  late SinglesGroup row1;
  late SinglePlaceConfig config;
  late MessagesGroupDaily daylies;
  late MessagesGroupBook books;
  late MessagesGroupFact facts;

  @override
  void onChanged() {}
}

class MessagesGroupDaily extends MessagesGroupWithCounter<dom.Daily> {
  MessagesGroupDaily(
    Storage storage, {
    required int rowStart,
    required int rowEnd,
    required SinglePlaceValue<int> uniqueCounter,
    required this.actDay,
    required SinglePlaceMsg<dom.Daily> itemsPlace,
  }) : super(storage, rowStart: rowStart, rowEnd: rowEnd, itemsPlace: itemsPlace, uniqueCounter: uniqueCounter);

  final SinglePlaceValue<int> actDay;

  @override
  BoxItem createBoxItem(int key, dynamic value) {
    final boxKey = BoxKey(key);
    if (boxKey.rowId == rowStart && boxKey.propId == 1) return actDay.createBoxItem(key, value);
    return super.createBoxItem(key, value);
  }

  @override
  Future seed() async {
    await super.seed();
    if (actDay.getValue() == null) await actDay.saveValue(Day.now);
  }
}

class MessagesGroupFact extends MessagesGroupWithCounter<dom.Fact> {
  MessagesGroupFact(
    Storage storage, {
    required int rowStart,
    required int rowEnd,
    required SinglePlaceValue<int> uniqueCounter,
    required SinglePlaceMsg<dom.Fact> itemsPlace,
  }) : super(storage, rowStart: rowStart, rowEnd: rowEnd, itemsPlace: itemsPlace, uniqueCounter: uniqueCounter);
}

class MessagesGroupBook extends MessagesGroupWithCounter<dom.Book> {
  MessagesGroupBook(
    Storage storage, {
    required int rowStart,
    required int rowEnd,
    required SinglePlaceValue<int> uniqueCounter,
    required SinglePlaceMsg<dom.Book> itemsPlace,
  }) : super(storage, rowStart: rowStart, rowEnd: rowEnd, itemsPlace: itemsPlace, uniqueCounter: uniqueCounter);
}

class SinglePlaceFact extends SinglePlaceMsg<dom.Fact> {
  SinglePlaceFact(Storage storage, {required int rowId, required int propId}) : super(storage, rowId: rowId, propId: propId);

  @override
  BoxItem createBoxItem(int key, dynamic value) => value == null ? BoxFact() : BoxFact()
    ..value = value;
}

class SinglePlaceDaily extends SinglePlaceMsg<dom.Daily> {
  SinglePlaceDaily(Storage storage, {required int rowId, required int propId}) : super(storage, rowId: rowId, propId: propId);

  @override
  BoxItem createBoxItem(int key, dynamic value) => value == null ? BoxDaily() : BoxDaily()
    ..value = value;
}

class SinglePlaceBook extends SinglePlaceMsg<dom.Book> {
  SinglePlaceBook(Storage storage, {required int rowId, required int propId}) : super(storage, rowId: rowId, propId: propId);

  @override
  BoxItem createBoxItem(int key, dynamic value) => value == null ? BoxBook() : BoxBook()
    ..value = value;
}

class SinglePlaceConfig extends SinglePlaceMsg<dom.Config> {
  SinglePlaceConfig(Storage storage, {required int rowId, required int propId}) : super(storage, rowId: rowId, propId: propId);

  @override
  BoxItem createBoxItem(int key, dynamic value) => value == null ? BoxConfig() : BoxConfig()
    ..value = value;
}

@HiveType(typeId: 10)
class BoxFact extends BoxMsg<dom.Fact> {
  @override
  dom.Fact msgCreator() => dom.Fact();

  @override
  void setMsgId(dom.Fact f, int id) => f.id = id;
}

@HiveType(typeId: 11)
class BoxDaily extends BoxMsg<dom.Daily> {
  @override
  dom.Daily msgCreator() => dom.Daily();

  @override
  void setMsgId(dom.Daily d, int id) => d.id = id;
}

@HiveType(typeId: 12)
class BoxBook extends BoxMsg<dom.Book> {
  @override
  dom.Book msgCreator() => dom.Book();

  @override
  void setMsgId(dom.Book b, int id) => b.id = id;
}

@HiveType(typeId: 13)
class BoxConfig extends BoxMsg<dom.Config> {
  @override
  dom.Config msgCreator() => dom.Config();

  @override
  void setMsgId(dom.Config c, int id) => c.id = id;
}
