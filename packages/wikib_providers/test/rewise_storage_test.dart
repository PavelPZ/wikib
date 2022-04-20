// ignore_for_file: unused_local_variable
@Timeout(Duration(seconds: 3600))

import 'dart:async';
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
    // cont.read(debugHivePathProvider.notifier).state = r'd:\temp\hive';
    cont.read(debugDeviceIdProvider.notifier).state = deviceId;
    if (debugClear != false) {
      cont.read(debugDeleteProvider.notifier).state = true;
      try {
        await cont.read(rewiseProvider.storageProvider.future);
      } finally {
        cont.read(debugDeleteProvider.notifier).state = false;
      }
    }
    if (debugClear == null) return null;
    storage = (await cont.read(rewiseProvider.storageProvider.future))!;
    await storage.debugFlush();
  } else {
    final rewiseId = DBRewiseId(learn: 'en', speak: 'cs');
    storage = RewiseStorage(
      await Hive.openBox(rewiseId.partitionKey(email ?? emptyEMail), path: r'd:\temp\hive'),
      email == null ? null : TableAccount(azureAccounts: AzureAccounts(), tableName: 'users'),
      rewiseId,
      email ?? emptyEMail,
    );
    await storage.initialize();
  }
  return storage;
}

void main() {
  Hive.init(r'd:\temp\hive');
  hiveRewiseStorageAdapters();
  group('emptyEMail and devices', () {
    test('more_devices', () async {
      const name = 'more_devices';

      final cont1 = getCont();
      await createDBLow(cont1, name, debugClear: null, deviceId: '$name-1-');
      final db1 = await createDB(cont1, name, debugClear: false, deviceId: '$name-1-');
      expect(db1.box.length, 5);
      db1.facts.addItems(range(0, 3).map((e) => dom.Fact()));
      await db1.debugFlush();
      expect(db1.box.length, 8);

      final cont2 = getCont();
      final fn = File(db1.box.path!.replaceFirst('-1-', '-2-'));
      if (fn.existsSync()) fn.deleteSync();
      final db2 = await createDB(cont2, name, debugClear: false, deviceId: '$name-2-');
      expect(db2.box.length, 8);
      db2.facts.addItems(range(0, 3).map((e) => dom.Fact()));
      expect(db2.box.length, 11);
      await db2.debugFlush();

      db1.facts.addItems(range(0, 3).map((e) => dom.Fact()));
      await db1.debugFlush();
      expect(db1.box.length, 11);

      db1.facts.addItems(range(0, 3).map((e) => dom.Fact()));
      expect(db1.box.length, 14);
      await Future.delayed(Duration(milliseconds: 100));
      expect(db1.box.length, 14);
      db1.facts.addItems(range(0, 3).map((e) => dom.Fact()));
      expect(db1.box.length, 17);
      // await db1.flush();
      expect(db1.box.length, 17);

      await db1.close();
      return;
    }, skip: true);
    test('testEmptyEMail', () async {
      final cont = getCont();
      const name = 'testEmptyEMail';
      // clear
      await createDBLow(cont, emptyEMail, debugClear: null, deviceId: name);
      await createDBLow(cont, name, debugClear: null, deviceId: name);

      // create new
      final db = await createDB(cont, null, debugClear: false, deviceId: name);
      print('*** test: await createDB');
      db.facts.addItems(range(0, 3).map((e) => dom.Fact()..nextInterval = e));
      print('*** test: before db.flush: ${cont.read(emailProvider)}');
      await db.debugFlush();

      print('*** test: db.flush: ${cont.read(emailProvider)}');
      // await db.close();
      assert(cont.read(emailProvider) == null);
      cont.read(emailProvider.notifier).state = name;
      final db2 = await cont.read(rewiseProvider.storageProvider.future);
      final facts = db2!.facts.getMsgs().map((m) => m.msg).toList();
      await db2.debugFlush();
      return;
    }, skip: true);
  });
  group('rewise_storage', () {
    test('save_stress', () async {
      const name = 'save_stress';
      final cont = getCont();
      final db = await createDB(cont, name, deviceId: name);

      for (var i = 0; i < 6; i++) {
        db.facts.addItems([dom.Fact()..nextInterval = i]);
        expect(db.box.length, 6 + i);
        await Future.delayed(Duration(milliseconds: i * 250));
      }
      await db.debugFlush();

      await db.wholeAzureDownload();
      expect(db.box.length, 11);
    }, skip: false);
    test('basic', () async {
      const name = 'basic';
      for (var i = 0; i < 2; i++) {
        final cont = getCont();
        final email = i == 0 ? null : name;
        final db = await createDB(cont, email, deviceId: name);
        print('=========== 0 ================');
        await db.debugFlush();
        print('=========== 1 ================');
        // CHANGE eTagRow here => test eTagConflict
        final db2 = await createDB(cont, email, debugClear: false, deviceId: name);
        await db2.debugFlush();
        print('=========== 2 ================');
        final db3 = await createDB(cont, email, debugClear: false, deviceId: name);
        await db3.debugFlush();
        print('=========== 3 ================');
        print(db3.debugDump());
        expect(db3.box.values.whereType<BoxItem>().where((it) => it.isDefered).toList().length, db3.saveToCloudTable == null ? 4 : 0);
      }
      return;
    }, skip: false);
    test('whole_database_download', () async {
      const name = 'whole_database_download';
      final cont = getCont();
      final db = await createDB(cont, name, deviceId: name);
      db.facts.addItems(range(0, 300).map((e) => dom.Fact()..nextInterval = e));
      await db.debugFlush();
      await db.wholeAzureDownload();
      await db.debugFlush();
      return;
    }, skip: false);
    test('update', () async {
      const name = 'update';
      for (var i = 0; i < 2; i++) {
        final cont = getCont();
        final db = await createDB(cont, i == 0 ? null : name, deviceId: name);
        await db.debugFlush();
        db.facts.addItems([dom.Fact()..nextInterval = 1]);
        await db.debugFlush();
      }
      return;
    }, skip: false);
    test('delete', () async {
      const name = 'delete';
      for (var i = 0; i < 2; i++) {
        final cont = getCont();
        final db = await createDB(cont, i == 0 ? null : name, deviceId: name);
        db.facts.addItems([dom.Fact()..nextInterval = 1]);
        await db.debugFlush();
        db.facts.clear(); // remove all facts
        await db.debugFlush();
      }
      return;
    }, skip: false);
    test('facts', () async {
      const name = 'facts';
      for (var i = 0; i < 2; i++) {
        final cont = getCont();
        final email = i == 0 ? null : name;
        final db = await createDB(cont, email, deviceId: name);
        print(db.box.values);
        expect(db.box.length, 5);
        if (db.saveToCloudTable == null) unawaited(db.debugFromAzureAllUploaded(db.toAzureUpload()));

        db.facts.addItems([
          dom.Fact()..nextInterval = 1,
          dom.Fact()..nextInterval = 2,
          dom.Fact()..nextInterval = 3,
        ]);
        expect(db.facts.getMsgs().where((f) => f.isDefered).length, 3);
        expect(db.facts.getItems().where((f) => f.isDefered).length, 4);

        // =====================
        // await db.debugReopen();
        if (db.saveToCloudTable == null)
          unawaited(db.debugFromAzureAllUploaded(db.toAzureUpload()));
        else
          await db.debugFlush();

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
        await db.debugFlush();

        print(db.debugDump());

        db.facts.clear();
        //expect(db.facts.getItems().length, 1);
        //db.facts.clear(startItemsIncluded: true);
        //expect(db.facts.getItems().length, 0);

        await db.debugFlush();
        await db.close();
        continue;
      }
      return;
    }, skip: false);
    test('daylies', () async {
      const name = 'daylies';
      for (var i = 0; i < 2; i++) {
        final cont = getCont();
        final email = i == 0 ? null : name;
        final db = await createDB(cont, email, deviceId: name);
        // save to azure
        if (db.saveToCloudTable == null)
          unawaited(db.debugFromAzureAllUploaded(db.toAzureUpload()));
        else
          await db.debugFlush();

        // ==== addDaylies 2x
        db.daylies.addDaylies(Day.now, range(0, 5).map((e) => dom.Daily()));
        expect(db.daylies.getMsgs().length, 5);
        expect(db.debugDeletedAndDefered(), 'deleted=0, defered=6');
        final d1 = db.debugDump();
        if (db.saveToCloudTable == null)
          unawaited(db.debugFromAzureAllUploaded(db.toAzureUpload()));
        else
          await db.debugFlush();
        await db.debugReopen();
        final d11 = db.debugDump();
        expect(db.box.values.whereType<BoxItem>().where((f) => f.isDefered).length, 0);

        // ==== change day
        db.daylies.addDaylies(Day.now + 1, range(0, 2).map((e) => dom.Daily()));
        expect(db.daylies.getMsgs().length, 2);
        expect(db.debugDeletedAndDefered(), 'deleted=3, defered=7');
        if (db.saveToCloudTable == null)
          unawaited(db.debugFromAzureAllUploaded(db.toAzureUpload()));
        else
          await db.debugFlush();
        expect(db.debugDeletedAndDefered(), 'deleted=0, defered=0');

        // addDaylies 510x
        db.daylies.addDaylies(Day.now + 2, range(0, 510).map((e) => dom.Daily()));
        expect(db.daylies.getMsgs().length, 510);
        if (db.saveToCloudTable == null)
          unawaited(db.debugFromAzureAllUploaded(db.toAzureUpload()));
        else
          await db.debugFlush();

        // addDaylies 10x, the same day
        db.daylies.addDaylies(Day.now + 2, range(0, 10).map((e) => dom.Daily()));
        expect(db.debugDeletedAndDefered(), 'deleted=0, defered=11');
        if (db.saveToCloudTable == null)
          unawaited(db.debugFromAzureAllUploaded(db.toAzureUpload()));
        else
          await db.debugFlush();

        db.daylies.addDaylies(Day.now + 3, range(0, 10).map((e) => dom.Daily()));
        expect(db.debugDeletedAndDefered(), 'deleted=510, defered=522');
        if (db.saveToCloudTable == null)
          unawaited(db.debugFromAzureAllUploaded(db.toAzureUpload()));
        else
          await db.debugFlush();

        await db.debugFlush();
        continue;
      }
      return;
    }, skip: false);
    test('bootstrap', () async {
      const name = 'bootstrap';
      for (var i = 0; i < 1; i++) {
        final cont = getCont();
        final email = i == 0 ? null : name;
        final db = await createDB(cont, email, deviceId: name);
        expect(db.box.length, 5); // with aTag first row
        await db.debugFlush();
        await db.close();

        final db2 = await createDB(cont, email, debugClear: false, deviceId: name);
        expect(db2.box.length, 5); // with aTag first row
        await db2.debugFlush();
        await db2.close();
      }
      return;
    }, skip: false);
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
