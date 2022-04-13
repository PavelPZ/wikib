import 'package:azure/azure.dart';
import 'package:riverpod/riverpod.dart';
import 'package:utils/utils.dart';

final emailProvider = Provider<String>((_) => 'pzika@langmaster.cz');
final rewiseIdProvider = Provider<DBRewiseId>((_) => DBRewiseId(speak: 'cs', learn: 'en'));
final debugIsTestProvider = StateProvider<bool>((_) => false);

// Azure account
final azureAccountProvider = Provider<AzureAccounts>((_) => const AzureAccounts());

// Azure account + 'users'
final azureRewiseUsersTableAccountProvider =
    Provider<TableAccount>((ref) => TableAccount(azureAccounts: ref.watch(azureAccountProvider), tableName: 'users', isEmulator: false));

// Azure users table
final azureRewiseUsersTableProvider = Provider<TableStorage>((ref) => TableStorage(account: ref.watch(azureRewiseUsersTableAccountProvider)));
