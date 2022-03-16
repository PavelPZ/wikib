import '../flutter_flow/flutter_flow_pdf_viewer.dart';
import '../flutter_flow/flutter_flow_rive_controller.dart';
import '../flutter_flow/flutter_flow_theme.dart';
import '../flutter_flow/flutter_flow_util.dart';
import 'dart:ui';
import 'package:rive/rive.dart' hide LinearGradient;
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

class Page5Widget extends StatefulWidget {
  const Page5Widget({Key key}) : super(key: key);

  @override
  _Page5WidgetState createState() => _Page5WidgetState();
}

class _Page5WidgetState extends State<Page5Widget> {
  final riveAnimationAnimationsList = [
    'Main Loop',
  ];
  List<FlutterFlowRiveController> riveAnimationControllers = [];
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    riveAnimationAnimationsList.forEach((name) {
      riveAnimationControllers.add(FlutterFlowRiveController(
        name,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        backgroundColor: FlutterFlowTheme.of(context).primaryColor,
        automaticallyImplyLeading: false,
        title: Text(
          FFLocalizations.of(context).getText(
            'vb4sff2c' /* Page Title */,
          ),
          style: FlutterFlowTheme.of(context).title2.override(
                fontFamily: 'Poppins',
                color: Colors.white,
                fontSize: 22,
              ),
        ),
        actions: [],
        centerTitle: false,
        elevation: 2,
      ),
      backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Lottie.network(
                'https://assets2.lottiefiles.com/packages/lf20_aZTdD5.json',
                width: 150,
                height: 130,
                fit: BoxFit.cover,
                animate: true,
              ),
              ClipRect(
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(
                    sigmaX: 2,
                    sigmaY: 2,
                  ),
                ),
              ),
              Container(
                width: 150,
                height: 130,
                child: RiveAnimation.network(
                  'https://public.rive.app/community/runtime-files/1199-2317-jack-olantern.riv',
                  artboard: 'New Artboard',
                  fit: BoxFit.cover,
                  controllers: riveAnimationControllers,
                ),
              ),
              Html(
                data: '<h3>H3 Header</h3> <p>Sample paragraph</p>',
              ),
              FlutterFlowPdfViewer(
                networkPath: 'http://www.africau.edu/images/default/sample.pdf',
                height: 300,
                horizontalScroll: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
