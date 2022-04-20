part of 'world.dart';

final worldRoutes = [
  RRoute<RegionSegment>(
    'region',
    RegionSegment.fromUrlPars,
    RegionScreen.new,
    opening: (s) => s.setAsyncValue(s.isRoot ? DataRoot.openData() : null),
    closing: (s) => s.isRoot ? DataRoot.closeData() : null,
  ),
];

class RegionSegment extends TypedSegment with AsyncSegment<void> {
  RegionSegment({this.id = '001'});
  factory RegionSegment.fromUrlPars(UrlPars pars) => RegionSegment(id: pars.getString('id'));

  final String id;

  void toUrlPars(UrlPars pars) => pars.setString('id', id);

  bool get isRoot => id == '001';
  bool get isTeritory => isDigit(id.codeUnitAt(0));
}
