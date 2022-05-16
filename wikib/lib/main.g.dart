// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'main.dart';

// **************************************************************************
// FunctionalWidgetGenerator
// **************************************************************************

class MyApp extends ConsumerWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext _context, WidgetRef _ref) => myApp(_context, _ref);
}

/// for Row or Column childs
class Wrapper extends StatelessWidget {
  /// for Row or Column childs
  const Wrapper({Key? key, this.flex = 0, this.alignment, this.padding, required this.child}) : super(key: key);

  /// for Row or Column childs
  final int flex;

  /// for Row or Column childs
  final AlignmentDirectional? alignment;

  /// for Row or Column childs
  final EdgeInsetsDirectional? padding;

  /// for Row or Column childs
  final Widget child;

  @override
  Widget build(BuildContext _context) => wrapper(flex: flex, alignment: alignment, padding: padding, child: child);
}
