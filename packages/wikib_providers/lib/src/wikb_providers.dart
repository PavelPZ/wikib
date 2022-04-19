import 'package:azure/azure.dart';
import 'package:rewise_storage/rewise_storage.dart';
import 'package:riverpod/riverpod.dart';
import 'package:utils/utils.dart';

import 'storage.dart';

// final emailProvider = StateProvider<String?>((_) => 'pzika@langmaster.cz');
final emailProvider = StateProvider<String?>((_) => null, name: 'emailProvider');
final rewiseIdProvider = StateProvider<DBRewiseId?>((_) => null, name: 'rewiseIdProvider'); // null => close RewiseStorage
final debugHivePath = StateProvider<String?>((_) => null, name: 'debugHivePath'); // e.g. r'd:\temp\hive'
final debugIsAzureEmulator = StateProvider<bool>((_) => false, name: 'debugIsAzureEmulator');
final debugDeleteProvider = StateProvider<bool>((_) => false, name: 'debugDeleteProvider');
final debugDeviceId = StateProvider<String?>((_) => null, name: 'debugDeviceId');

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

final rewiseProvider = StorageProviders<RewiseStorage>(rewiseIdProvider, RewiseStorage.new);
