class Day {
  Day._();
  static int get now => epochDifference().inDays; // 0xffff = 75 let
  static int get nowUtc => epochDifferenceUtc().inDays;
  static int get nowSec => epochDifference().inSeconds;
  static int get nowSecUtc => epochDifferenceUtc().inSeconds; // 0xffffffff = 134 let
  static int get nowMilisec => epochDifference().inMilliseconds; // maxInt (2^53) = 285,616 let, 0xffffffff = 49 dnu

  static Duration tillMidnight() {
    final nowDate = dateNow(null);
    final nextDay = DateTime(nowDate.year, nowDate.month, nowDate.day + 1);
    return nextDay.difference(nowDate);
  }

  static int get nowEx => getNowEx != null ? getNowEx!() : now;
  static int Function()? getNowEx;

  static const DAYSECS = 3600 * 24;
  static final epoch = DateTime(2022);

  static DateTime? _nowMock;
  static void mockSet(int? day) => _nowMock = day == null ? null : toDate(day);
  static void mockNow(DateTime now) => _nowMock = now;

  static DateTime dateNow([DateTime? date]) {
    assert((() {
      date ??= _nowMock;
      return true;
    })());
    return date ?? DateTime.now();
  }

  static Duration epochDifference([DateTime? date]) => dateNow(date).difference(epoch);
  static Duration epochDifferenceUtc([DateTime? date]) => dateNow(date).toUtc().difference(epoch);

  static Duration toDuration([int? day]) => Duration(days: day ?? now);
  static DateTime toDate([int? day]) => epoch.add(toDuration(day));
}
