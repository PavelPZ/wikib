part of 'storage.dart';

abstract class ItemsGroup {
  ItemsGroup(this.storage, {required this.rowStart, required this.rowEnd});

  final Storage storage;

  final int rowStart;
  final int rowEnd;

  BoxItem wholeAzureDownload(int key, dynamic value);
  void seed() {}

  Iterable<BoxItem> getItems() =>
      storage.getItems(BoxKey.getBoxKey(rowStart, 0), BoxKey.getBoxKey(rowEnd, BoxKey.maxPropId), (item) => !item.isDeleted);
}

class SinglesGroup extends ItemsGroup {
  SinglesGroup(Storage storage, {required int row, required this.singles}) : super(storage, rowStart: row, rowEnd: row);

  final List<Place> singles;

  @override
  BoxItem wholeAzureDownload(int key, dynamic value) {
    final boxKey = BoxKey(key);
    assert(boxKey.propId < singles.length);
    return singles[boxKey.propId].createFromValue(key, value);
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
  BoxItem wholeAzureDownload(int key, dynamic value) => itemsPlace.createFromValue(key, base64Decode(value));

  Iterable<BoxMsg<T>> getMsgs() =>
      storage.getItems<BoxMsg<T>>(BoxKey.getBoxKey(rowStart, 0), BoxKey.getBoxKey(rowEnd, BoxKey.maxPropId), (item) => !item.isDeleted);

  void clear({bool startItemsIncluded = false}) {
    final items = (startItemsIncluded ? getItems() : getMsgs()).toList();
    storage.saveBoxItems(items.map((e) => e
      ..isDeleted = true
      ..isDefered = true));
  }
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
  BoxItem wholeAzureDownload(int key, dynamic value) {
    final boxKey = BoxKey(key);
    if (boxKey.rowId == rowStart && boxKey.propId == 0) return uniqueCounter.createFromValue(key, value);
    return super.wholeAzureDownload(key, value);
  }

  void addItems(Iterable<T> msgs) {
    final uniqueBox = uniqueCounter.getBox() as BoxInt;
    var nextKey = uniqueBox.value;
    final items = msgs.map((msg) => itemsPlace.createFromValueOrMsg(nextKey = BoxKey.nextKey(nextKey), msg)).toList();
    items.add(uniqueBox..value = nextKey);
    storage.saveBoxItems(items);
  }

  @override
  void seed() {
    super.seed();
    if (!uniqueCounter.exists()) uniqueCounter.saveValue(itemsPlace.boxKey - 1);
  }
}
