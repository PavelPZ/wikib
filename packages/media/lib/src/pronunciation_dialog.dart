import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:functional_widget_annotation/functional_widget_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'audio_player.dart';

// flutter pub run build_runner watch --delete-conflicting-outputs
part 'pronunciation_dialog.g.dart';

enum PronuncState { none, playReady, playing, playRecGap, recReady, recording, recPlayGap, recPlayRecReady, recPlaying }

final pronuncStateProvider = StateProvider.autoDispose<PronuncState>((_) => throw UnimplementedError());

@swidget
Widget pronuncDialog({required String? sourceUrl}) {
  return ProviderScope(
    overrides: [
      pronuncUrlProvider.overrideWithValue(sourceUrl),
      pronuncStateProvider.overrideWithValue(StateController<PronuncState>(sourceUrl == null ? PronuncState.none : PronuncState.playReady)),
      pronuncAudioPlayerProvider,
    ],
    key: ValueKey(sourceUrl),
    child: Row(
      children: const [
        PlayWrapper(),
      ],
    ),
  );
}

@cwidget
Widget playButton(WidgetRef ref) {
  final player = ref.watchAudioPlayer;
  return ElevatedButton(
    onPressed: player == null
        ? null
        : () async {
            await player.stop();
            await player.resume();
          },
    child: Consumer(builder: (_, ref, ___) => Text(ref.watch(pronuncStateProvider) == PronuncState.playing ? 'Replay' : 'Play')),
  );
}

@hcwidget
Widget playProgress(WidgetRef ref) {
  final player = ref.watchAudioPlayer;
  final fDuration = useStream(player?.onDurationChanged, initialData: Duration());
  final fPosition = useStream(player?.onPositionChanged, initialData: Duration());
  return Text('${fPosition.hasData ? fPosition.data!.inMilliseconds : 0} / ${fDuration.hasData ? fDuration.data!.inMilliseconds : 0}');
}

@hcwidget
Widget playWrapper(WidgetRef ref) {
  final sourceUrl = ref.watchSourceUrl;
  useEffect(() {
    createPlayer(ref, sourceUrl: sourceUrl, stateChanged: (stateEx) {
      if (stateEx == PlayerStateEx.other) return;
      ref.state = stateEx == PlayerStateEx.playing ? PronuncState.playing : PronuncState.playRecGap;
    });
    return null;
  }, [sourceUrl]);
  return Column(children: [
    PlayButton(),
    PlayProgress(),
    SizedBox(height: 20),
    Consumer(builder: (_, ref, __) => Text(ref.watchState.toString())),
  ]);
}

extension WidgetRefPronunc on WidgetRef {
  PronuncState get state => read(pronuncStateProvider);
  set state(PronuncState state) => read(pronuncStateProvider.notifier).state = state;
  PronuncState get watchState => watch(pronuncStateProvider);
}

// ****************** TEST

void main() {
  runApp(const MyApp());
}

const longUrl = 'https://free-loops.com/data/mp3/c8/84/81a4f6cc7340ad558c25bba4f6c3.mp3';
const shortUrl = 'https://file-examples.com/storage/fed7f5feae62719de971a0c/2017/11/file_example_MP3_5MG.mp3';
const mp3Files = [longUrl, shortUrl];

@hcwidget
Widget myApp() {
  final state = useState(0);
  final sourceUrl = state.value < 2 ? mp3Files[state.value] : null;
  return MaterialApp(
    title: 'PronuncDialog',
    home: Scaffold(
      body: Center(
        child: Column(
          children: [
            PronuncDialog(sourceUrl: sourceUrl), //, key: ValueKey(sourceUrl ?? '')),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: () => state.value == 2 ? state.value = 0 : state.value++, child: Text('RUN ${state.value}')),
            const SizedBox(height: 20),
            PronuncDialog(sourceUrl: shortUrl),
          ],
        ),
      ),
    ),
  );
}
