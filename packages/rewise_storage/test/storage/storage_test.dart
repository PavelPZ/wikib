// ignore_for_file: unused_local_variable

import 'package:azure/azure.dart';
import 'package:hive/hive.dart';
import 'package:protobuf_for_dart/algorithm.dart' as dom;
import 'package:rewise_storage/rewise_storage.dart';
import 'package:riverpod/riverpod.dart';
import 'package:test/test.dart';
import 'package:utils/utils.dart';

Future<ProviderContainer> createContainer(String dbName) async {
  final storage = RewiseStorage(await Hive.openBox(dbName, path: r'd:\temp\hive'));
  await storage.box.clear();
  await storage.seed();
  final res = ProviderContainer(overrides: rewiseStorageOverrides(storage));
  addTearDown(res.dispose);
  return res;
}

void main() {
  Hive.init('');
  initRewiseStorage();
  group('rewise_storage', () {
    test('basic', () async {
      final container = await createContainer('t1');
      final db = container.read(rewiseStorageProvider);
      await db.facts.addItems([
        dom.Fact()..nextInterval = 1,
        dom.Fact()..nextInterval = 2,
        dom.Fact()..nextInterval = 3,
      ]);

      // =====================
      await db.debugReopen();

      final facts = db.facts.getMsgs().toList();
      expect(facts.map((f) => f.msg!.nextInterval).join(','), '1,2,3');
      expect(facts.map((f) => f.msg!.id).join(','), '2049,2050,2051');
      expect(facts.where((f) => f.isDefered).length, 3);

      final azureUpload = db.toAzureUpload();

      // =====================
      await db.debugReopen();

      await db.fromAzureUpload(azureUpload!.versions);

      final upload2 = db.toAzureUpload();
      expect(upload2, null);
      final facts2 = db.facts.getMsgs().toList();
      expect(facts2.where((f) => f.isDefered).length, 0);

      // =====================
      await db.debugReopen();

      await db.facts.itemsPlace.updateMsg(2050, (fact) => fact.nextInterval = 4);
      expect(db.facts.getMsgs().map((f) => f.msg!.nextInterval).join(','), '1,4,3');

      await db.facts.itemsPlace.updateMsg(null, (fact) => fact.nextInterval = 5);
      expect(db.facts.getMsgs().map((f) => f.msg!.nextInterval).join(','), '5,4,3');

      final f3 = db.facts.itemsPlace.getValueOrMsg(2051);
      f3.nextInterval = 6;
      db.facts.itemsPlace.saveValue(f3, f3.id);
      expect(db.facts.getMsgs().map((f) => f.msg!.nextInterval).join(','), '5,4,6');

      await db.facts.clear();
      expect(db.facts.getItems().length, 1);
      await db.facts.clear(true);
      expect(db.facts.getItems().length, 0);

      return;
    });
    test('daylies', () async {
      final container = await createContainer('t2');
      final db = container.read(rewiseStorageProvider);

      // after initialization
      await db.debugReopen();
      final its01 = db.box.values.cast<BoxItem>().toList();
      final keys01 = its01.map((d) => d.key).join(',');
      expect(its01.length, 4);
      final def01 = db.box.values.cast<BoxItem>().where((f) => f.isDefered).toList();
      expect(def01.length, 4);

      // save to azure
      await db.fromAzureUpload(db.toAzureUpload()!.versions);
      // after save to azure
      await db.debugReopen();
      final values = db.box.values.toList();
      final its0 = db.box.values.cast<BoxItem>().toList();
      final keys0 = its0.map((d) => d.key).join(',');
      expect(its0.length, 4);
      final def0 = db.box.values.cast<BoxItem>().where((f) => f.isDefered).toList();
      expect(def0.length, 0);

      // addDaylies
      await db.daylies.addDaylies(Day.now, range(0, 2).map((e) => dom.Daily()));
      await db.debugReopen();
      final def1 = db.box.values.cast<BoxItem>().where((f) => f.isDefered).toList();
      final d1 = db.debugDump();
      expect(def1.length, 4);

      await db.fromAzureUpload(db.toAzureUpload()!.versions);
      final d11 = db.debugDump();
      await db.debugReopen();
      expect(db.box.values.cast<BoxItem>().where((f) => f.isDefered).length, 0);

      await db.daylies.addDaylies(Day.now + 1, range(0, 510).map((e) => dom.Daily()));
      await db.debugReopen();
      final def2 = db.box.values.cast<BoxItem>().where((f) => f.isDefered).toList();
      final d2 = db.debugDump(); // 512 new & defered
      expect(db.debugDeletedAndDefered(), 'deleted=0, defered=512');
      expect(def2.length, 512);

      final toAzure = db.toAzureUpload();
      await db.daylies.addDaylies(Day.now + 1, range(0, 10).map((e) => dom.Daily()));
      expect(db.debugDeletedAndDefered(), 'deleted=500, defered=512');
      await db.fromAzureUpload(toAzure!.versions);
      final d5 = db.debugDump();

      // save to azure
      final toAzure2 = db.toAzureUpload();
      await db.fromAzureUpload(toAzure2!.versions);
      final d6 = db.debugDump();

      final def3 = db.box.values.cast<BoxItem>().where((f) => f.isDefered).toList();
      expect(def3.length, 0);

      return;
    });
  });
  group('test', () {
    test('t3', () async {
      final container = await createContainer('t3');
    });
  });
}
