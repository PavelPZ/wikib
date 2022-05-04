import 'package:audioplayers/audioplayers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:utils/utils.dart';

final audioPlayerUrlProvider = Provider<String?>((_) => throw UnimplementedError());

final audioPlayerProvider = FutureProvider<AudioPlayerEx?>((ref) async {
  final sourceUrl = ref.watch(audioPlayerUrlProvider);
  if (isNullOrEmpty(sourceUrl)) return null;
  final res = AudioPlayerEx(ref);
  await res.setSourceUrl(sourceUrl!);
  return res;
});

final audioPlayerNotifierProvider =
    StateNotifierProvider<AudioPlayerNotifier, AudioPlayerEx?>((ref) => AudioPlayerNotifier(ref.watch(audioPlayerProvider).value));

final audioPlayerStateProvider = StateProvider<PlayerState>((_) => PlayerState.stopped);

class AudioPlayerNotifier extends StateController<AudioPlayerEx?> {
  AudioPlayerNotifier(AudioPlayerEx? player) : super(player);

  @override
  void dispose() {
    if (state != null) {
      state!._disposed = true;
      state!.dispose();
    }
    super.dispose();
  }
}

class AudioPlayerEx extends AudioPlayer {
  AudioPlayerEx(this.ref) : super() {
    onPlayerComplete.forEach((_) {
      if (!_disposed) ref.playerState = PlayerState.completed;
    });
    onPlayerStateChanged.forEach((s) {
      if (!_disposed) ref.playerState = s;
    });
  }

  final Ref ref;
  bool _disposed = false;
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
