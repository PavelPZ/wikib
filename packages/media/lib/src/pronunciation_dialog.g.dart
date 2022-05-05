// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pronunciation_dialog.dart';

// **************************************************************************
// FunctionalWidgetGenerator
// **************************************************************************

class PronuncDialog extends HookWidget {
  const PronuncDialog({Key? key, required this.sourceUrl}) : super(key: key);

  final String? sourceUrl;

  @override
  Widget build(BuildContext _context) => pronuncDialog(sourceUrl: sourceUrl);
}

class PlayButton extends ConsumerWidget {
  const PlayButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext _context, WidgetRef _ref) => playButton(_ref);
}

class PlayProgress extends HookConsumerWidget {
  const PlayProgress({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext _context, WidgetRef _ref) => playProgress(_ref);
}

class PlayWrapper extends HookConsumerWidget {
  const PlayWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext _context, WidgetRef _ref) => playWrapper(_ref);
}

class MyApp extends HookConsumerWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext _context, WidgetRef _ref) => myApp();
}
