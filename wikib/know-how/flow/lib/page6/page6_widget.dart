import '../flutter_flow/flutter_flow_language_selector.dart';
import '../flutter_flow/flutter_flow_pdf_viewer.dart';
import '../flutter_flow/flutter_flow_theme.dart';
import '../flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';

class Page6Widget extends StatefulWidget {
  const Page6Widget({Key key}) : super(key: key);

  @override
  _Page6WidgetState createState() => _Page6WidgetState();
}

class _Page6WidgetState extends State<Page6Widget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        backgroundColor: FlutterFlowTheme.of(context).primaryColor,
        automaticallyImplyLeading: false,
        title: Text(
          FFLocalizations.of(context).getText(
            'gl0my9lq' /* Page Title */,
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
      drawer: Drawer(
        elevation: 16,
      ),
      endDrawer: Drawer(
        elevation: 16,
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              FlutterFlowPdfViewer(
                networkPath: 'http://www.africau.edu/images/default/sample.pdf',
                height: 300,
                horizontalScroll: false,
              ),
              FlutterFlowLanguageSelector(
                width: 200,
                backgroundColor: Colors.black,
                borderColor: Color(0xFF262D34),
                dropdownIconColor: Color(0xFF14181B),
                borderRadius: 8,
                textStyle: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.normal,
                  fontSize: 13,
                ),
                hideFlags: false,
                flagSize: 24,
                flagTextGap: 8,
                currentLanguage: FFLocalizations.of(context).languageCode,
                languages: FFLocalizations.languages(),
                onChanged: (lang) => setAppLanguage(context, lang),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
