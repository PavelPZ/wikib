import 'dart:typed_data';

import 'package:azure_storage/azure_storage.dart';
import 'package:hive/hive.dart';
import 'package:protobuf_for_dart/algorithm.dart' as dom;
import 'package:riverpod/riverpod.dart';
import 'package:utils/utils.dart';

// flutter pub run build_runner watch --delete-conflicting-outputs
part 'device_storage.g.dart';

class DeviceStorage extends Storage<DBDeviceId> {
  DeviceStorage(Ref ref, StorageInfo info) : super(ref, info) {
    setAllGroups([
      SinglesGroup(this, row: 1, singles: [
        deviceId = PlaceInt(this, rowId: 1, propId: 0),
        deviceName = PlaceString(this, rowId: 2, propId: 0),
        authProfile = PlaceAuthProfile(this, rowId: 3, propId: 0),
      ]),
    ]);
  }

  late PlaceInt deviceId;
  late PlaceString deviceName;
  late PlaceAuthProfile authProfile;

  @override
  void seed() {
    super.seed();
    if (!deviceId.exists()) deviceId.saveValue(Day.nowMilisecUtc);
  }
}

class PlaceAuthProfile extends PlaceMsg<dom.AuthProfile> {
  PlaceAuthProfile(Storage storage, {required int rowId, required int propId}) : super(storage, rowId: rowId, propId: propId);

  @override
  BoxItem createBoxItem() => BoxAuthProfile();
}

@HiveType(typeId: 21)
class BoxAuthProfile extends BoxMsg<dom.AuthProfile> {
  @override
  dom.AuthProfile msgCreator() => dom.AuthProfile();

  @override
  void setMsgId(dom.AuthProfile msg, int id) => msg.id = id;
}
