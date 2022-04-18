// ignore_for_file: unused_local_variable
@Timeout(Duration(seconds: 3600))

import 'package:test/test.dart';

void main() {
  group('utils', () {
    test('reduce', () async {
      final ints = <int>[2, 3, 4];
      final res = ints.reduce((value, element) {
        return value + element;
      });
      return;
    });
  });
}
