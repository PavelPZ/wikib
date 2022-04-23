part of 'wikib_providers.dart';

Provider<StorageInfo> getStorageInfoProvider<TStorage extends Storage>(
  AlwaysAliveProviderBase<DBId?> dbIdProvider,
  Provider<TableAccount?>? tableAccountProvider,
) =>
    Provider<StorageInfo>(
      (ref) => StorageInfo(
        dbId: ref.watch(dbIdProvider),
        emailOrEmpty: ref.watch(emailOrEmptyProvider),
        debugDeviceId: ref.watch(debugDeviceIdProvider),
        tableAccount: tableAccountProvider == null ? null : ref.watch(tableAccountProvider),
      ),
      name: 'storageInfoProvider.${TStorage.runtimeType}',
    );

FutureProvider<TStorage?> getStorageProvider<TStorage extends Storage>(
  TStorage create(Ref ref, StorageInfo info),
  Provider<StorageInfo> storageInfoProvider,
  StateProvider<TStorage?>? oldStorageProvider,
) =>
    FutureProvider<TStorage?>(
      (ref) async {
        final storageInfo = ref.watch(storageInfoProvider);

        final oldStorage = oldStorageProvider == null ? null : ref.read(oldStorageProvider.notifier);

        if (oldStorage != null && storageInfo.isEmpty) {
          if (oldStorage.state == null) return null;
          await oldStorage.state!.close();
          oldStorage.state = null;
          return null;
        }

        await storageInfo.initHiveBox();

        final res = create(ref, storageInfo);
        if (oldStorage != null &&
            oldStorage.state != null &&
            oldStorage.state!.info.emailOrEmpty == emptyEMail &&
            storageInfo.emailOrEmpty != emptyEMail &&
            oldStorage.state!.info.id.eq(storageInfo.id)) {
          assert(storageInfo.hiveBox != oldStorage.state!.box);
          await oldStorage.state!.moveTo(res);
        } else {
          if (oldStorage != null && oldStorage.state != null && oldStorage.state!.box != storageInfo.hiveBox) await oldStorage.state!.close();
          assert(storageInfo.hiveBox!.isOpen);
          await res.initialize();
        }
        if (oldStorage != null) oldStorage.state = res;
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
