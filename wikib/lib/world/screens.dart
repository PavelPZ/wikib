part of 'world.dart';

@cwidget
Widget regionScreen(RegionSegment segment) => WorldScreen(
      child: Text('Home'),
    );

@cwidget
Widget worldScreen(BuildContext context, WidgetRef ref, {required Widget child}) {
  final navigator = ref.read(navigatorProvider) as RNavigator;
  return BackButtonHandler(
    child: Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        leading: navigator.getAppBarLeading(),
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: child,
        ),
      ),
    ),
  );
}
