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

class RewiseId {
  const RewiseId({required this.email, required this.learn, required this.speak});
  final String email;
  final String learn;
  final String speak;
  String get primaryKey => '$email|$speak|$learn';
}

class CancelToken {
  void cancel() => canceled = true;
  bool canceled = false;
}
