part of 'world.dart';

class DataRoot {
  DataRoot(this.source) {
    for (final l in source.langs) langs[l.id] = l;
    for (final s in source.scripts) scripts[s.id] = s;
    // TODO(pz): for (final l in source.langs) langs[l.id] = l;
  }
  final LangInfos source;
  final countries = <String, Country>{};
  final langs = <String, LangInfo>{};
  final scripts = <String, Script>{};
  final teritories = <String, Teritory>{};

  static DataRoot? instance;
  static Future<void>? closeData() {
    instance = null;
    return null;
  }

  static Future<void> openData() async {
    final byteData = await rootBundle.load('assets/bin/lang-info.bin');
    instance = DataRoot(Protobuf.fromBytes(byteData.buffer.asUint8List(), () => LangInfos()));
  }
}
