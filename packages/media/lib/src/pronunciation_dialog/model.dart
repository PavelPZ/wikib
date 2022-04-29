import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod/riverpod.dart';

// flutter pub run build_runner watch --delete-conflicting-outputs
part 'model.freezed.dart';

class PronuncConfig {}

enum PronuncState { none, playReady, playing, playRecGap, recReady, recording, recPlayGap, recPlayRecReady, recPlaying }

@freezed
class PronuncModel with _$PronuncModel {
  const factory PronuncModel({required String playUrl, required PronuncState state, String? recUrl}) = _Person;
}

final pronuncModelPlayUrl = StateProvider<String?>((_) => null);
final pronuncModelProvider = StateProvider<PronuncModel?>((ref) {
  final playUrl = ref.watch(pronuncModelPlayUrl);
  return playUrl == null ? null : PronuncModel(playUrl: playUrl, state: PronuncState.none);
});
final pronuncEngine = Provider<PronuncEngine?>((ref) => PronuncEngine(ref));

class PronuncEngine {
  PronuncEngine(this.ref);
  final Ref ref;

  void dispose() {}

  void playClick() {}

  void playStarted() {}
  void playFinished() {}
}
