import 'package:azure/azure.dart';
import 'package:hive/hive.dart';
import 'package:protobuf_for_dart/algorithm.dart' as dom;
import 'package:rewise_storage/rewise_storage.dart';
import 'package:riverpod/riverpod.dart';
import 'package:test/test.dart';

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
  group('basic', () {
    test('t1', () async {
      final container = await createContainer('t1');
      final db = container.read(rewiseStorageProvider);
      await db.facts.addNewGroupItems([
        dom.Fact()..nextInterval = 1,
        dom.Fact()..nextInterval = 2,
        dom.Fact()..nextInterval = 3,
      ]);

      // =====================
      await db.debugReopen();

      final facts = db.facts.getItems().toList();
      expect(facts.map((f) => f.msg!.nextInterval).join(','), '1,2,3');
      expect(facts.map((f) => f.msg!.id).join(','), '2049,2050,2051');
      expect(facts.where((f) => f.isDefered).length, 3);

      final azureUpload = db.toAzureUpload();

      // =====================
      await db.debugReopen();

      await db.fromAzureUpload(azureUpload!.versions);

      final upload2 = db.toAzureUpload();
      expect(upload2, null);
      final facts2 = db.facts.getItems().toList();
      expect(facts2.where((f) => f.isDefered).length, 0);

      // =====================
      await db.debugReopen();

      await db.facts.itemsPlace.updateValue(BoxKey(2050), (fact) => fact.nextInterval = 4);
      expect(db.facts.getItems().map((f) => f.msg!.nextInterval).join(','), '1,4,3');

      await db.facts.itemsPlace.updateValue(null, (fact) => fact.nextInterval = 5);
      expect(db.facts.getItems().map((f) => f.msg!.nextInterval).join(','), '5,4,3');

      final f3 = db.facts.itemsPlace.getValue(BoxKey(2051));
      f3!.nextInterval = 6;
      db.facts.itemsPlace.saveValue(f3, BoxKey(f3.id));
      expect(db.facts.getItems().map((f) => f.msg!.nextInterval).join(','), '5,4,6');

      return;
    });
    test('t2', () async {
      final container = await createContainer('t2');
      final db = container.read(rewiseStorageProvider);

      return;
    });
  });
  group('test', () {
    test('t3', () async {
      final container = await createContainer('t3');
    });
  });
}
