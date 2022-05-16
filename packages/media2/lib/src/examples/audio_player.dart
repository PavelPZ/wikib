import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:utils/utils.dart';

enum PlayerState { none, playing, paused, completed }

final audioPlayerUrlProvider = Provider<String?>((_) => throw UnimplementedError());

final audioPlayerProvider = FutureProvider<AudioPlayerEx?>((ref) async {
  void init() {
    ref.playerState = PlayerState.none;
    ref.duration = Duration();
    ref.position = Duration();
  }

  final sourceUrl = ref.watch(audioPlayerUrlProvider);

  if (isNullOrEmpty(sourceUrl)) {
    await Future.microtask(init);
    return null;
  }

  final res = AudioPlayerEx();
  res.streamSubscriptions = [
    res.durationStream.listen((d) => ref.duration = d ?? Duration()),
    res.positionStream.listen((d) => ref.position = d),
    res.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed)
        ref.playerState = PlayerState.completed;
      else if (state.playing) ref.playerState = PlayerState.playing;
    }),
  ];
  await res.setAudioSource(AudioSource.uri(Uri.parse(sourceUrl!))) ?? Duration();
  init();
  print('new AudioPlayerEx($sourceUrl)');
  return res;
});

final audioPlayerNotifierProvider =
    StateNotifierProvider<AudioPlayerNotifier, AudioPlayerEx?>((ref) => AudioPlayerNotifier(ref.watch(audioPlayerProvider).value));

final audioPlayerStateProvider = StateProvider<PlayerState>((_) => PlayerState.none);
final audioPlayerDurationProvider = StateProvider<Duration>((_) => Duration());
final audioPlayerPositionProvider = StateProvider<Duration>((_) => Duration());

class AudioPlayerNotifier extends StateController<AudioPlayerEx?> {
  AudioPlayerNotifier(AudioPlayerEx? player) : super(player);

  @override
  void dispose() {
    if (state != null) {
      final st = state!;
      st.stop().then((_) => st.dispose()).then((_) {
        super.dispose();
        print('AudioPlayerEx.dispose');
      });
    } else
      super.dispose();
  }
}

class AudioPlayerEx extends AudioPlayer {
  late List<StreamSubscription> streamSubscriptions;

  @override
  Future dispose() {
    streamSubscriptions.forEach((s) => s.cancel());
    return super.dispose();
  }
}

List<Override> playerOverrides(String? sourceUrl) => [
      audioPlayerUrlProvider.overrideWithValue(sourceUrl), // url source
      audioPlayerProvider, // AudioPlayerEx
      audioPlayerNotifierProvider, // StateController<AudioPlayerEx?> for AudioPlayerEx disposing
      audioPlayerStateProvider, // recompute onPlayerComplete => playerState = PlayerState.completed
      audioPlayerDurationProvider,
      audioPlayerPositionProvider,
    ];

extension WidgetRefPlayer on WidgetRef {
  String? get sourceUrl => read(audioPlayerUrlProvider);
  String? get watchSourceUrl => watch(audioPlayerUrlProvider);

  AudioPlayerEx? get audioPlayer => read(audioPlayerNotifierProvider);
  set audioPlayer(AudioPlayerEx? player) => read(audioPlayerNotifierProvider.notifier).state = player;
  AudioPlayerEx? get watchAudioPlayer => watch(audioPlayerNotifierProvider);

  PlayerState get playerState => read(audioPlayerStateProvider);
  set playerState(PlayerState state) => read(audioPlayerStateProvider.notifier).state = state;
  PlayerState get watchplayerState => watch(audioPlayerStateProvider);

  Duration get watchDuration => watch(audioPlayerDurationProvider);
  Duration get watchPosition => watch(audioPlayerPositionProvider);
}

extension RefPlayer on Ref {
  set playerState(PlayerState state) => read(audioPlayerStateProvider.notifier).state = state;
  set duration(Duration state) => read(audioPlayerDurationProvider.notifier).state = state;
  set position(Duration state) => read(audioPlayerPositionProvider.notifier).state = state;
}
