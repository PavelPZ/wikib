import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:riverpod/riverpod.dart';
import 'package:utils/utils.dart';

final pronuncUrlProvider = StateProvider<String>((ref) => '');
final pronuncStateProvider = StateProvider<PronuncState>((_) => PronuncState.none);
// singleton
final pronuncEngine = Provider<PronuncEngine?>((ref) => PronuncEngine(ref));

class PronuncConfig {}

enum PronuncState { none, playReady, playing, playRecGap, recReady, recording, recPlayGap, recPlayRecReady, recPlaying }

// @freezed
// class PronuncState with _$PronuncState {
//   const factory PronuncState({required String playUrl, required PronuncStateId state, String? recUrl}) = _Person;
// }

class PronuncEngine {
  PronuncEngine(this.ref) {
    _stateProviderSubscription = ref.listen<PronuncState>(pronuncStateProvider, stateChanged);
    _urlSubscription = ref.listen<String>(pronuncUrlProvider, urlChanged);
  }
  final Ref ref;
  AudioPlayer? player;
  late ProviderSubscription<PronuncState> _stateProviderSubscription;
  late ProviderSubscription<String> _urlSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;

  void dispose() {
    _stateProviderSubscription.close();
    _urlSubscription.close();
    _playerStateSubscription?.cancel();
  }

  Future urlChanged(String? old, String url) async {
    final state = ref.read(pronuncStateProvider.notifier);
    if (player != null) {
      await _playerStateSubscription!.cancel();
      _playerStateSubscription = null;
      await player!.release();
      player = null;
    }
    if (!isNullOrEmpty(url)) {
      player = AudioPlayer();
      _playerStateSubscription = player!.onPlayerStateChanged.listen(playerStateChanged);
      await player!.setSourceUrl(url);
      state.state = PronuncState.playReady;
    } else
      state.state = PronuncState.none;
  }

  dynamic playerStateChanged(PlayerState pstate) {
    final state = ref.read(pronuncStateProvider.notifier);
    switch (pstate) {
      case PlayerState.playing:
        return state.state = PronuncState.playing;
      case PlayerState.stopped:
      case PlayerState.completed:
      case PlayerState.paused:
    }
  }

  void stateChanged(PronuncState? old, PronuncState state) {}

  void playClick() {}

  void playStarted() {}
  void playFinished() {}

  void resetWhenUrlChanged() {}
}
