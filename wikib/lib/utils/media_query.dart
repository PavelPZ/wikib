import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:functional_widget_annotation/functional_widget_annotation.dart';

// flutter pub run build_runner watch --delete-conflicting-outputs
part 'media_query.g.dart';

final mediaQueryProvider = StateProvider<MediaQueryData>((_) => MediaQueryData());
final widthProvider = StateProvider<double>((ref) => ref.watch(mediaQueryProvider).size.width);

@cwidget
Widget mediaQueryWrapper(BuildContext context, WidgetRef ref, {required Widget child}) {
  scheduleMicrotask(() => ref.read(mediaQueryProvider.notifier).state = MediaQuery.of(context));
  return child;
}
