part of 'storage.dart';

abstract class Place<T> {
  Place(this.storage, {required int rowId, required int propId}) : boxKey = (rowId << 8) + propId;

  final int boxKey;
  final Storage storage;

  BoxItem createBoxItem();
  BoxItem createFromValueOrMsg(int? key, T value);

  T getValueOrMsg([int? key]) => getBox(key)!.value;
  BoxItem setValueOrMsg(T value, [int? key]) => getBox(key)!..value = value;

  int getKey([int? key]) => key ?? boxKey;
  int getBoxKey([int? key]) => getKey(key);

  BoxItem createFromValue(int key, dynamic value) => createBoxItem()
    ..key = key
    ..value = value;

  BoxItem? getBox([int? key]) {
    final boxItem = storage.info.hiveBox.get(getBoxKey(key));
    return boxItem == null || boxItem.isDeleted ? null : boxItem;
  }

  bool exists([int? key]) => getBox(key) != null;

  void delete({int? key}) {
    final boxItem = getBox(key);
    rAssert(boxItem != null);
    boxItem!.isDeleted = true;
    storage.saveBoxItem(boxItem);
  }

  void saveValue(T valueOrMsg, {int? key}) {
    final b = getBox(key);
    final res = b == null ? createFromValueOrMsg(key, valueOrMsg) : setValueOrMsg(valueOrMsg, key);
    storage.saveBoxItem(res);
  }
}

abstract class PlaceValue<T> extends Place<T> {
  PlaceValue(Storage storage, {required int rowId, required int propId}) : super(storage, rowId: rowId, propId: propId);

  @override
  BoxItem createFromValueOrMsg(int? key, T value) => createFromValue(getKey(key), value);
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
  BoxItem createFromValueOrMsg(int? key, T value) {
    key ??= getKey(key);
    return (createBoxItem() as BoxMsg<T>)
      ..setMsgId(value, key) // must be first: following "msg = msg" saves msg to uint8 value
      ..key = key
      ..msg = value;
  }

  @override
  T getValueOrMsg([int? key]) => ((getBox(key) as BoxMsg<T>).msg)!;
  @override
  BoxItem setValueOrMsg(T value, [int? key]) => (getBox(key) as BoxMsg<T>)..msg = value;
}
