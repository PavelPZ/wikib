// ignore_for_file: unused_local_variable
@Timeout(Duration(seconds: 3600))

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
var withoutAzure = false;

Future<RewiseStorage> createDB(
  String email, {
  bool debugClear = true,
}) async {
  RewiseStorage storage;
  if (createDBWithProviders) {
    final cont = ProviderContainer();
    cont.read(emailProvider.notifier).state = email;
    cont.read(rewiseIdProvider.notifier).state = DBRewiseId(learn: 'en', speak: 'cs');
    cont.read(debugHivePath.notifier).state = r'd:\temp\hive';
    if (withoutAzure) cont.read(azureRewiseUsersTableProvider.notifier).state = null;
    storage = (await cont.read((debugClear ? rewiseProviderDebugClear : rewiseProvider).storage.future))!;
  } else {
    final rewiseId = DBRewiseId(learn: 'en', speak: 'cs');
    storage = RewiseStorage(
      await Hive.openBox(rewiseId.partitionKey(email), path: r'd:\temp\hive'),
      withoutAzure ? null : TableStorage(account: TableAccount(azureAccounts: AzureAccounts(), tableName: 'users')),
      rewiseId,
      email,
    );
    await storage.initialize(debugClear);
  }
  return storage;
}

void main() {
  Hive.init('');
  hiveRewiseStorageAdapters();
  dpIgnore = false; // DEBUG prints
  group('rewise_storage', () {
    test('basic', () async {
      print('=========== 0 ================');
      final db = await createDB('email@10.en');
      await db.flush();
      print('=========== 1 ================');
      final db2 = await createDB('email@10.en', debugClear: false);
      await db2.flush();
      print('=========== 2 ================');
      if (!withoutAzure) expect(db2.box.values.whereType<BoxItem>().where((it) => it.isDefered).toList().length, 0);
      return;
    });
    test('update', () async {
      final db = await createDB('email@11.en');
      db.facts.addItems([dom.Fact()..nextInterval = 1]);
    });
    test('facts', () async {
      for (var i = 0; i < 2; i++) {
        withoutAzure = i == 0;
        final db = await createDB('email@1.en');
        print(db.box.values);
        expect(db.box.length, 5);
        if (withoutAzure) db.debugFromAzureAllUploaded(db.toAzureUpload());

        db.facts.addItems([
          dom.Fact()..nextInterval = 1,
          dom.Fact()..nextInterval = 2,
          dom.Fact()..nextInterval = 3,
        ]);
        expect(db.facts.getMsgs().where((f) => f.isDefered).length, 3);
        expect(db.facts.getItems().where((f) => f.isDefered).length, 4);

        // =====================
        // await db.debugReopen();
        if (withoutAzure)
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

        db.facts.clear();
        expect(db.facts.getItems().length, 1);
        db.facts.clear(startItemsIncluded: true);
        expect(db.facts.getItems().length, 0);

        await db.flush();
        await db.close();
        continue;
      }
      return;
    });
    test('daylies', () async {
      for (var i = 1; i < 2; i++) {
        withoutAzure = i == 0;
        final db = await createDB('email@2.en');
        // save to azure
        if (withoutAzure)
          db.debugFromAzureAllUploaded(db.toAzureUpload());
        else
          await db.flush();

        // ==== addDaylies 2x
        db.daylies.addDaylies(Day.now, range(0, 5).map((e) => dom.Daily()));
        expect(db.daylies.getMsgs().length, 5);
        expect(db.debugDeletedAndDefered(), 'deleted=0, defered=6');
        final d1 = db.debugDump();
        if (withoutAzure)
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
        if (withoutAzure)
          db.debugFromAzureAllUploaded(db.toAzureUpload());
        else
          await db.flush();
        expect(db.debugDeletedAndDefered(), 'deleted=0, defered=0');

        // addDaylies 510x
        db.daylies.addDaylies(Day.now + 2, range(0, 510).map((e) => dom.Daily()));
        expect(db.daylies.getMsgs().length, 510);
        if (withoutAzure)
          db.debugFromAzureAllUploaded(db.toAzureUpload());
        else
          await db.flush();

        // addDaylies 10x, the same day
        db.daylies.addDaylies(Day.now + 2, range(0, 10).map((e) => dom.Daily()));
        expect(db.debugDeletedAndDefered(), 'deleted=0, defered=11');
        if (withoutAzure)
          db.debugFromAzureAllUploaded(db.toAzureUpload());
        else
          await db.flush();

        await db.flush();
        await db.close();
        continue;
      }
      return;
    });
    test('bootstrap', () async {
      final db = await createDB('email@3.en');
      db.debugFromAzureAllUploaded(db.toAzureUpload());
      expect(db.box.length, 5); // with aTag first row
      await db.close();

      final db2 = await createDB('email@3.en', debugClear: false);
      await db2.flush();
      expect(db2.box.length, 5); // with aTag first row
      await db2.close();
      return;
    });
  });
}
