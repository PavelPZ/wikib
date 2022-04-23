import 'package:azure_storage/azure_storage.dart';
import 'package:hive/hive.dart';
import 'package:rewise_storage/rewise_storage.dart';

export 'src/device_storage.dart';
export 'src/rewise_storage.dart';

void hiveRewiseStorageAdapters() {
  initStorage();
  Hive.registerAdapter(BoxFactAdapter());
  Hive.registerAdapter(BoxDailyAdapter());
  Hive.registerAdapter(BoxBookAdapter());
  Hive.registerAdapter(BoxConfigAdapter());

  Hive.registerAdapter(BoxAuthProfileAdapter());
}
