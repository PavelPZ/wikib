import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

Future<AudioPlayerEx?> createPlayer(WidgetRef ref, {String? sourceUrl, void stateChanged(PlayerState state)?}) {
  if (sourceUrl == null) {
    ref.audioPlayer = null;
    return Future.value(null);
  }
  final res = AudioPlayerEx();
  res.onPlayerStateChangedEx.forEach((stateEx) => stateChanged?.call(stateEx));
  return res.setSourceUrl(sourceUrl).then((value) => ref.audioPlayer = res);
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

class AudioPlayerEx extends AudioPlayer {
  AudioPlayerEx() : super() {
    _stateEx = StreamController<PlayerState>();
    onPlayerComplete.forEach((_) {
      if (!_stateEx.isClosed) _stateEx.add(PlayerState.completed);
    });
    onPlayerStateChanged.forEach((s) {
      if (!_stateEx.isClosed) _stateEx.add(s);
    });
  }

  // repair not used "PlayerState.completed"
  late StreamController<PlayerState> _stateEx;
  Stream<PlayerState> get onPlayerStateChangedEx => _stateEx.stream;

  @override
  Future dispose() async {
    await _stateEx.close();
    await super.dispose();
  }
}

extension WidgetRefPlayer on WidgetRef {
  String? get sourceUrl => read(pronuncUrlProvider);
  String? get watchSourceUrl => watch(pronuncUrlProvider);

  AudioPlayerEx? get audioPlayer => read(pronuncAudioPlayerProvider);
  set audioPlayer(AudioPlayerEx? player) => read(pronuncAudioPlayerProvider.notifier).setPlayer(player);
  AudioPlayerEx? get watchAudioPlayer => watch(pronuncAudioPlayerProvider);
}
