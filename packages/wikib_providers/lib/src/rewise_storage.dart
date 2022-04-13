import 'package:azure/azure.dart';
import 'package:hive/hive.dart';
import 'package:rewise_storage/rewise_storage.dart';
import 'package:riverpod/riverpod.dart';

import 'wikb_providers.dart';

// rewise hive box
final rewiseHiveBoxProvider = FutureProvider<Box>((ref) =>
    Hive.openBox(ref.watch(rewiseIdProvider).partition(ref.watch(emailProvider)), path: ref.watch(debugIsTestProvider) ? r'd:\temp\hive' : null));

final rewiseStorageProvider = FutureProvider<RewiseStorage>((ref) async {
  final old = ref.read(_rewiseStorageOldProvider.notifier);
  if (old.state != null) await old.state!.close();
  final nw = RewiseStorage(
    await ref.watch(rewiseHiveBoxProvider.future),
    ref.watch(azureRewiseUsersTableProvider),
    ref.watch(rewiseIdProvider),
    ref.watch(emailProvider),
  );
  old.state = nw;
  return nw;
});

final _rewiseStorageOldProvider = StateProvider<RewiseStorage?>((_) => null);
