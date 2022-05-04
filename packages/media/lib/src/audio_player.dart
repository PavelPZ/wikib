import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

Future<AudioPlayerEx?> createPlayer(WidgetRef ref, {String? sourceUrl, void stateChanged(PlayerStateEx state)?}) {
  print('createPlayer s');
  if (sourceUrl == null) {
    ref.audioPlayer = null;
    return Future.value(null);
  }
  final res = AudioPlayerEx();
  res.onPlayerStateChangedEx.forEach((stateEx) => stateChanged?.call(stateEx));
  print('createPlayer 0');
  return res.setSourceUrl(sourceUrl).then((value) {
    ref.audioPlayer = res;
    print('createPlayer e');
  });
}

final pronuncUrlProvider = Provider.autoDispose<String?>((_) => throw UnimplementedError());
final pronuncAudioPlayerProvider = StateNotifierProvider.autoDispose<AudioPlayerNotifier, AudioPlayerEx?>((_) => AudioPlayerNotifier(null));

class AudioPlayerNotifier extends StateNotifier<AudioPlayerEx?> {
  AudioPlayerNotifier(AudioPlayerEx? player) : super(player);
  void setPlayer(AudioPlayerEx? player) => state = player;

  @override
  void dispose() {
    state?.dispose();
    super.dispose();
  }
}

enum PlayerStateEx { other, playing, completed }

class AudioPlayerEx extends AudioPlayer {
  AudioPlayerEx() : super() {
    _stateEx = StreamController<PlayerStateEx>();
    onPlayerComplete.forEach((_) {
      if (!_stateEx.isClosed) _stateEx.add(PlayerStateEx.completed);
    });
    onPlayerStateChanged.forEach((s) {
      if (!_stateEx.isClosed) _stateEx.add(s == PlayerState.playing ? PlayerStateEx.playing : PlayerStateEx.other);
    });
  }

  late StreamController<PlayerStateEx> _stateEx;
  Stream<PlayerStateEx> get onPlayerStateChangedEx => _stateEx.stream;

  @override
  Future dispose() async {
    print('dispose s');
    await _stateEx.close();
    print('dispose 1');
    await super.dispose();
    print('dispose e');
  }
}

extension WidgetRefPlayer on WidgetRef {
  String? get sourceUrl => read(pronuncUrlProvider);
  String? get watchSourceUrl => watch(pronuncUrlProvider);

  AudioPlayerEx? get audioPlayer => read(pronuncAudioPlayerProvider);
  set audioPlayer(AudioPlayerEx? player) => read(pronuncAudioPlayerProvider.notifier).setPlayer(player);
  AudioPlayerEx? get watchAudioPlayer => watch(pronuncAudioPlayerProvider);
}
