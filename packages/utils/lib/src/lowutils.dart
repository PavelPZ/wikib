bool isDigit(int c) {
  return c >= 0x30 && c <= 0x39;
}

void rAssert(bool cond, [String? msg]) {
  if (cond) return;
  throw Exception(msg);
}

Iterable<int> range(int start, int len) sync* {
  for (var i = 0; i < start + len; i++) yield i;
}

abstract class DBId {
  String partition(String email);
}

class DBRewiseId implements DBId {
  const DBRewiseId({required this.learn, required this.speak});
  final String learn;
  final String speak;
  String partition(String email) => '$email!rewise!$speak!$learn';
}

class DBUserId implements DBId {
  const DBUserId();
  String partition(String email) => '$email!user';
}

abstract class ICancelToken {
  void cancel();
  bool get canceled;
}

class CancelToken implements ICancelToken {
  void cancel() => _canceled = true;
  bool get canceled => _canceled;
  bool _canceled = false;
}
