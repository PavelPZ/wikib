// Import package
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:functional_widget_annotation/functional_widget_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:record/record.dart';

// flutter pub run build_runner watch --delete-conflicting-outputs
part 'audio_recorder.g.dart';

// final record = Record();

// // Check and request permission
// bool result = await record.hasPermission();

// // Start recording
// await record.start(
//   path: 'aFullPath/myFile.m4a', // required
//   encoder: AudioEncoder.AAC, // by default
//   bitRate: 128000, // by default
//   sampleRate: 44100, // by default
// );

// // Get the state of the recorder
// bool isRecording = await record.isRecording();

// // Stop recording
// await record.stop();

// ****************** TEST

// final readyForPlayProvider = StateProvider<bool>((_) => false);
final recordPathProvider = StateProvider<String?>((_) => null);

void main() {
  runApp(ProviderScope(child: const MyApp()));
}

@hcwidget
Widget myApp() => MaterialApp(
      title: 'PronuncDialog',
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(children: const [
              Recorder(),
              SizedBox(height: 20),
            ]),
          ),
        ),
      ),
    );

@hcwidget
Widget recorder(WidgetRef ref) {
  final recordPath = ref.watch(recordPathProvider);
  final record = useMemoized<Record?>(() => recordPath == null ? Record() : null, [recordPath]);
  final isRecordingState = useState<bool?>(false);
  useEffect(() => () => record?.dispose(), []);

  VoidCallback? onPress;
  if (record != null) {
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
  }

  return ElevatedButton(
    onPressed: onPress,
    child: Text(record == null || isRecordingState.value == null
        ? '...waiting...'
        : isRecordingState.value == true
            ? 'Stop'
            : 'Record'),
  );
}
