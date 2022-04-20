import 'package:azure/azure.dart';
import 'package:azure_storage/azure_storage.dart';
import 'package:hive/hive.dart';
import 'package:riverpod/riverpod.dart';
import 'package:utils/utils.dart';

import 'wikb_providers.dart';

class StorageProviders<TStorage extends Storage> {
  StorageProviders(
    AlwaysAliveProviderBase<DBRewiseId?> dbIdProvider,
    TStorage create(Box storage, TableAccount? azureTable, DBId dbId, String email),
  ) {
    storageProvider = FutureProvider<TStorage?>((ref) async {
      final oldStorage = ref.read(_oldStorageProvider.notifier);
      final dbId = ref.watch(dbIdProvider);
      final emailOrEmpty = ref.watch(emailOrEmptyProvider);
      final debugDelete = ref.watch(debugDeleteProvider);
      final debugDeviceId = ref.watch(debugDeviceIdProvider);
      final azureRewiseUsersTableAccount = ref.watch(azureRewiseUsersTableAccountProvider);
      // ref.watch(eTagConflictProvider);
      if (dbId == null) {
        if (oldStorage.state == null) return null;
        await oldStorage.state!.close();
        oldStorage.state = null;
        return null;
      }

      final hiveName = '${debugDeviceId == null ? '' : debugDeviceId + '-'}${dbId.partitionKey(emailOrEmpty)}';
      final hive = await Hive.openBox(hiveName);

      // print('*** StorageProviders.storage emailOrEmptyProvider: ${ref.read(emailOrEmptyProvider)}');
      if (debugDelete) {
        if (azureRewiseUsersTableAccount != null) await Storage.debugDeleteAzureAll(dbId.partitionKey(emailOrEmpty), azureRewiseUsersTableAccount);
        await hive.deleteFromDisk();
        return null;
      }
      final res = create(hive, azureRewiseUsersTableAccount, dbId, emailOrEmpty);
      if (oldStorage.state != null && oldStorage.state!.email == emptyEMail && emailOrEmpty != emptyEMail && oldStorage.state!.dbId.eq(dbId)) {
        assert(hive != oldStorage.state!.box);
        await oldStorage.state!.moveTo(res);
      } else {
        if (oldStorage.state != null && oldStorage.state!.box != hive) await oldStorage.state!.close();
        assert(hive.isOpen);
        await res.initialize();
      }
      oldStorage.state = res;
      return res;
    }, name: 'StorageProviders.storageProvider');
  }
  final _oldStorageProvider = StateProvider<TStorage?>((_) => null, name: 'StorageProviders._oldStorageProvider');
  late FutureProvider<TStorage?> storageProvider;
}
