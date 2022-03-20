import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:functional_widget_annotation/functional_widget_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_navigator/riverpod_navigator.dart';
import 'package:protobuf_for_dart/algorithm.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'utils/media_query.dart';
import 'utils/protobuf.dart';
//import 'package:path_provider/path_provider.dart';

// flutter pub run build_runner watch --delete-conflicting-outputs
part 'main.g.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final byteData = await rootBundle.load('assets/bin/lang-info.bin');
  final langInfos = Protobuf.fromBytes(byteData.buffer.asUint8List(), () => LangInfos());

  runApp(
    ProviderScope(
      overrides: providerOverrides(const [HomeSegment()], AppNavigator.new),
      child: const MyApp(),
    ),
  );
}

@cwidget
Widget myApp(BuildContext context, WidgetRef ref) {
  final navigator = ref.read(navigatorProvider) as AppNavigator;
  return MaterialApp.router(
    title: 'Flutter Demo',
    routerDelegate: navigator.routerDelegate,
    routeInformationParser: navigator.routeInformationParser,
    debugShowCheckedModeBanner: false,
  );
}

class HomeSegment extends TypedSegment {
  const HomeSegment();
  // ignore: avoid_unused_constructor_parameters
  factory HomeSegment.fromUrlPars(UrlPars pars) => const HomeSegment();
}

class AppNavigator extends RNavigator {
  AppNavigator(Ref ref)
      : super(
          ref,
          [
            RRoute<HomeSegment>(
              'home',
              HomeSegment.fromUrlPars,
              HomeScreen.new,
            ),
          ],
          progressIndicatorBuilder: () => const SpinKitCircle(color: Colors.blue, size: 45),
        );
}

class HomeScreen extends RScreen<AppNavigator, HomeSegment> {
  const HomeScreen(HomeSegment segment) : super(segment);

  @override
  Widget buildScreen(context, ref, navigator, appBarLeading) {
    return MediaQueryWrapper(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Home'),
          leading: appBarLeading,
        ),
        body: SafeArea(
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Column(
              children: [
                Consumer(builder: (_, ref, __) {
                  final data = ref.watch(widthProvider.select((v) => v < 300
                      ? 'mobile'
                      : v < 900
                          ? 'tablet'
                          : 'desktop'));
                  return Wrapper(flex: 1, child: Text('$data'));
                }),
                Spacer(flex: 1),
                Container(),
                SizedBox(),
                Align(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// for Row or Column childs
@swidget
Widget wrapper({int flex = 0, AlignmentDirectional? alignment, EdgeInsetsDirectional? padding, required Widget child}) {
  if (padding != null) child = Padding(padding: padding, child: child);
  if (alignment != null) child = Align(alignment: alignment, child: child);
  if (flex > 0) child = Expanded(flex: flex, child: child);
  return child;
}
