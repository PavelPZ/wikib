@Timeout(Duration(seconds: 3600))

import 'dart:convert';

import 'package:azure/azure.dart';
import 'package:rewise_storage/rewise_storage.dart';
import 'package:test/test.dart';

import 'lib.dart';

void main() {
  group('storage', () {
    test('', () async {
      await initStorage('t1');
    });
  });
}
