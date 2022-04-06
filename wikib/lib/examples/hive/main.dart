import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:functional_widget_annotation/functional_widget_annotation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// flutter pub run build_runner watch --delete-conflicting-outputs
part 'main.g.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  final box = await Hive.openBox('test');
  runApp(ProviderScope(
    overrides: [
      hiveBoxProvider.overrideWithValue(box),
    ],
    child: const MyApp(),
  ));
}

@hcwidget
Widget myApp(BuildContext context, WidgetRef ref) {
  final createDBResult = useState('');
  final deleteDBResult = useState('');
  return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
          appBar: AppBar(
            title: Text('Home'),
          ),
          body: Center(
            child: Column(
              children: [
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => createDB(ref, (msg) => createDBResult.value = msg),
                  child: Text('Create DB'),
                ),
                SizedBox(height: 10),
                Text(createDBResult.value),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => deleteDB(ref, (msg) => deleteDBResult.value = msg),
                  child: Text('Delete DB'),
                ),
                SizedBox(height: 10),
                Text(deleteDBResult.value),
              ],
            ),
          )));
}

final hiveBoxProvider = Provider<Box>((_) => throw UnimplementedError());

Future createDB(WidgetRef ref, void done(String msg)) async {
  done('');
  final box = ref.read(hiveBoxProvider);
  final file = File(box.path!);
  await box.clear();
  assert(file.lengthSync() == 0);
  final rnd = Random();
  final bytes = Uint8List.fromList(List<int>.generate(400, (i) => rnd.nextInt(256)));
  final entries = Map<int, Uint8List>.fromEntries(List<MapEntry<int, Uint8List>>.generate(25000, (i) => MapEntry(i, bytes)));
  await box.putAll(entries);
  assert(file.existsSync());
  done('... db created, len=${file.lengthSync()}');
}

Future deleteDB(WidgetRef ref, void done(String msg)) async {
  done('');
  final box = ref.read(hiveBoxProvider);
  final file = File(box.path!);
  final keys = List<int>.generate(6000, (i) => i + 12000);
  await box.deleteAll(keys);
  await box.compact();
  done('... db created, len=${file.lengthSync()}');
}
