// ignore_for_file: unused_local_variable

import 'dart:typed_data';

import 'package:azure/azure.dart';
import 'package:azure_storage/azure_storage.dart';
import 'package:hive/hive.dart';
import 'package:riverpod/riverpod.dart';
import 'package:protobuf_for_dart/algorithm.dart' as dom;
import 'package:utils/utils.dart';

// flutter pub run build_runner watch --delete-conflicting-outputs
part 'rewise_storage.g.dart';

final rewiseStorageProvider = Provider<RewiseStorage>((_) => throw UnimplementedError());
List<Override> debugRewiseStorageOverrides(RewiseStorage storage) => <Override>[rewiseStorageProvider.overrideWithValue(storage)];

void hiveRewiseStorageAdapters() {
  initStorage();
  Hive.registerAdapter(BoxFactAdapter());
  Hive.registerAdapter(BoxDailyAdapter());
  Hive.registerAdapter(BoxBookAdapter());
  Hive.registerAdapter(BoxConfigAdapter());
}

typedef TRows = Map<String, Map<String, dynamic>>;

class RewiseStorage extends Storage<DBRewiseId> {
  RewiseStorage(Box storage, TableStorage? azureTable, DBId dbId, String email) : super(storage, azureTable, dbId, email) {
    setAllGroups([
      //systemRow,
      row1 = SinglesGroup(this, row: 1, singles: [
        config = PlaceConfig(this, rowId: 1, propId: 0),
      ]),
      books = MessagesGroupBook(
        this,
        rowStart: 2,
        rowEnd: 3,
        uniqueCounter: PlaceInt(this, rowId: 2, propId: 0),
        itemsPlace: PlaceBook(this, rowId: 2, propId: 1),
      ),
      daylies = MessagesGroupDaily(
        this,
        rowStart: 4,
        rowEnd: 7,
        uniqueCounter: PlaceInt(this, rowId: 4, propId: 0),
        actDay: PlaceInt(this, rowId: 4, propId: 1),
        itemsPlace: PlaceDaily(this, rowId: 4, propId: 2),
      ),
      facts = MessagesGroupFact(
        this,
        rowStart: 8,
        rowEnd: 99,
        uniqueCounter: PlaceInt(this, rowId: 8, propId: 0),
        itemsPlace: PlaceFact(this, rowId: 8, propId: 1),
      ),
    ]);
  }

  late SinglesGroup row1;
  late PlaceConfig config;
  late MessagesGroupDaily daylies;
  late MessagesGroupBook books;
  late MessagesGroupFact facts;
}

class MessagesGroupDaily extends MessagesGroupWithCounter<dom.Daily> {
  MessagesGroupDaily(
    Storage storage, {
    required int rowStart,
    required int rowEnd,
    required PlaceValue<int> uniqueCounter,
    required this.actDay,
    required PlaceMsg<dom.Daily> itemsPlace,
  }) : super(storage, rowStart: rowStart, rowEnd: rowEnd, itemsPlace: itemsPlace, uniqueCounter: uniqueCounter);

  final PlaceValue<int> actDay;

  @override
  BoxItem wholeAzureDownload(int key, dynamic value) {
    final boxKey = BoxKey(key);
    if (boxKey.rowId == rowStart && boxKey.propId == 1) return actDay.createFromValue(key, value);
    return super.wholeAzureDownload(key, value);
  }

  @override
  void seed() {
    super.seed();
    if (!actDay.exists()) actDay.saveValue(Day.now);
  }

  int get actDayValue => actDay.getValueOrMsg();

  void addDaylies(int newActDay, Iterable<dom.Daily> msgs) {
    if (newActDay != actDayValue) {
      clear(startItemsIncluded: true);
      // final a1 = storage.debugDump();
      seed();
      // final a2 = storage.debugDump();
      // final c = uniqueCounter.getValueOrMsg();
      actDay.saveValue(newActDay);
    }
    // final a3 = storage.debugDump();
    addItems(msgs.map((e) => e..day = newActDay));
    // final a4 = storage.debugDump();
  }
}

class MessagesGroupFact extends MessagesGroupWithCounter<dom.Fact> {
  MessagesGroupFact(
    Storage storage, {
    required int rowStart,
    required int rowEnd,
    required PlaceValue<int> uniqueCounter,
    required PlaceMsg<dom.Fact> itemsPlace,
  }) : super(storage, rowStart: rowStart, rowEnd: rowEnd, itemsPlace: itemsPlace, uniqueCounter: uniqueCounter);
}

class MessagesGroupBook extends MessagesGroupWithCounter<dom.Book> {
  MessagesGroupBook(
    Storage storage, {
    required int rowStart,
    required int rowEnd,
    required PlaceValue<int> uniqueCounter,
    required PlaceMsg<dom.Book> itemsPlace,
  }) : super(storage, rowStart: rowStart, rowEnd: rowEnd, itemsPlace: itemsPlace, uniqueCounter: uniqueCounter);
}

class PlaceFact extends PlaceMsg<dom.Fact> {
  PlaceFact(Storage storage, {required int rowId, required int propId}) : super(storage, rowId: rowId, propId: propId);

  @override
  BoxItem createBoxItem() => BoxFact();
}

class PlaceDaily extends PlaceMsg<dom.Daily> {
  PlaceDaily(Storage storage, {required int rowId, required int propId}) : super(storage, rowId: rowId, propId: propId);

  @override
  BoxItem createBoxItem() => BoxDaily();
}

class PlaceBook extends PlaceMsg<dom.Book> {
  PlaceBook(Storage storage, {required int rowId, required int propId}) : super(storage, rowId: rowId, propId: propId);

  @override
  BoxItem createBoxItem() => BoxBook();
}

class PlaceConfig extends PlaceMsg<dom.Config> {
  PlaceConfig(Storage storage, {required int rowId, required int propId}) : super(storage, rowId: rowId, propId: propId);

  @override
  BoxItem createBoxItem() => BoxConfig();
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

