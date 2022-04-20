import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:functional_widget_annotation/functional_widget_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// flutter pub run build_runner watch --delete-conflicting-outputs
part 'media_query.g.dart';

final mediaQueryProvider = StateProvider<MediaQueryData>((_) => MediaQueryData());
final mediaWidthProvider = StateProvider<double>((ref) => ref.watch(mediaQueryProvider).size.width);
final mediaDeviceProvider = StateProvider<int>((ref) {
  // flutter_flow_util.dart
  final data = ref.watch(mediaQueryProvider);
  final width = data.size.width;
  if (width < 479) return cPhone;
  if (width < 767) return cTablet;
  final height = data.size.height;
  if (width < 991 && width > height) return cTabletLandscape;
  return cDesktop;
});

const cPhone = 1;
const cTablet = 2;
const cTabletLandscape = 3;
const cDesktop = 4;

@cwidget
Widget mediaQueryWrapper(BuildContext context, WidgetRef ref, {required Widget child}) {
  scheduleMicrotask(() => ref.read(mediaQueryProvider.notifier).state = MediaQuery.of(context));
  return child;
}
