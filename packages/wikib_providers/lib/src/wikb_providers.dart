import 'package:azure/azure.dart';
import 'package:azure_storage/azure_storage.dart';
import 'package:hive/hive.dart';
import 'package:rewise_storage/rewise_storage.dart';
import 'package:riverpod/riverpod.dart';
import 'package:utils/utils.dart';

final emailProvider = StateProvider<String>((_) => 'pzika@langmaster.cz');
final rewiseIdProvider = StateProvider<DBRewiseId?>((_) => null); // null => close RewiseStorage
final debugHivePath = StateProvider<String?>((_) => null); // e.g. r'd:\temp\hive'
final debugIsAzureEmulator = StateProvider<bool>((_) => false);

// Azure account
final azureAccountProvider = Provider<AzureAccounts>((_) => const AzureAccounts());

// Azure account + 'users'
final azureRewiseUsersTableAccountProvider = Provider<TableAccount>(
    (ref) => TableAccount(azureAccounts: ref.watch(azureAccountProvider), tableName: 'users', isEmulator: ref.watch(debugIsAzureEmulator)));

// Azure users table
final azureRewiseUsersTableProvider = StateProvider<TableStorage?>((ref) => TableStorage(account: ref.watch(azureRewiseUsersTableAccountProvider)));

class StorageProviders<TStorage extends Storage> {
  StorageProviders(
    AlwaysAliveProviderBase<DBRewiseId?> dbIdProvider,
    TStorage create(Box storage, TableStorage? azureTable, DBRewiseId dbId, String email),
    bool debugClear,
  ) {
    _hive = FutureProvider<Box?>((ref) {
      final dbId = ref.watch(dbIdProvider);
      return dbId == null
          ? null
          : Hive.openBox(
              ref.watch(dbIdProvider)!.partitionKey(ref.watch(emailProvider)),
              path: ref.watch(debugHivePath),
            );
    });
    storage = FutureProvider<TStorage?>((ref) async {
      final old = ref.read(_old.notifier);
      if (old.state != null) await old.state!.close();
      final dbId = ref.watch(dbIdProvider);
      if (dbId == null) return null;
      final box = await ref.watch(_hive.future);
      assert(box != null);
      final nw = create(
        box!,
        ref.watch(azureRewiseUsersTableProvider),
        dbId,
        ref.watch(emailProvider),
      );
      await nw.initialize(debugClear);
      old.state = nw;
      return nw;
    });
  }
  late FutureProvider<Box?> _hive;
  final _old = StateProvider<TStorage?>((_) => null);
  late FutureProvider<TStorage?> storage;
}

final rewiseProvider = StorageProviders<RewiseStorage>(rewiseIdProvider, RewiseStorage.new, false);
final rewiseProviderDebugClear = StorageProviders<RewiseStorage>(rewiseIdProvider, RewiseStorage.new, true);
