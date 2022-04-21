import 'package:azure/azure.dart';
import 'package:azure_storage/azure_storage.dart';
import 'package:hive/hive.dart';
import 'package:rewise_storage/rewise_storage.dart';
import 'package:riverpod/riverpod.dart';
import 'package:utils/utils.dart';

part 'storage_provider.dart';

final emailProvider = StateProvider<String?>((_) => null, name: 'emailProvider');
final rewiseIdProvider = StateProvider<DBRewiseId?>((_) => null, name: 'rewiseIdProvider'); // null => close RewiseStorage
final debugIsAzureEmulator = StateProvider<bool>((_) => false, name: 'debugIsAzureEmulator');
final debugDeviceIdProvider = StateProvider<String?>((_) => null, name: 'debugDeviceId');

// Azure account
final azureAccountProvider = Provider<AzureAccounts>((_) => const AzureAccounts(), name: 'azureAccountProvider');

// Azure account + 'users'
final azureRewiseUsersTableAccountProvider = Provider<TableAccount?>(
  (ref) => ref.watch(emailProvider) == null
      ? null
      : TableAccount(azureAccounts: ref.watch(azureAccountProvider), tableName: 'users', isEmulator: ref.watch(debugIsAzureEmulator)),
  name: 'azureRewiseUsersTableAccountProvider',
);

final emailOrEmptyProvider = Provider<String>((ref) => ref.watch(emailProvider) ?? emptyEMail, name: 'emailOrEmptyProvider');

// Rewise Storage
final rewiseStorageProvider = getStorageProvider<RewiseStorage>(RewiseStorage.new, _rewiseStorageInfoProvider, _oldRewiseStorageProvider);
final debugRewiseStorageDeleteProvider = getDebugStorageDeleteProvider<RewiseStorage>(_rewiseStorageInfoProvider);
final _rewiseStorageInfoProvider = getStorageInfoProvider<RewiseStorage>(rewiseIdProvider, azureRewiseUsersTableAccountProvider);
final _oldRewiseStorageProvider = getOldStorageProvider<RewiseStorage>();
