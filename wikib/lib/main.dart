import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:functional_widget_annotation/functional_widget_annotation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:localization/localization_meta.dart';
import 'package:riverpod_navigator/riverpod_navigator.dart';

import 'localize.dart';
import 'utils/media_query.dart';
import 'world/world.dart';
//import 'package:path_provider/path_provider.dart';

// flutter pub run build_runner watch --delete-conflicting-outputs
part 'main.g.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  // TODO(pz): will be modified by download from azure etc.
  runApp(
    ProviderScope(
      overrides: [
        ...riverpodNavigatorOverrides([RegionSegment()], AppNavigator.new),
      ],
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
  // ignore: avoid_ unused_constructor_parameters
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
            ...worldRoutes,
          ],
          progressIndicatorBuilder: () => const SpinKitCircle(color: Colors.blue, size: 45),
          navigatorWraperBuilder: (rnavig, navig) => MediaQueryWrapper(
            child: NavigatorWraper(rnavig, navig),
          ),
        );
}

class HomeScreen extends RScreen<AppNavigator, HomeSegment> {
  const HomeScreen(HomeSegment segment) : super(segment);

  @override
  Widget buildScreen(context, ref, navigator, appBarLeading) {
    return Scaffold(
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
                final data = ref.watch(mediaWidthProvider.select((v) => v < 300
                    ? 'mobile'
                    : v < 900
                        ? 'tablet'
                        : 'desktop'));
                return Wrapper(flex: 1, child: Text('$data'));
              }),
              Text(Lo$msg('1', 'Hi, how are you?', _lo$file, descr: 'd1').loc),
              Spacer(flex: 1),
              Container(),
              SizedBox(),
              Align(),
            ],
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

const _lo$file = Lo$file('1', lo$project);
