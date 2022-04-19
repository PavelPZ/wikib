// ignore_for_file: unused_local_variable
@Timeout(Duration(seconds: 3600))

import 'dart:io';

import 'package:azure/azure.dart';
import 'package:azure_storage/azure_storage.dart';
import 'package:hive/hive.dart';
import 'package:protobuf_for_dart/algorithm.dart' as dom;
import 'package:rewise_storage/rewise_storage.dart';
import 'package:riverpod/riverpod.dart';
import 'package:test/test.dart';
import 'package:utils/utils.dart';
import 'package:wikib_providers/wikb_providers.dart';

const createDBWithProviders = true;

ProviderContainer getCont() => ProviderContainer(); //observers: [Logger()]);

Future<RewiseStorage> createDB(
  ProviderContainer cont,
  String? email, {
  bool debugClear = true,
  String? deviceId,
}) async {
  final res = await createDBLow(cont, email, debugClear: debugClear, deviceId: deviceId);
  return res!;
}

Future<RewiseStorage?> createDBLow(
  ProviderContainer cont,
  String? email, {
  bool? debugClear = true,
  String? deviceId,
}) async {
  RewiseStorage storage;
  if (createDBWithProviders) {
    cont.read(emailProvider.notifier).state = email;
    // print('*** emailOrEmptyProvider: ${cont.read(emailOrEmptyProvider)}');
    cont.read(rewiseIdProvider.notifier).state = DBRewiseId(learn: 'en', speak: 'cs');
    cont.read(debugHivePathProvider.notifier).state = r'd:\temp\hive';
    cont.read(debugDeviceIdProvider.notifier).state = deviceId;
    if (debugClear != false) {
      cont.read(debugDeleteProvider.notifier).state = true;
      try {
        await cont.read(rewiseProvider.storage.future);
      } finally {
        cont.read(debugDeleteProvider.notifier).state = false;
      }
    }
    if (debugClear == null) return null;
    storage = (await cont.read(rewiseProvider.storage.future))!;
    await storage.flush();
  } else {
    final rewiseId = DBRewiseId(learn: 'en', speak: 'cs');
    storage = RewiseStorage(
      await Hive.openBox(rewiseId.partitionKey(email ?? emptyEMail), path: r'd:\temp\hive'),
      email == null ? null : TableStorage(account: TableAccount(azureAccounts: AzureAccounts(), tableName: 'users')),
      rewiseId,
      email ?? emptyEMail,
    );
    await storage.initialize();
  }
  return storage;
}

