part of 'wikib_providers.dart';

// Future debugInitAppWithRef(ProviderContainer ref) => initAppLow(ref.read, ref.listen);
// Future initAppWithRef(Ref ref) => initAppLow(ref.read, ref.listen);

// Future initAppLow(
//   T Function<T>(ProviderBase<T> provider) read,
//   void Function<T>(AlwaysAliveProviderListenable<T> provider, void Function(T? previous, T next) listener) listen,
// ) =>
// _initAppFuture == null ? (_initAppFuture = _initAppLow(read, listen)) : _initAppFuture!;

Future<bool> _initWikib(Ref ref) => _initAppFuture == null ? (_initAppFuture = __initWikib(ref)) : _initAppFuture!;

Future<bool> __initWikib(Ref ref) async {
  final deviceStorage = await ref.read(deviceStorageProvider.future) as DeviceStorage;
  ref.read(authProfileProvider.notifier).state = deviceStorage.authProfile.exists() ? deviceStorage.authProfile.getValueOrMsg() : null;
  ref.listen<AuthProfile?>(authProfileProvider, (_, next) {
    if (next == null)
      deviceStorage.authProfile.delete();
    else
      deviceStorage.authProfile.saveValue(next);
  });
  return true;
}

final initWikibProviders = FutureProvider<bool>(_initWikib);

// Future _initAppLow(
//   T Function<T>(ProviderBase<T> provider) read,
//   void Function<T>(AlwaysAliveProviderListenable<T> provider, void Function(T? previous, T next) listener) listen,
// ) async {
//   final deviceStorage = await read(deviceStorageProvider.future) as DeviceStorage;
//   read(authProfileProvider.notifier).state = deviceStorage.authProfile.exists() ? deviceStorage.authProfile.getValueOrMsg() : null;
//   listen<StateController<AuthProfile?>>(authProfileProvider.notifier, (_, next) {
//     if (next.state == null)
//       deviceStorage.authProfile.delete();
//     else
//       deviceStorage.authProfile.setValueOrMsg(next.state!);
//   });
// }

Future<bool>? _initAppFuture;
