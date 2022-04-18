import 'package:azure/azure.dart';
import 'package:azure_storage/azure_storage.dart';
import 'package:hive/hive.dart';
import 'package:rewise_storage/rewise_storage.dart';
import 'package:riverpod/riverpod.dart';
import 'package:utils/utils.dart';

// final emailProvider = StateProvider<String?>((_) => 'pzika@langmaster.cz');
final emailProvider = StateProvider<String?>((_) => null, name: 'emailProvider');
final rewiseIdProvider = StateProvider<DBRewiseId?>((_) => null, name: 'rewiseIdProvider'); // null => close RewiseStorage
final debugHivePath = StateProvider<String?>((_) => null, name: 'debugHivePath'); // e.g. r'd:\temp\hive'
final debugIsAzureEmulator = StateProvider<bool>((_) => false, name: 'debugIsAzureEmulator');
final debugDeleteProvider = StateProvider<bool>((_) => false, name: 'debugDeleteProvider');

// Azure account
final azureAccountProvider = Provider<AzureAccounts>((_) => const AzureAccounts(), name: 'azureAccountProvider');

// Azure account + 'users'
final azureRewiseUsersTableAccountProvider = Provider<TableAccount>(
  (ref) => TableAccount(azureAccounts: ref.watch(azureAccountProvider), tableName: 'users', isEmulator: ref.watch(debugIsAzureEmulator)),
  name: 'azureRewiseUsersTableAccountProvider',
);

// Azure users table
final azureRewiseUsersTableProvider = StateProvider<TableStorage?>(
  (ref) => TableStorage(account: ref.watch(azureRewiseUsersTableAccountProvider)),
  name: 'azureRewiseUsersTableProvider',
);

final emailOrEmptyProvider = Provider<String>((ref) => ref.watch(emailProvider) ?? emptyEMail, name: 'emailOrEmptyProvider');

class StorageProviders<TStorage extends Storage> {
  StorageProviders(
    AlwaysAliveProviderBase<DBRewiseId?> dbIdProvider,
    TStorage create(Box storage, TableStorage? azureTable, DBId dbId, String email),
  ) {
    _hive = FutureProvider<Box?>((ref) async {
      final dbId = ref.watch(dbIdProvider);
      final email = ref.watch(emailOrEmptyProvider);
      print('*** StorageProviders._hive emailOrEmptyProvider: ${ref.read(emailOrEmptyProvider)}');
      final res = dbId == null
          ? null
          : await Hive.openBox(
              dbId.partitionKey(email),
              path: ref.watch(debugHivePath),
            );
      if (res != null && ref.watch(debugDeleteProvider)) {
        await res.deleteFromDisk();
        return null;
      }
      return res;
    }, name: 'StorageProviders._hive');
    storage = FutureProvider<TStorage?>((ref) async {
      final old = ref.read(_old.notifier);
      final dbId = ref.watch(dbIdProvider);
      if (dbId == null) {
        if (old.state != null) await old.state!.close();
        old.state = null;
        return null;
      }
      final table = ref.watch(emailProvider) == null ? null : ref.watch(azureRewiseUsersTableProvider);
      final email = ref.watch(emailOrEmptyProvider);
      print('*** StorageProviders.storage emailOrEmptyProvider: ${ref.read(emailOrEmptyProvider)}');
      if (ref.watch(debugDeleteProvider)) {
        if (table != null) await Storage.debugDeleteAzureAll(dbId.partitionKey(email), table);
        await ref.watch(_hive.future);
        return null;
      }
      final box = await ref.watch(_hive.future);
      assert(box != null);
      TStorage res = create(box!, table, dbId, email);
      if (old.state != null && old.state!.email == emptyEMail && email != emptyEMail && old.state!.dbId.eq(dbId))
        await old.state!.moveTo(res);
      else {
        await res.initialize();
      }
      old.state = res;
      return res;
    }, name: 'StorageProviders.storage');
  }
  late FutureProvider<Box?> _hive;
  final _old = StateProvider<TStorage?>((_) => null, name: 'StorageProviders._old');
  late FutureProvider<TStorage?> storage;
}

final rewiseProvider = StorageProviders<RewiseStorage>(rewiseIdProvider, RewiseStorage.new);