void main() {
  Hive.init('');
  hiveRewiseStorageAdapters();
  dpIgnore = false; // DEBUG prints
  group('emptyEMail and devices', () {
    test('more devices', () async {
      final email = 'devices@m.c';

      final cont1 = getCont();
      await createDBLow(cont1, email, debugClear: null, deviceId: 'd1');
      final db1 = await createDB(cont1, email, debugClear: false, deviceId: 'd1');
      expect(db1.box.length, 5);
      db1.facts.addItems(range(0, 3).map((e) => dom.Fact()));
      await db1.flush();
      expect(db1.box.length, 8);

      final cont2 = getCont();
      final fn = File(db1.box.path!.replaceFirst('\\d1-', '\\d2-'));
      if (fn.existsSync()) fn.deleteSync();
      final db2 = await createDB(cont2, email, debugClear: false, deviceId: 'd2');
      expect(db2.box.length, 8);
      db2.facts.addItems(range(0, 3).map((e) => dom.Fact()));
      expect(db2.box.length, 11);
      await db2.flush();

      db1.facts.addItems(range(0, 3).map((e) => dom.Fact()));
      await db1.flush();
      expect(db1.box.length, 11);

      db1.facts.addItems(range(0, 3).map((e) => dom.Fact()));
      expect(db1.box.length, 14);
      await Future.delayed(Duration(milliseconds: 100));
      expect(db1.box.length, 14);
      db1.facts.addItems(range(0, 3).map((e) => dom.Fact()));
      expect(db1.box.length, 17);
      // await db1.flush();
      expect(db1.box.length, 17);

      return;
    }, skip: false);
    test('emptyEMail', () async {
      final cont = getCont();
      // clear
      await createDBLow(cont, 'fromEmpty@m.c', debugClear: null);

      // create new
      final db = await createDB(cont, null, debugClear: false);
      print('*** test: await createDB');
      db.facts.addItems(range(0, 3).map((e) => dom.Fact()..nextInterval = e));
      print('*** test: before db.flush: ${cont.read(emailProvider)}');
      await db.flush();
      print('*** test: db.flush: ${cont.read(emailProvider)}');
      // await db.close();
      assert(cont.read(emailProvider) == null);
      cont.read(emailProvider.notifier).state = 'fromEmpty@m.c';
      final db2 = await cont.read(rewiseProvider.storage.future);
      final facts = db2!.facts.getMsgs().map((m) => m.msg).toList();
      return;
    });
  });
  group('rewise_storage', () {
    test('save stress', () async {
      final cont = getCont();
      final db = await createDB(cont, 'save stress');

      for (var i = 0; i < 6; i++) {
        db.facts.addItems([dom.Fact()..nextInterval = i]);
        expect(db.box.length, 6 + i);
        await Future.delayed(Duration(milliseconds: i * 250));
      }
      await db.flush();

      await db.wholeAzureDownload();
      expect(db.box.length, 11);
    });
    test('basic', () async {
      for (var i = 0; i < 2; i++) {
        final cont = getCont();
        final email = i == 0 ? null : 'email@10.en';
        final db = await createDB(cont, email);
        print('=========== 0 ================');
        await db.flush();
        print('=========== 1 ================');
        // CHANGE eTagRow here => test eTagConflict
        final db2 = await createDB(cont, email, debugClear: false);
        await db2.flush();
        print('=========== 2 ================');
        final db3 = await createDB(cont, email, debugClear: false);
        await db3.flush();
        print('=========== 3 ================');
        print(db3.debugDump());
        expect(db3.box.values.whereType<BoxItem>().where((it) => it.isDefered).toList().length, db3.azureTable == null ? 4 : 0);
      }
      return;
    });
    test('whole database download', () async {
      final cont = getCont();
      final db = await createDB(cont, 'email@11.en');
      db.facts.addItems(range(0, 300).map((e) => dom.Fact()..nextInterval = e));
      await db.flush();
      await db.wholeAzureDownload();
      await db.flush();
      return;
    });
    test('update', () async {
      for (var i = 0; i < 2; i++) {
        final cont = getCont();
        final email = i == 0 ? null : 'email@12.en';
        final db = await createDB(cont, email);
        await db.flush();
        db.facts.addItems([dom.Fact()..nextInterval = 1]);
        await db.flush();
      }
      return;
    });
    test('delete', () async {
      for (var i = 0; i < 2; i++) {
        final cont = getCont();
        final email = i == 0 ? null : 'email@13.en';
        final db = await createDB(cont, email);
        db.facts.addItems([dom.Fact()..nextInterval = 1]);
        await db.flush();
        db.facts.clear(); // remove all facts
        await db.flush();
      }
      return;
    });
    test('facts', () async {
      for (var i = 0; i < 2; i++) {
        final cont = getCont();
        final email = i == 0 ? null : 'email@1.en';
        final db = await createDB(cont, email);
        print(db.box.values);
        expect(db.box.length, 5);
        if (db.azureTable == null) db.debugFromAzureAllUploaded(db.toAzureUpload());

        db.facts.addItems([
          dom.Fact()..nextInterval = 1,
          dom.Fact()..nextInterval = 2,
          dom.Fact()..nextInterval = 3,
        ]);
        expect(db.facts.getMsgs().where((f) => f.isDefered).length, 3);
        expect(db.facts.getItems().where((f) => f.isDefered).length, 4);

        // =====================
        // await db.debugReopen();
        if (db.azureTable == null)
          db.debugFromAzureAllUploaded(db.toAzureUpload());
        else
          await db.flush();

        expect(db.facts.getItems().where((f) => f.isDefered).length, 0);

        final upload2 = db.toAzureUpload(allowSingleRow: false);
        expect(upload2 == null, true);

        // =====================
        await db.debugReopen();

        db.facts.itemsPlace.updateMsg((fact) => fact.nextInterval = 4, key: db.facts.getMsgs().first.key + 1);
        expect(db.facts.getMsgs().map((f) => f.msg!.nextInterval).join(','), '1,4,3');

        db.facts.itemsPlace.updateMsg((fact) => fact.nextInterval = 5, key: db.facts.getMsgs().first.key);
        expect(db.facts.getMsgs().map((f) => f.msg!.nextInterval).join(','), '5,4,3');

        final f3 = db.facts.itemsPlace.getValueOrMsg(db.facts.getMsgs().first.key + 2);
        f3.nextInterval = 6;
        db.facts.itemsPlace.saveValue(f3, key: f3.id);
        expect(db.facts.getMsgs().map((f) => f.msg!.nextInterval).join(','), '5,4,6');
        await db.flush();

        print(db.debugDump());

        db.facts.clear();
        //expect(db.facts.getItems().length, 1);
        //db.facts.clear(startItemsIncluded: true);
        //expect(db.facts.getItems().length, 0);

        await db.flush();
        await db.close();
        continue;
      }
      return;
    });
    test('daylies', () async {
      for (var i = 0; i < 2; i++) {
        final cont = getCont();
        final email = i == 0 ? null : 'email@2.en';
        final db = await createDB(cont, email);
        // save to azure
        if (db.azureTable == null)
          db.debugFromAzureAllUploaded(db.toAzureUpload());
        else
          await db.flush();

        // ==== addDaylies 2x
        db.daylies.addDaylies(Day.now, range(0, 5).map((e) => dom.Daily()));
        expect(db.daylies.getMsgs().length, 5);
        expect(db.debugDeletedAndDefered(), 'deleted=0, defered=6');
        final d1 = db.debugDump();
        if (db.azureTable == null)
          db.debugFromAzureAllUploaded(db.toAzureUpload());
        else
          await db.flush();
        await db.debugReopen();
        final d11 = db.debugDump();
        expect(db.box.values.whereType<BoxItem>().where((f) => f.isDefered).length, 0);

        // ==== change day
        db.daylies.addDaylies(Day.now + 1, range(0, 2).map((e) => dom.Daily()));
        expect(db.daylies.getMsgs().length, 2);
        expect(db.debugDeletedAndDefered(), 'deleted=3, defered=7');
        if (db.azureTable == null)
          db.debugFromAzureAllUploaded(db.toAzureUpload());
        else
          await db.flush();
        expect(db.debugDeletedAndDefered(), 'deleted=0, defered=0');

        // addDaylies 510x
        db.daylies.addDaylies(Day.now + 2, range(0, 510).map((e) => dom.Daily()));
        expect(db.daylies.getMsgs().length, 510);
        if (db.azureTable == null)
          db.debugFromAzureAllUploaded(db.toAzureUpload());
        else
          await db.flush();

        // addDaylies 10x, the same day
        db.daylies.addDaylies(Day.now + 2, range(0, 10).map((e) => dom.Daily()));
        expect(db.debugDeletedAndDefered(), 'deleted=0, defered=11');
        if (db.azureTable == null)
          db.debugFromAzureAllUploaded(db.toAzureUpload());
        else
          await db.flush();

        db.daylies.addDaylies(Day.now + 3, range(0, 10).map((e) => dom.Daily()));
        expect(db.debugDeletedAndDefered(), 'deleted=510, defered=522');
        if (db.azureTable == null)
          db.debugFromAzureAllUploaded(db.toAzureUpload());
        else
          await db.flush();

        await db.flush();
        continue;
      }
      return;
    });
    test('bootstrap', () async {
      for (var i = 0; i < 2; i++) {
        final cont = getCont();
        final email = i == 0 ? null : 'email@3.en';
        final db = await createDB(cont, email);
        expect(db.box.length, 5); // with aTag first row
        await db.flush();

        final db2 = await createDB(cont, email, debugClear: false);
        expect(db2.box.length, 5); // with aTag first row
        await db2.flush();
      }
      return;
    });
  });
}

class Logger extends ProviderObserver {
  @override
  void didUpdateProvider(ProviderBase provider, Object? previousValue, Object? newValue, ProviderContainer container) =>
      print('UPDATE ${provider.name ?? provider.runtimeType} = $newValue');

  @override
  void didAddProvider(
    ProviderBase provider,
    Object? value,
    ProviderContainer container,
  ) =>
      print('ADD ${provider.name ?? provider.runtimeType} = $value');

  @override
  void didDisposeProvider(
    ProviderBase provider,
    ProviderContainer container,
  ) =>
      print('DISPOSE ${provider.name ?? provider.runtimeType}');
}
