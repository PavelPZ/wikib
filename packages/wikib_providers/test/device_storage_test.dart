// ignore_for_file: unused_local_variable
@Timeout(Duration(seconds: 3600))

import 'dart:async';

import 'package:hive/hive.dart';
import 'package:rewise_storage/rewise_storage.dart';
import 'package:riverpod/riverpod.dart';
import 'package:test/test.dart';
import 'package:wikib_providers/wikib_providers.dart';

Future<ProviderContainer> getCont() async {
  final res = ProviderContainer();
  await res.read(initWikibProviders.future);
  return res;
} //observers: [Logger()]);

Future<DeviceStorage> createDB(
  Future<ProviderContainer> cont, {
  bool debugClear = true,
  String? deviceId,
}) async {
  final res = await createDBLow(cont, debugClear: debugClear, deviceId: deviceId);
  return res!;
}

Future<DeviceStorage?> createDBLow(
  Future<ProviderContainer> fcont, {
  bool? debugClear = true,
  String? deviceId,
}) async {
  final cont = await fcont;
  cont.read(debugDeviceIdProvider.notifier).state = deviceId;
  if (debugClear != false) {
    await cont.read(debugDeviceStorageDeleteProvider)!();
  }
  if (debugClear == null) return null;

  final storage = (await cont.read(deviceStorageProvider.future))!;
  await storage.debugFlush();
  return storage;
}

void main() {
  Hive.init(r'd:\temp\hive');
  hiveRewiseStorageAdapters();
  test('more_devices', () async {
    const name = 'more_devices';
    final cont1 = getCont();
    final db1 = await createDB(cont1, deviceId: '$name');
  });
}
