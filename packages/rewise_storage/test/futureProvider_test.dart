import 'package:riverpod/riverpod.dart';
import 'package:test/test.dart';

class RewiseStart {
  RewiseStart(this.email, this.speak, this.learn);
  final String email;
  final String learn;
  final String speak;
  String get primaryKey => '';
}

class Storage {
  Storage(this.primaryKey);
  final String primaryKey;
  Future init() => Future.delayed(Duration(milliseconds: 500));
  Future dispose() => Future.delayed(Duration(milliseconds: 500));
}

final rewiseStartProvider = StateProvider<RewiseStart?>((ref) {
  return RewiseStart('', '', '');
});

final storageProvider = FutureProvider<Storage?>((ref) async {
  final rs = ref.watch(rewiseStartProvider);
  if (rs == null) return null;
  final res = Storage(rs.primaryKey);
  await res.init();
  return res;
});

void main() {
  test('basic', () async {});
}
