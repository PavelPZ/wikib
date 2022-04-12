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
  test('basic', () async {
    final container = ProviderContainer();
    container.read(stateProvider.notifier).state = 200;
    print('1. ${DateTime.now().millisecond}');
    await container.pump(); // NO SHIFT
    print('2. ${DateTime.now().millisecond}');
    container.read(futureProvider); // NO SHIFT
    print('3. ${DateTime.now().millisecond}');
    await container.read(futureProvider.future); // time SHIFT
    print('4. ${DateTime.now().millisecond}');
    container.read(stateProvider.notifier).state = 600;
    // print('5. ${DateTime.now().millisecond}');
    // await container.pump();
    print('6. ${DateTime.now().millisecond}');
    await container.read(futureProvider.future); // time SHIFT
    print('7. ${DateTime.now().millisecond}');
    await container.read(futureProvider.future);
    print('8. ${DateTime.now().millisecond}');
    return;
  });
}

final stateProvider = StateProvider<int>((_) => 0);
final futureProvider = FutureProvider((ref) => Future.delayed(Duration(milliseconds: ref.watch(stateProvider))));
