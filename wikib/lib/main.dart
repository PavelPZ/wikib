import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:functional_widget_annotation/functional_widget_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_navigator/riverpod_navigator.dart';

// flutter pub run build_runner watch --delete-conflicting-outputs
part 'main.g.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ProviderScope(
      overrides: providerOverrides(const [HomeSegment()], AppNavigator.new),
      child: const MyApp(),
    ),
  );
}

@cwidget
Widget myApp(WidgetRef ref) {
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
  Widget buildScreen(context, ref, navigator, appBarLeading) => Scaffold(
        appBar: AppBar(
          title: Text('Home'),
          leading: appBarLeading,
        ),
        body: SafeArea(
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Column(
              children: [
                Wrapper(flex: 1, child: Text('')),
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

/// for Row or Column childs
@swidget
Widget wrapper({int flex = 0, AlignmentDirectional? alignment, EdgeInsetsDirectional? padding, required Widget child}) {
  if (padding != null) child = Padding(padding: padding, child: child);
  if (alignment != null) child = Align(alignment: alignment, child: child);
  if (flex > 0) child = Expanded(flex: flex, child: child);
  return child;
}
