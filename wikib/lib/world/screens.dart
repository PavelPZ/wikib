part of 'world.dart';

@cwidget
Widget regionScreen(RegionSegment segment) => WorldScreen(
      //child: Container(color: Colors.white, child: Center(child: Text(Lo$msg('1', 'Home', _lo$file, descr: 'd1').loc))),
      child: Container(color: Colors.white, child: Center(child: Text(Lo$msg('2', 'Hi, how are you 2?', _lo$file, descr: 'd4').loc))),
    );

@cwidget
Widget worldScreen(BuildContext context, WidgetRef ref, {required Widget child}) {
  final navigator = ref.read(navigatorProvider) as RNavigator;
  return BackButtonHandler(
    child: DefaultTextStyle(style: Theme.of(context).textTheme.titleMedium!, child: child),
    // child: Scaffold(
    //   appBar: AppBar(
    //     title: Text('Home'),
    //     leading: navigator.getAppBarLeading(),
    //   ),
    //   body: SafeArea(
    //     child: GestureDetector(
    //       onTap: () => FocusScope.of(context).unfocus(),
    //       child: child,
    //     ),
    //   ),
    // ),
  );
}
