import 'package:hive/hive.dart';
import 'package:rewise_storage/rewise_storage.dart';
import 'package:riverpod/riverpod.dart';

class WikibProvidersConfig {
  late RewiseStorage rewiseStorage;
}

Future<WikibProvidersConfig> appInit() async {
  final res = WikibProvidersConfig();
  hiveRewiseStorageAdapters();
  res.rewiseStorage = RewiseStorage(await Hive.openBox('rewise_storage'));
  res.rewiseStorage.seed(null);
  return res;
}

List<Override> wikibOverrides(WikibProvidersConfig wikibProvidersConfig) => <Override>[
      rewiseStorageProvider.overrideWithValue(
        wikibProvidersConfig.rewiseStorage,
      )
    ];
