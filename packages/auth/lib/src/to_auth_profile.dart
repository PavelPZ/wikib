part of 'auth.dart';

AuthProfile? convert2AuthoProfile(User? user) {
  if (user == null) return null;
  final res = AuthProfile()
    ..email = user.email!
    ..displayName = user.displayName ?? ''
    ..icon = user.photoURL ?? '';
  if (user.providerData.isNotEmpty) {
    final userInfo = user.providerData[0];
    res.providerId = userInfo.providerId;
  }
  return res;
}
