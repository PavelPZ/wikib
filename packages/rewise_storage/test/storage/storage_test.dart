// ignore_for_file: unused_local_variable

import 'package:azure_storage/azure_storage.dart';
import 'package:hive/hive.dart';
import 'package:protobuf_for_dart/algorithm.dart' as dom;
import 'package:rewise_storage/rewise_storage.dart';
import 'package:riverpod/riverpod.dart';
import 'package:test/test.dart';
import 'package:utils/utils.dart';

Future<ProviderContainer> createContainer(
  String name, {
  bool isLogged = false,
  bool debugClear = true,
}) async {
  final storage = RewiseStorage(await Hive.openBox(name, path: r'd:\temp\hive'));
  if (debugClear) await storage.box.clear();
  storage.seed(name);
  final res = ProviderContainer(overrides: debugRewiseStorageOverrides(storage));
  addTearDown(res.dispose);
  return res;
}

void main() {
  Hive.init('');
  hiveRewiseStorageAdapters();
  group('rewise_storage', () {
    test('basic', () async {
      final container = await createContainer('user1');
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
      final dblen1 = db.box.length;

      // =====================
      await db.debugReopen();

      db.fromAzureUpload(azureUpload!.versions);
      expect(db.box.length, dblen1);

      final upload2 = db.toAzureUpload();
      expect(upload2!.rows.length, 1);
      final facts2 = db.facts.getMsgs().toList();
      expect(facts2.where((f) => f.isDefered).length, 0);

      // =====================
      await db.debugReopen();

      db.facts.itemsPlace.updateMsg(2050, (fact) => fact.nextInterval = 4);
      expect(db.facts.getMsgs().map((f) => f.msg!.nextInterval).join(','), '1,4,3');

      db.facts.itemsPlace.updateMsg(null, (fact) => fact.nextInterval = 5);
      expect(db.facts.getMsgs().map((f) => f.msg!.nextInterval).join(','), '5,4,3');

      final f3 = db.facts.itemsPlace.getValueOrMsg(2051);
      f3.nextInterval = 6;
      db.facts.itemsPlace.saveValue(f3, f3.id);
      expect(db.facts.getMsgs().map((f) => f.msg!.nextInterval).join(','), '5,4,6');

      db.facts.clear();
      expect(db.facts.getItems().length, 1);
      db.facts.clear(true);
      expect(db.facts.getItems().length, 0);

      return;
    });
    test('daylies', () async {
      const partitionKey = 'pk2';
      final container = await createContainer('user2');
      final db = container.read(rewiseStorageProvider);

      // after initialization
      await db.debugReopen();
      final its01 = db.box.values.cast<BoxItem>().toList();
      final keys01 = its01.map((d) => d.key).join(',');
      expect(its01.length, 6);
      final def01 = db.box.values.cast<BoxItem>().where((f) => f.isDefered).toList();
      expect(def01.length, 6);

      // save to azure
      db.fromAzureUpload(db.toAzureUpload()!.versions);
      // after save to azure
      await db.debugReopen();
      final values = db.box.values.toList();
      final its0 = db.box.values.cast<BoxItem>().toList();
      final keys0 = its0.map((d) => d.key).join(',');
      expect(its0.length, 6);
      final def0 = db.box.values.cast<BoxItem>().where((f) => f.isDefered).toList();
      expect(def0.length, 0);

      // addDaylies
      db.daylies.addDaylies(Day.now, range(0, 2).map((e) => dom.Daily()));
      await db.debugReopen();
      final def1 = db.box.values.cast<BoxItem>().where((f) => f.isDefered).toList();
      final d1 = db.debugDump();
      expect(def1.length, 4);

      db.fromAzureUpload(db.toAzureUpload()!.versions);
      final d11 = db.debugDump();
      await db.debugReopen();
      expect(db.box.values.cast<BoxItem>().where((f) => f.isDefered).length, 0);

      db.daylies.addDaylies(Day.now + 1, range(0, 510).map((e) => dom.Daily()));
      await db.debugReopen();
      final def2 = db.box.values.cast<BoxItem>().where((f) => f.isDefered).toList();
      final d2 = db.debugDump(); // 512 new & defered
      expect(db.debugDeletedAndDefered(), 'deleted=0, defered=512');
      expect(def2.length, 512);

      final toAzure = db.toAzureUpload();
      db.daylies.addDaylies(Day.now + 1, range(0, 10).map((e) => dom.Daily()));
      expect(db.debugDeletedAndDefered(), 'deleted=500, defered=512');
      db.fromAzureUpload(toAzure!.versions);
      expect(db.debugDeletedAndDefered(), 'deleted=500, defered=512'); // no statistics change, only 12 items are modified
      final d5 = db.debugDump();

      // save to azure
      final toAzure2 = db.toAzureUpload(); // 1 row is "put", 2 rows are "delete"
      db.fromAzureUpload(toAzure2!.versions);
      expect(db.debugDeletedAndDefered(), 'deleted=0, defered=0');

      return;
    });
    test('bootstrap', () async {
      final container = await createContainer('user3');
      final db = container.read(rewiseStorageProvider);
      container.dispose();
      await db.debugReopen();

      final container2 = await createContainer('user3', debugClear: false);
      final db2 = container2.read(rewiseStorageProvider);
      return;
    });
  });
}
