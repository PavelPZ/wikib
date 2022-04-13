import 'package:riverpod/riverpod.dart';
import 'package:test/test.dart';

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

int count = 1;
final stateProvider = StateProvider<int>((_) => 0);

final oldProvider = StateProvider<Storage?>((_) => null);

final futureProvider = FutureProvider<Storage>((ref) async {
  final old = ref.read(oldProvider.notifier);
  await Future.delayed(Duration(milliseconds: ref.watch(stateProvider)));
  final res = Storage(count++);
  print('Old: ${old.state?.value.toString()}');
  print('Create: ${res.value.toString()}');
  old.state = res;
  return res;
});

class Storage {
  Storage(this.value);
  final int value;
}
