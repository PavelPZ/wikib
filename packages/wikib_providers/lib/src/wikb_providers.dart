import 'package:azure/azure.dart';
import 'package:azure_storage/azure_storage.dart';
import 'package:hive/hive.dart';
import 'package:rewise_storage/rewise_storage.dart';
import 'package:riverpod/riverpod.dart';
import 'package:utils/utils.dart';

// final emailProvider = StateProvider<String?>((_) => 'pzika@langmaster.cz');
final emailProvider = StateProvider<String?>((_) => null);
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

final emailOrEmptyProvider = Provider<String>((ref) => ref.watch(emailProvider) ?? emptyEMail);

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
              ref.watch(dbIdProvider)!.partitionKey(ref.watch(emailOrEmptyProvider)),
              path: ref.watch(debugHivePath),
            );
    });
    storage = FutureProvider<TStorage?>((ref) async {
      final old = ref.read(_old.notifier);
      final dbId = ref.watch(dbIdProvider);
      if (dbId == null) {
        if (old.state != null) await old.state!.close();
        return null;
      }
      final box = await ref.watch(_hive.future);
      assert(box != null);
      final table = ref.watch(emailProvider) == null ? null : ref.watch(azureRewiseUsersTableProvider);
      final email = ref.watch(emailOrEmptyProvider);
      TStorage res;
      if (old.state != null && old.state!.email == emptyEMail && email != emptyEMail && old.state!.dbId == dbId) {
        res = await old.state!.rename(box!, table, email) as TStorage;
      } else {
        res = create(box!, table, dbId, email);
        await res.initialize(debugClear);
      }
      old.state = res;
      return res;
    });
  }
  late FutureProvider<Box?> _hive;
  final _old = StateProvider<TStorage?>((_) => null);
  late FutureProvider<TStorage?> storage;
}

final rewiseProvider = StorageProviders<RewiseStorage>(rewiseIdProvider, RewiseStorage.new, false);
final rewiseProviderDebugClear = StorageProviders<RewiseStorage>(rewiseIdProvider, RewiseStorage.new, true);
