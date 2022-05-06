import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:functional_widget_annotation/functional_widget_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';

// flutter pub run build_runner watch --delete-conflicting-outputs
part 'audio_recorder.g.dart';

// == null => recording, else playing
final recordPathProvider = StateProvider<String?>((_) => null);

void main() {
  runApp(ProviderScope(child: const MyApp()));
}

@cwidget
Widget myApp(WidgetRef ref) => MaterialApp(
      title: 'Pronunciation Dialog',
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: ref.watch(recordPathProvider) == null ? RecorderWidget() : PlayerWidget(),
          ),
        ),
      ),
    );

@hcwidget
Widget recorderWidget(WidgetRef ref) {
  final recordPath = ref.watch(recordPathProvider);
  assert(recordPath == null);
  final record = useMemoized<Record>(() => Record(), [recordPath]);
  final isRecordingState = useState<bool?>(false);
  useEffect(
      () => () {
            record.dispose();
          },
      []);

  VoidCallback? onPress;
  if (isRecordingState.value == false) {
    onPress = () async {
      isRecordingState.value = true;
      final permission = await record.hasPermission();
      if (!permission) return;
      await record.start();
    };
  } else {
    onPress = () async {
      isRecordingState.value = null;
      final path = await record.stop();
      ref.read(recordPathProvider.notifier).state = path;
      isRecordingState.value = false;
    };
  }

  return ElevatedButton(
    onPressed: onPress,
    child: Text(isRecordingState.value == null
        ? '...waiting for stop...'
        : isRecordingState.value == true
            ? 'Stop'
            : 'Record'),
  );
}

@hcwidget
Widget playerWidget(WidgetRef ref) {
  final recordPath = ref.watch(recordPathProvider);
  assert(recordPath != null);
  final player = useMemoized<AudioPlayer>(() => AudioPlayer(), [recordPath]);
  final isPlayingState = useState<bool>(false);
  final streamSubscriptions = useMemoized<List<StreamSubscription>>(
      () => [
            player.playerStateStream.listen((state) {
              if (state.processingState == ProcessingState.completed) {
                ref.read(recordPathProvider.notifier).state = null;
              } else if (state.playing) {
                isPlayingState.value = true;
              }
            }),
          ],
      [recordPath]);
  useEffect(
      () => () {
            streamSubscriptions.forEach((s) => s.cancel());
            player.dispose();
          },
      []);

  VoidCallback? onPress;

  if (!isPlayingState.value)
    onPress = () async {
      await player.setFilePath(recordPath!);
      unawaited(player.play());
    };

  return ElevatedButton(
    onPressed: onPress,
    child: Text(isPlayingState.value ? '...waiting...' : 'Play'),
  );
}
