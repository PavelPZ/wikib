import 'package:azure/azure.dart';
import 'package:azure_storage/azure_storage.dart';
import 'package:hive/hive.dart';
import 'package:riverpod/riverpod.dart';
import 'package:utils/utils.dart';

import 'wikb_providers.dart';

class StorageProviders<TStorage extends Storage> {
  StorageProviders(
    AlwaysAliveProviderBase<DBRewiseId?> dbIdProvider,
    TStorage create(Box storage, TableStorage? azureTable, DBId dbId, String email),
  ) {
    _hiveProvider = FutureProvider<Box?>((ref) async {
      final dbId = ref.watch(dbIdProvider);
      final emailOrEmpty = ref.watch(emailOrEmptyProvider);
      ref.watch(eTagConflictProvider);
      final debugHivePath = ref.watch(debugHivePathProvider);
      final debugDelete = ref.watch(debugDeleteProvider);
      var debugDeviceId = ref.watch(debugDeviceIdProvider);

      debugDeviceId = debugDeviceId == null ? '' : debugDeviceId + '-';
      // print('*** StorageProviders._hive emailOrEmptyProvider: ${ref.read(emailOrEmptyProvider)}');
      final res = dbId == null
          ? null
          : await Hive.openBox(
              debugDeviceId + dbId.partitionKey(emailOrEmpty),
              path: debugHivePath,
            );
      if (res != null && debugDelete) {
        await res.deleteFromDisk();
        return null;
      }
      return res;
    }, name: 'StorageProviders._hive');
    storage = FutureProvider<TStorage?>((ref) async {
      final _old = ref.read(_oldProvider.notifier);
      final dbId = ref.watch(dbIdProvider);
      final email = ref.watch(emailProvider);
      final emailOrEmpty = ref.watch(emailOrEmptyProvider);
      final debugDelete = ref.watch(debugDeleteProvider);
      final azureRewiseUsersTable = ref.watch(azureRewiseUsersTableProvider);
      final _hive = await ref.watch(_hiveProvider.future);
      ref.watch(eTagConflictProvider);

      if (dbId == null) {
        if (_old.state != null) await _old.state!.close();
        _old.state = null;
        return null;
      }
      final table = email == null ? null : azureRewiseUsersTable;
      // print('*** StorageProviders.storage emailOrEmptyProvider: ${ref.read(emailOrEmptyProvider)}');
      if (debugDelete) {
        if (table != null) await Storage.debugDeleteAzureAll(dbId.partitionKey(emailOrEmpty), table);
        return null;
      }
      TStorage res = create(_hive!, table, dbId, emailOrEmpty);
      if (_old.state != null && _old.state!.email == emptyEMail && emailOrEmpty != emptyEMail && _old.state!.dbId.eq(dbId)) {
        assert(_hive != _old.state!.box);
        await _old.state!.moveTo(res);
      } else {
        if (_old.state != null && _old.state!.box != _hive) await _old.state!.close();
        assert(_hive.isOpen != false);
        await res.initialize();
      }
      _old.state = res;
      return res;
    }, name: 'StorageProviders.storage');
  }
  late FutureProvider<Box?> _hiveProvider;
  final _oldProvider = StateProvider<TStorage?>((_) => null, name: 'StorageProviders._old');
  late FutureProvider<TStorage?> storage;
}
