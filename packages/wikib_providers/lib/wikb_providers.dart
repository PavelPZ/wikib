import 'package:azure/azure.dart';
import 'package:hive/hive.dart';
import 'package:rewise_storage/rewise_storage.dart';
import 'package:riverpod/riverpod.dart';
import 'package:utils/utils.dart';

final emailProvider = Provider<String>((_) => 'pzika@langmaster.cz');
final langSpeakProvider = Provider<String>((_) => 'cs');
final langLearnProvider = Provider<String>((_) => 'en');

// Azure account
final azureAccountProvider = Provider<AzureAccounts>((_) => const AzureAccounts());

// Azure account + 'users'
final azureRewiseUsersTableAccountProvider =
    Provider<TableAccount>((ref) => TableAccount(azureAccounts: ref.watch(azureAccountProvider), tableName: 'users', isEmulator: false));

// Azure users table
final azureRewiseUsersTableProvider = Provider<TableStorage>((ref) => TableStorage(account: ref.watch(azureRewiseUsersTableAccountProvider)));

// rewise Id: email + langLearn + langSpeak
final rewiseIdProvider = Provider<RewiseId>((ref) => RewiseId(
      email: ref.watch(emailProvider),
      learn: ref.watch(langLearnProvider),
      speak: ref.watch(langSpeakProvider),
    ));

// rewise hive box
final rewiseHiveBoxProvider = FutureProvider<Box>((ref) => Hive.openBox(ref.watch(rewiseIdProvider).primaryKey));

final rewiseStorageProvider = FutureProvider<RewiseStorage>((ref) async => RewiseStorage(
      await ref.watch(rewiseHiveBoxProvider.future),
      ref.watch(azureRewiseUsersTableProvider),
      ref.watch(rewiseIdProvider).primaryKey,
    ));
