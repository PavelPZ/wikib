import 'package:audioplayers/audioplayers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:utils/utils.dart';

const disposeDelayMSecs = 1000;

final audioPlayerUrlProvider = Provider.autoDispose<String?>(
  (_) => throw UnimplementedError(),
  disposeDelay: Duration(milliseconds: disposeDelayMSecs),
);

final audioPlayerProvider = FutureProvider.autoDispose<AudioPlayerEx?>((ref) async {
  final sourceUrl = ref.watch(audioPlayerUrlProvider);
  if (isNullOrEmpty(sourceUrl)) return null;
  final res = AudioPlayerEx(ref);
  await res.setSourceUrl(sourceUrl!);
  return res;
}, disposeDelay: Duration(milliseconds: disposeDelayMSecs));

final audioPlayerNotifierProvider = StateNotifierProvider.autoDispose<AudioPlayerNotifier, AudioPlayerEx?>(
  (ref) => AudioPlayerNotifier(ref.watch(audioPlayerProvider).value),
  disposeDelay: Duration(milliseconds: disposeDelayMSecs),
);

final audioPlayerStateProvider = StateProvider.autoDispose<PlayerState>(
  (_) => PlayerState.stopped,
  disposeDelay: Duration(milliseconds: disposeDelayMSecs),
);

class AudioPlayerNotifier extends StateController<AudioPlayerEx?> {
  AudioPlayerNotifier(AudioPlayerEx? player) : super(player);

  @override
  void dispose() {
    state?.dispose();
    super.dispose();
  }
}

class AudioPlayerEx extends AudioPlayer {
  AudioPlayerEx(this.ref) : super() {
    onPlayerComplete.forEach((_) => ref.playerState = PlayerState.completed);
    onPlayerStateChanged.forEach((s) => ref.playerState = s);
  }

  final Ref ref;
}

extension WidgetRefPlayer on WidgetRef {
  String? get sourceUrl => read(audioPlayerUrlProvider);
  String? get watchSourceUrl => watch(audioPlayerUrlProvider);

  AudioPlayerEx? get audioPlayer => read(audioPlayerNotifierProvider);
  set audioPlayer(AudioPlayerEx? player) => read(audioPlayerNotifierProvider.notifier).state = player;
  AudioPlayerEx? get watchAudioPlayer => watch(audioPlayerNotifierProvider);

  PlayerState get playerState => read(audioPlayerStateProvider);
  set playerState(PlayerState state) => read(audioPlayerStateProvider.notifier).state = state;
  PlayerState get watchplayerState => watch(audioPlayerStateProvider);
}

extension RefPlayer on Ref {
  set playerState(PlayerState state) => read(audioPlayerStateProvider.notifier).state = state;
}
