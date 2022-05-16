// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'world.dart';

// **************************************************************************
// FunctionalWidgetGenerator
// **************************************************************************

class RegionScreen extends ConsumerWidget {
  const RegionScreen(this.segment, {Key? key}) : super(key: key);

  final RegionSegment segment;

  @override
  Widget build(BuildContext _context, WidgetRef _ref) => regionScreen(segment);
}

class WorldScreen extends ConsumerWidget {
  const WorldScreen({Key? key, required this.child}) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext _context, WidgetRef _ref) => worldScreen(_context, _ref, child: child);
}
