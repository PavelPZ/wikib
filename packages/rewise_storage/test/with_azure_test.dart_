// // ignore_for_file: unused_local_variable

// import 'package:azure/azure.dart';
// import 'package:azure_storage/azure_storage.dart';
// import 'package:hive/hive.dart';
// import 'package:protobuf_for_dart/algorithm.dart' as dom;
// import 'package:rewise_storage/rewise_storage.dart';
// import 'package:riverpod/riverpod.dart';
// import 'package:test/test.dart';
// import 'package:utils/utils.dart';

// Future<RewiseStorage> createDB(
//   String email, {
//   bool debugClear = true,
// }) async {
//   final rewiseId = DBRewiseId(learn: 'en', speak: 'cs');
//   final storage = await RewiseStorage(
//     await Hive.openBox(rewiseId.partitionKey(email), path: r'd:\temp\hive'),
//     TableStorage(account: TableAccount(azureAccounts: AzureAccounts(), tableName: 'users')),
//     rewiseId,
//     email,
//   ).initialize(debugClear: true);
//   if (debugClear) await storage.debugClear();
//   await storage.azureTable?.running;
//   return storage;
// }

// void main() {
//   Hive.init('');
//   hiveRewiseStorageAdapters();
//   group('rewise_storage', () {
//     test('basic', () async {
//       final db = await createDB('email@10.en');
//     });
//   });
// }
