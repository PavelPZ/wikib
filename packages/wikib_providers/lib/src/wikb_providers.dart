import 'package:azure/azure.dart';
import 'package:azure_storage/azure_storage.dart';
import 'package:protobuf_for_dart/algorithm.dart';
import 'package:rewise_storage/rewise_storage.dart';
import 'package:riverpod/riverpod.dart';
import 'package:utils/utils.dart';

part 'storage_provider.dart';

// *********** AUTH
final authProfileProvider = StateProvider<AuthProfile?>((_) => null);
final emailProvider = Provider<String?>((ref) {
  final profile = ref.watch(authProfileProvider);
  return profile == null || profile.email == '' ? null : profile.email;
}, name: 'emailProvider');
final emailOrEmptyProvider = Provider<String>((ref) => ref.watch(emailProvider) ?? emptyEMail, name: 'emailOrEmptyProvider');

final debugIsAzureEmulator = StateProvider<bool>((_) => false, name: 'debugIsAzureEmulator');
final debugDeviceIdProvider = StateProvider<String?>((_) => null, name: 'debugDeviceId');

// Azure account
final azureAccountProvider = Provider<AzureAccounts>((_) => const AzureAccounts(), name: 'azureAccountProvider');

// Azure account + 'users'3+
final azureRewiseUsersTableAccountProvider = Provider<TableAccount?>(
  (ref) => ref.watch(emailProvider) == null
      ? null
      : TableAccount(azureAccounts: ref.watch(azureAccountProvider), tableName: 'users', isEmulator: ref.watch(debugIsAzureEmulator)),
  name: 'azureRewiseUsersTableAccountProvider',
);

// Rewise Storage
final rewiseIdProvider = StateProvider<DBRewiseId?>((_) => null, name: 'rewiseIdProvider'); // null => close RewiseStorage
final rewiseStorageProvider = getStorageProvider<RewiseStorage>(RewiseStorage.new, _rewiseStorageInfoProvider, _oldRewiseStorageProvider);
final debugRewiseStorageDeleteProvider = getDebugStorageDeleteProvider<RewiseStorage>(_rewiseStorageInfoProvider);
final _rewiseStorageInfoProvider = getStorageInfoProvider<RewiseStorage>(rewiseIdProvider, azureRewiseUsersTableAccountProvider);
final _oldRewiseStorageProvider = getOldStorageProvider<RewiseStorage>();
