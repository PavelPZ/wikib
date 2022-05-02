import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod/riverpod.dart';

// flutter pub run build_runner watch --delete-conflicting-outputs
part 'model.freezed.dart';

final pronuncPlayUrlProvider = StateProvider<String>((_) => '');
final pronuncStatelProvider = StateProvider<PronuncState?>((ref) => PronuncState(
      playUrl: ref.watch(pronuncPlayUrlProvider),
      state: PronuncStateId.none,
    ));
final pronuncEngine = Provider<PronuncEngine?>((ref) => PronuncEngine(ref));

class PronuncConfig {}

enum PronuncStateId { none, playReady, playing, playRecGap, recReady, recording, recPlayGap, recPlayRecReady, recPlaying }

@freezed
class PronuncState with _$PronuncState {
  const factory PronuncState({required String playUrl, required PronuncStateId state, String? recUrl}) = _Person;
}

class PronuncEngine {
  PronuncEngine(this.ref);
  final Ref ref;

  void dispose() {}

  void playClick() {}

  void playStarted() {}
  void playFinished() {}
}
