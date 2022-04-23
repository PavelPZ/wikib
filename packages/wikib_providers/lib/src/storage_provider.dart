part of 'wikb_providers.dart';

Provider<StorageInfo> getStorageInfoProvider<TStorage extends Storage>(
  AlwaysAliveProviderBase<DBRewiseId?> dbIdProvider,
  Provider<TableAccount?> tableAccountProvider,
) =>
    Provider<StorageInfo>(
      (ref) => StorageInfo(
        dbId: ref.watch(dbIdProvider),
        emailOrEmpty: ref.watch(emailOrEmptyProvider),
        debugDeviceId: ref.watch(debugDeviceIdProvider),
        tableAccount: ref.watch(tableAccountProvider),
      ),
      name: 'storageInfoProvider.${TStorage.runtimeType}',
    );

FutureProvider<TStorage?> getStorageProvider<TStorage extends Storage>(
  TStorage create(StorageInfo info),
  Provider<StorageInfo> storageInfoProvider,
  StateProvider<TStorage?> oldStorageProvider,
) =>
    FutureProvider<TStorage?>(
      (ref) async {
        final storageInfo = ref.watch(storageInfoProvider);
        final oldStorage = ref.read(oldStorageProvider.notifier);

        if (storageInfo.isEmpty) {
          if (oldStorage.state == null) return null;
          await oldStorage.state!.close();
          oldStorage.state = null;
          return null;
        }

        await storageInfo.initHiveBox();

        final res = create(storageInfo);
        if (oldStorage.state != null &&
            oldStorage.state!.info.emailOrEmpty == emptyEMail &&
            storageInfo.emailOrEmpty != emptyEMail &&
            oldStorage.state!.info.id.eq(storageInfo.id)) {
          assert(storageInfo.hiveBox != oldStorage.state!.box);
          await oldStorage.state!.moveTo(res);
        } else {
          if (oldStorage.state != null && oldStorage.state!.box != storageInfo.hiveBox) await oldStorage.state!.close();
          assert(storageInfo.hiveBox!.isOpen);
          await res.initialize();
        }
        oldStorage.state = res;
        return res;
      },
      name: 'storageProvider.${TStorage.runtimeType}',
    );

StateProvider<TStorage?> getOldStorageProvider<TStorage extends Storage>() => StateProvider<TStorage?>(
      (_) => null,
      name: 'oldStorageProvider.${TStorage.runtimeType}',
    );

Provider<Future Function()?> getDebugStorageDeleteProvider<TStorage extends Storage>(
  Provider<StorageInfo> storageInfoProvider,
) =>
    Provider<Future Function()?>(
      (ref) {
        final storageInfo = ref.watch(storageInfoProvider);
        if (storageInfo.isEmpty) return null;
        return () async {
          await storageInfo.initHiveBox();
          await storageInfo.hiveBox!.deleteFromDisk();
          storageInfo.hiveBox = null;
          await Storage.debugDeleteAzureAll(storageInfo.getTableStorage());
        };
      },
      name: 'debugStorageDeleteProvider.${TStorage.runtimeType}',
    );
