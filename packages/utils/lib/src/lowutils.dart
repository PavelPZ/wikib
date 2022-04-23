const emptyEMail = '@empty_email';

bool isDigit(int c) {
  return c >= 0x30 && c <= 0x39;
}

void rAssert(bool cond, [String? msg]) {
  if (cond) return;
  throw Exception(msg);
}

Iterable<int> range(int start, int len) sync* {
  for (var i = start; i < start + len; i++) yield i;
}

abstract class DBId {
  bool eq(DBId id);
  String partitionKey(String email);
}

class DBRewiseId implements DBId {
  const DBRewiseId({required this.learn, required this.speak});
  final String learn;
  final String speak;
  @override
  bool eq(DBId id) => id is DBRewiseId && id.learn == learn && id.speak == speak;
  @override
  String partitionKey(String email) => '$email!rewise!$speak!$learn';
}

class DBDeviceId implements DBId {
  @override
  bool eq(DBId id) => id is DBDeviceId;
  @override
  String partitionKey(String email) => 'device_local_db';
}

class DBUserId implements DBId {
  @override
  bool eq(DBId id) => id is DBUserId;
  @override
  String partitionKey(String email) => '$email!user';
}

abstract class ICancelToken {
  void cancel();
  bool get canceled;
}

class CancelToken implements ICancelToken {
  @override
  void cancel() => _canceled = true;
  @override
  bool get canceled => _canceled;
  bool _canceled = false;
}
